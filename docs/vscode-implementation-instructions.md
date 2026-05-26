# Skippy — instrukcja wdrożeniowa do VS Code

## Cel dokumentu

Ten dokument opisuje pierwszy techniczny etap realizacji Skippy po stronie VS Code.

Priorytety:

1. Szybka rozmowa z użytkowniczką.
2. Redis jako cache kontekstu.
3. PostgreSQL jako źródło prawdy.
4. Pełny zapis danych od początku.
5. Pipeline, który nie blokuje odpowiedzi.
6. Przygotowanie pod nocną analizę profili.

## Główna zasada architektury

```txt
Redis = szybkość rozmowy
PostgreSQL = pełna historia i źródło prawdy
n8n / worker = analiza, synchronizacja i zadania w tle
Hermes = silnik rozmowy / AI
```

Nie wolno traktować Redisa jako głównej bazy danych.

## Docelowy flow wiadomości

```txt
WhatsApp
↓
Hermes / Skippy runtime
↓
Redis: szybki kontekst użytkowniczki
↓
AI response
↓
WhatsApp reply
↓
PostgreSQL: zapis wiadomości, odpowiedzi i eventu
↓
background worker / n8n
↓
analiza intencji, profilu, kosztów i użycia
↓
aktualizacja PostgreSQL
↓
aktualizacja Redis profile_summary
```

## Fast path

Fast path to ścieżka, która musi odpowiedzieć użytkowniczce możliwie szybko.

W fast path robimy tylko:

1. Odbiór wiadomości.
2. Identyfikację numeru telefonu.
3. Pobranie krótkiego kontekstu z Redis.
4. Wywołanie AI.
5. Wysłanie odpowiedzi.
6. Minimalny zapis eventu do PostgreSQL albo kolejki.

Nie robimy tu ciężkiej analizy, segmentacji ani generowania profilu.

## Background path

Background path działa po odpowiedzi.

Robi:

1. Pełny zapis wiadomości i odpowiedzi.
2. Analizę intencji.
3. Ekstrakcję danych do zapamiętania.
4. Aktualizację profilu.
5. Aktualizację usage i kosztów.
6. Aktualizację cache Redis.
7. Przygotowanie danych do nocnej analizy.

## Nocna analiza

Raz dziennie system powinien uruchomić analizę profili.

Przykładowo: 02:00–04:00.

Zakres:

1. Pobierz wiadomości użytkowniczki z ostatnich 24h.
2. Użyj mocniejszego modelu.
3. Wykryj nowe fakty, preferencje, rutyny i ważne daty.
4. Odrzuć informacje jednorazowe i nieistotne.
5. Zaktualizuj `user_profile_summary`.
6. Zaktualizuj `user_preferences`, `family_members`, `user_routines`.
7. Odśwież Redis.

## Redis — struktura kluczy

### Kontekst użytkowniczki

```txt
skippy:user:{phone}:context
```

Przykładowa wartość:

```json
{
  "phone": "+48500111222",
  "name": "Ania",
  "plan": "free",
  "calendar_connected": true,
  "profile_summary": "Ania testuje Skippy. Preferuje krótkie odpowiedzi.",
  "recent_context": [
    "Dodała wizytę u dentysty",
    "Pytała o listę zakupów"
  ],
  "conversation_state": "active"
}
```

### Ostatnie wiadomości

```txt
skippy:user:{phone}:recent_messages
```

Typ: lista Redis.

Przechowuj ostatnie 10–20 wiadomości.

### Status onboardingu

```txt
skippy:user:{phone}:onboarding
```

Przykład:

```json
{
  "status": "need_name",
  "updated_at": "2026-05-26T10:00:00Z"
}
```

### Usage szybkie

```txt
skippy:user:{phone}:usage:daily:{YYYY-MM-DD}
```

TTL: do końca dnia + zapas.

### TTL rekomendowany

| Dane | TTL |
|------|-----|
| context | 15–60 min |
| recent_messages | 15–60 min |
| onboarding | 24h |
| daily usage | 26h |
| profile_summary | 1–24h |

Po zmianie planu, połączeniu kalendarza albo nocnej analizie cache powinien zostać odświeżony.

## PostgreSQL — minimalna struktura bazy

Schema: `skippy`.

### users

```sql
CREATE TABLE IF NOT EXISTS skippy.users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone TEXT UNIQUE NOT NULL,
  name TEXT,
  email TEXT,
  plan TEXT NOT NULL DEFAULT 'free',
  status TEXT NOT NULL DEFAULT 'active',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### plans_config

```sql
CREATE TABLE IF NOT EXISTS skippy.plans_config (
  plan_name TEXT PRIMARY KEY,
  monthly_price DECIMAL(10,2) NOT NULL DEFAULT 0,
  daily_message_limit INT,
  monthly_message_limit INT,
  voice_minutes_limit INT,
  memory_days INT,
  family_members_limit INT,
  proactive_enabled BOOLEAN DEFAULT FALSE,
  calendar_enabled BOOLEAN DEFAULT FALSE,
  shopping_enabled BOOLEAN DEFAULT FALSE,
  shared_enabled BOOLEAN DEFAULT FALSE,
  description TEXT
);
```

### user_messages

```sql
CREATE TABLE IF NOT EXISTS skippy.user_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES skippy.users(id),
  phone TEXT NOT NULL,
  whatsapp_message_id TEXT,
  direction TEXT NOT NULL,
  message_type TEXT NOT NULL,
  message_text TEXT,
  raw_payload JSONB,
  created_at TIMESTAMP DEFAULT NOW()
);
```

`direction`:

```txt
inbound
outbound
```

`message_type`:

```txt
text
voice
system
```

### assistant_messages

```sql
CREATE TABLE IF NOT EXISTS skippy.assistant_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES skippy.users(id),
  phone TEXT NOT NULL,
  reply_text TEXT NOT NULL,
  model TEXT,
  latency_ms INT,
  input_tokens INT,
  output_tokens INT,
  cost_estimate NUMERIC(10,6),
  created_at TIMESTAMP DEFAULT NOW()
);
```

### conversation_events

```sql
CREATE TABLE IF NOT EXISTS skippy.conversation_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES skippy.users(id),
  event_type TEXT NOT NULL,
  payload JSONB NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);
```

Przykładowe eventy:

```txt
message_received
reply_sent
reminder_created
calendar_event_created
shopping_item_added
profile_update_detected
google_auth_completed
limit_exceeded
error_occurred
```

### event_outbox

```sql
CREATE TABLE IF NOT EXISTS skippy.event_outbox (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES skippy.users(id),
  event_type TEXT NOT NULL,
  payload JSONB NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  attempts INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  processed_at TIMESTAMP
);
```

### user_profile_summary

```sql
CREATE TABLE IF NOT EXISTS skippy.user_profile_summary (
  user_id UUID PRIMARY KEY REFERENCES skippy.users(id),
  summary TEXT,
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### user_preferences

```sql
CREATE TABLE IF NOT EXISTS skippy.user_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES skippy.users(id),
  preference_key TEXT NOT NULL,
  preference_value TEXT NOT NULL,
  confidence NUMERIC(4,3) DEFAULT 0.700,
  source TEXT DEFAULT 'conversation',
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### family_members

```sql
CREATE TABLE IF NOT EXISTS skippy.family_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES skippy.users(id),
  name TEXT NOT NULL,
  relation TEXT,
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### user_routines

```sql
CREATE TABLE IF NOT EXISTS skippy.user_routines (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES skippy.users(id),
  routine_name TEXT NOT NULL,
  recurrence_text TEXT,
  related_person TEXT,
  confidence NUMERIC(4,3) DEFAULT 0.700,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### user_reminders

```sql
CREATE TABLE IF NOT EXISTS skippy.user_reminders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES skippy.users(id),
  title TEXT NOT NULL,
  remind_at TIMESTAMP,
  source TEXT DEFAULT 'whatsapp',
  google_calendar_event_id TEXT,
  status TEXT DEFAULT 'active',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### shopping_items

```sql
CREATE TABLE IF NOT EXISTS skippy.shopping_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES skippy.users(id),
  item_name TEXT NOT NULL,
  quantity TEXT,
  status TEXT DEFAULT 'active',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### ai_usage

```sql
CREATE TABLE IF NOT EXISTS skippy.ai_usage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES skippy.users(id),
  model TEXT,
  operation_type TEXT,
  input_tokens INT,
  output_tokens INT,
  latency_ms INT,
  cost_estimate NUMERIC(10,6),
  created_at TIMESTAMP DEFAULT NOW()
);
```

### user_usage_daily

```sql
CREATE TABLE IF NOT EXISTS skippy.user_usage_daily (
  user_id UUID REFERENCES skippy.users(id),
  usage_date DATE NOT NULL DEFAULT CURRENT_DATE,
  messages_count INT NOT NULL DEFAULT 0,
  voice_seconds INT NOT NULL DEFAULT 0,
  PRIMARY KEY (user_id, usage_date)
);
```

## Pipeline implementacyjny

### 1. Inbound message

```txt
WhatsApp message received
↓
normalize phone
↓
load Redis context
↓
if Redis miss: load from PostgreSQL and hydrate Redis
↓
append recent message to Redis
↓
call AI
↓
send WhatsApp reply
↓
write inbound/outbound message to PostgreSQL
↓
write event_outbox
```

### 2. Redis miss

Jeśli nie ma kontekstu w Redis:

```txt
load users by phone
load plan
load profile_summary
load last messages
hydrate Redis
continue fast path
```

### 3. Event outbox processing

Worker lub n8n cyklicznie pobiera:

```sql
SELECT * FROM skippy.event_outbox
WHERE status = 'pending'
ORDER BY created_at ASC
LIMIT 50;
```

Następnie:

1. analizuje event,
2. uzupełnia intencję,
3. zapisuje profil lub usage,
4. oznacza event jako `processed`.

### 4. Nocna analiza profilu

```txt
cron 02:00
↓
select active users
↓
for each user:
  load messages from last 24h
  load current profile summary
  call stronger model
  update profile tables
  refresh Redis
  optionally write Markdown snapshot
```

## Kolejność pracy w VS Code

### Krok 1

Utwórz albo zaktualizuj schema SQL zgodnie z tabelami z tego dokumentu.

### Krok 2

Dodaj moduł Redis:

```txt
getUserContext(phone)
setUserContext(phone, context)
appendRecentMessage(phone, message)
incrementDailyUsage(phone)
clearUserCache(phone)
```

### Krok 3

Dodaj moduł Postgres:

```txt
findOrCreateUser(phone)
loadUserProfile(userId)
saveInboundMessage(...)
saveAssistantMessage(...)
createEventOutbox(...)
updateUsage(...)
```

### Krok 4

Zbuduj pipeline inbound message.

### Krok 5

Zbuduj event outbox worker albo n8n workflow.

### Krok 6

Zbuduj nocny workflow analizy profilu.

### Krok 7

Testuj na jednym numerze telefonu.

### Krok 8

Dopiero potem zaproś pierwsze testerki.

## Kryteria gotowości

System jest gotowy do pierwszych testów, gdy:

- wiadomość tekstowa przechodzi przez cały pipeline,
- Redis zapisuje i odczytuje kontekst,
- Postgres zapisuje inbound i outbound,
- event_outbox tworzy event,
- worker lub n8n przetwarza event,
- można odtworzyć historię rozmowy z bazy,
- profile_summary odświeża się po analizie,
- odpowiedź do użytkowniczki nie czeka na nocną analizę.

## Ważne ograniczenie

Pełny zapis danych jest wymagany od początku, ale nie może blokować odpowiedzi.

Najważniejsza zasada implementacyjna:

```txt
Najpierw odpowiedź dla użytkowniczki.
Potem ciężka analiza.
```

# Skippy — Finalny Plan v4

> Dla Copilota/Codexa. Jeden WhatsApp bot numer, mamy logują się przez Google.
> Voice → tekst, odpowiedź tylko zadaniowa, zero gadania.

## Architektura

```
Rejestracja: skippy.app → Google OAuth → podaj telefon → Postgres
                               ↓
Mama pisze voice/tekst na Twój WhatsApp numer
                               ↓
                        n8n (rate limiter + Postgres)
                               ↓
              Hermes OGARNIAM (jeden profil)
              agentmemory namespaced per user
              STT: voice → tekst (Whisper tiny)
              TTS: WYŁĄCZONY (odpowiedź tekstem)
                               ↓
              Google Calendar (per-user token)
```

## Wymagania serwera

**MINIMUM (do 50 mam):**
- RAM: 4 GB
- CPU: 2 vCPU
- Dysk: 20 GB

**REKOMENDOWANE (do 200 mam):**
- RAM: 8 GB
- CPU: 4 vCPU
- Dysk: 40 GB NVMe

## Task 1: PostgreSQL schema

**Plik:** `~/skippy/db/schema.sql`

```sql
CREATE TABLE users (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone                 TEXT UNIQUE NOT NULL,
    name                  TEXT,
    email                 TEXT,
    plan                  TEXT NOT NULL DEFAULT 'basic',
    daily_quota           INT NOT NULL DEFAULT 20,
    calendar_token        TEXT,
    calendar_refresh_token TEXT,
    calendar_email        TEXT,
    onboarded             BOOLEAN DEFAULT FALSE,
    created_at            TIMESTAMP DEFAULT NOW(),
    updated_at            TIMESTAMP DEFAULT NOW()
);

CREATE TABLE user_usage (
    user_id       UUID REFERENCES users(id),
    date          DATE NOT NULL DEFAULT CURRENT_DATE,
    queries_used  INT NOT NULL DEFAULT 0,
    PRIMARY KEY (user_id, date)
);

CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_user_usage_date ON user_usage(date);
```

## Task 2: Profil "skippy" — system prompt + STT/TTS

```bash
hermes profile create skippy --clone
```

**`~/.hermes/profiles/skippy/config.yaml`:**

```yaml
agent:
  disabled_toolsets:
    - terminal
    - git

system_prompt: |
  Jesteś "Skippy" — asystentką do zadań, a nie do rozmowy.

  TWOJA ROLA: planowanie, zarządzanie kalendarzem, lista zakupów,
  przypomnienia. Nic więcej.

  ZASADY:
  1. Jeśli mama prosi o zadanie (event, zakupy, przypomnienie) — wykonaj.
  2. Jeśli mama pyta "co mam dziś" — odczytaj kalendarz i podsumuj.
  3. Jeśli mama mówi COKOLWIEK spoza twoich funkcji (pogoda, polityka,
     dowcipy, rozmowa towarzyska) — odpowiedz krótko i zamknij temat:
     "Jestem asystentką do zadań, nie do rozmowy. Powiedz co mam ogarnąć 😊"
  4. Odpowiadaj po polsku, zwięźle, ciepło ale rzeczowo.
  5. Jeśli funkcja spoza planu userki — poinformuj o wyższym pakiecie.

  SYSTEM:
  - Każda użytkowniczka ma własny namespace w agentmemory.
  - Numer telefonu = klucz do jej danych, historii i preferencji.
  - Przechowuj w pamięci: dzieci, preferencje, plan, Google Calendar token,
    częste wydarzenia, nawyki.
  - Nigdy nie mieszaj kontekstu między userkami.

stt:
  enabled: true
  provider: local
  local:
    model: tiny             # tiny = szybciej + mniej RAM, kosztem minimalnej dokładności

tts:
  enabled: false            # WYŁĄCZONE — głos tylko w jedną stronę (mama→nas)

voice:
  auto_tts: false           # odpowiedzi tekstem, nie głosem

whatsapp:
  dm_policy: allow
  group_policy: disabled

mcp_servers:
  agentmemory:
    command: npx
    args: ["-y", "@agentmemory/mcp"]

memory:
  provider: agentmemory
```

**.env profilu:**
```bash
WHATSAPP_ENABLED=true
WHATSAPP_MODE=bot
# brak innych platform — usunięte Discord/Telegram
```

## Task 3: Uruchomienie połączeń WhatsApp

**Cel:** aktywować jedyny kanał komunikacji Skippy i zweryfikować pierwszy kontakt przez WhatsApp.

**Sekwencja startowa:**
1. Ustaw `WHATSAPP_ENABLED=true` i `WHATSAPP_MODE=bot` w profilu `skippy`.
2. Uruchom bridge Hermesa dla profilu `skippy`.
3. Zeskanuj QR i potwierdź, że bot numer jest online.
4. Wyślij testową wiadomość tekstową z telefonu i potwierdź odpowiedź.
5. Dopiero potem podłącz n8n rate limiter i Google Calendar flow.

**Stan docelowy:**
- tylko WhatsApp jako kanał wejścia/wyjścia,
- brak Discord/Telegram,
- odpowiedź tekstem, bez TTS.

## Task 4: WhatsApp bridge (jednorazowo Dawid)

```bash
find / -path "*/whatsapp-bridge/bridge.js" 2>/dev/null
cd $(dirname $(find / -path "*/whatsapp-bridge/bridge.js" 2>/dev/null | head -1))
npm install

hermes -p skippy whatsapp
# Zeskanuj QR → bot numer gotowy na lata
```

## Task 5: n8n rate limiter pipeline

Webhook → Postgres (sprawdź daily_quota vs queries_used)
→ IF ok: UPSERT usage + POST do Hermesa API
→ IF limit: odpowiedź "Wykorzystałaś limit na dziś, wróć jutro"

## Task 6: Google OAuth onboarding

Landing page → Zaloguj Google → Podaj telefon → Zapisz w Postgres → Wyślij WhatsApp powitalny

```python
# Endpointy:
GET /auth/google?state=<phone>
  → Google OAuth (offline, scope: calendar.events)
  → callback: zapisz token + refresh_token
  → wyślij WhatsApp: "Konto Skippy aktywowane! 🎉 Wyślij coś do ogarnięcia!"
```

## Task 7: Cron reminders

```bash
# crontab -e — codziennie 7:00
0 7 * * * curl -s -X POST https://n8n.local/webhook/skippy-daily-reminder
```

Workflow: userki premium/family → Google Calendar (wydarzenia dziś) → WhatsApp:
```
"☀️ Dzień dobry {name}! Dziś: wizyta u pediatry 15:00, zakupy 17:00. Miłego dnia!"
```

## Task 7: Feature gating przez plan

agentmemory usera przechowuje plan. System prompt regułuje:
- basic: tylko kalendarz
- premium: kalendarz + zakupy
- family: wszystko + współdzielony

## Oczekiwane opóźnienia

| Scenariusz | Czas |
|------------|------|
| Tekst → odpowiedź | **~5-8s** |
| Voice 20s → Whisper tiny → tekst → odpowiedź | **~7-10s** |
| Voice 60s → Whisper tiny → tekst → odpowiedź | **~10-15s** |

Największy wpływ: model Whisper tiny (oszczędza ~3s vs base) i wyłączony TTS.

## ⚠️ Pułapki

| Problem | Rozwiązanie |
|---------|-------------|
| Whisper nadal za wolny | Zmień na Groq Whisper API (free tier, ~1s) — wymaga GROQ_API_KEY |
| Mama próbuje gadać | System prompt tnie. Po 3 off-topicach agentmemory zapamiętuje i tnie ostrzej. |
| Token Google wygasa | Użyj refresh_token (offline access), odświeżaj cronem co 6 dni |
| WhatsApp blokada | ~250 msg/dzień. 50 mam × 5 msg = 250. Limit na styk. Po beta — zweryfikuj numer przez Meta. |
| agentmemory nie działa | Node >=18, `npx -y @agentmemory/mcp` |
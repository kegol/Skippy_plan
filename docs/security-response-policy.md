# Skippy — polityka reakcji bezpieczeństwa i blokowania użytkowników

## Cel

Skippy musi reagować na próby uzyskania dostępu do danych, ustawień systemowych, promptów, tokenów, logów lub informacji innych użytkowniczek.

Sama odmowa odpowiedzi nie wystarczy. System powinien zapisywać incydenty, podnosić poziom ryzyka i blokować użytkownika po przekroczeniu progów.

## Zasada główna

```txt
Pojedyncza podejrzana wiadomość = odmowa i log.
Powtarzalne lub poważne próby = ograniczenie, zawieszenie albo blokada.
```

## Statusy użytkownika

```txt
active
limited
suspended
blocked
manual_review
```

## Pola w tabeli users

```sql
ALTER TABLE skippy.users
ADD COLUMN IF NOT EXISTS security_status TEXT NOT NULL DEFAULT 'active',
ADD COLUMN IF NOT EXISTS risk_score INT NOT NULL DEFAULT 0,
ADD COLUMN IF NOT EXISTS blocked_reason TEXT,
ADD COLUMN IF NOT EXISTS blocked_at TIMESTAMP,
ADD COLUMN IF NOT EXISTS suspended_until TIMESTAMP,
ADD COLUMN IF NOT EXISTS manual_review_required BOOLEAN NOT NULL DEFAULT FALSE;
```

## Reakcje systemu

### Poziom 1

Pojedynczy niski sygnał ryzyka.

Akcja:

- bezpieczna odmowa,
- zapis do logu bezpieczeństwa,
- zwiększenie `risk_score`,
- brak blokady.

### Poziom 2

Powtarzalne sygnały ryzyka.

Akcja:

- bezpieczna odmowa,
- ostrzeżenie,
- zapis eventu,
- podniesienie `risk_score`,
- możliwe ograniczenie funkcji.

### Poziom 3

Wysoki poziom ryzyka.

Akcja:

- natychmiastowa odmowa,
- zapis eventu high/critical,
- czasowa blokada,
- alert do administratora.

### Poziom 4

Uporczywe lub krytyczne nadużycie.

Akcja:

- trwała blokada,
- alert do administratora,
- oznaczenie do ręcznej weryfikacji,
- brak dalszej rozmowy poza krótkim komunikatem.

## Progi ryzyka

| Risk score | Akcja |
|-----------:|-------|
| 1–2 | odmowa + log |
| 3–5 | ostrzeżenie + log |
| 6–9 | limited / cooldown |
| 10–14 | suspended + alert |
| 15+ | blocked + manual review |

## Pipeline

```txt
message_received
↓
sprawdzenie security_status
↓
security classifier / reguły
↓
if safe: normal flow
↓
if suspicious: refusal + log + risk score
↓
if threshold exceeded: limited / suspended / blocked
```

## Tabela akcji bezpieczeństwa

```sql
CREATE TABLE IF NOT EXISTS skippy.user_security_actions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES skippy.users(id),
  action_type TEXT NOT NULL,
  reason TEXT,
  previous_status TEXT,
  new_status TEXT,
  risk_score INT,
  created_by TEXT DEFAULT 'system',
  created_at TIMESTAMP DEFAULT NOW()
);
```

## Typy akcji

```txt
warning_sent
risk_score_increased
user_limited
user_suspended
user_blocked
manual_review_required
user_unblocked
false_positive_marked
```

## Komunikaty

### Blokada

```txt
Dostęp do Skippy został wstrzymany z powodów bezpieczeństwa. Jeśli uważasz, że to błąd, skontaktuj się z obsługą.
```

### Zawieszenie

```txt
Dostęp do Skippy jest tymczasowo wstrzymany z powodów bezpieczeństwa. Spróbuj ponownie później albo skontaktuj się z obsługą.
```

### Ostrzeżenie

```txt
Nie mogę pomagać w dostępie do ustawień ani danych technicznych. Mogę pomóc w Twoim kalendarzu, przypomnieniach albo zakupach.
```

## Ważne ograniczenie

Blokada nie może zależeć wyłącznie od modelu LLM. Backend musi mieć twarde reguły:

- status użytkownika,
- liczniki prób,
- progi punktowe,
- odmowa dostępu przed wywołaniem narzędzi.

## Ręczna weryfikacja

Administrator powinien mieć możliwość:

- zobaczyć eventy bezpieczeństwa,
- zmienić status użytkownika,
- wyzerować `risk_score`,
- odblokować konto,
- oznaczyć fałszywy alarm.

## Wniosek

Skippy powinien mieć automatyczną eskalację:

```txt
odmowa
↓
ostrzeżenie
↓
ograniczenie
↓
czasowa blokada
↓
trwała blokada + ręczna weryfikacja
```

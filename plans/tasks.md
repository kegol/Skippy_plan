# Taski do wykonania przez Copilota/Codexa

> Dawid nie rusza terminala. Wszystko robi Copilot.

## Task 1: PostgreSQL schema

**Lokalizacja:** `~/skippy/db/schema.sql` → przenieś na serwer i wykonaj

```bash
# Na VPS:
scp schema.sql user@vps:/tmp/
psql -h localhost -U skippy_user -d skippy -f /tmp/schema.sql
```

## Task 2: Profil Hermesa "skippy"

```bash
hermes profile create skippy --clone
# Nadpisz config.yaml treścią z prompts/system-prompt.md
# Ustaw STT, TTS, WhatsApp mode
```

**Plik konfiguracji:** `~/.hermes/profiles/skippy/config.yaml`

**Plik .env:** `~/.hermes/profiles/skippy/.env`
```
WHATSAPP_ENABLED=true
WHATSAPP_MODE=bot
```

## Task 3: WhatsApp bridge

```bash
# Znajdź bridge
find / -path "*/whatsapp-bridge/bridge.js" 2>/dev/null | head -1
cd $(dirname $(...))
npm install

# Uruchom
hermes -p skippy whatsapp
# Zeskanuj QR → bot gotowy
```

## Task 4: n8n rate limiter pipeline

Stwórz workflow n8n:
1. **Webhook** (POST /skippy-incoming)
2. **Postgres node** — sprawdź usera po numerze telefonu
3. **Postgres node** — sprawdź daily_quota vs queries_used
4. **IF** OK → UPSERT usage + HTTP POST do Hermesa API
5. **IF** limit → odpowiedź "Wykorzystałaś limit na dziś"

## Task 5: Google OAuth landing page

Stwórz prostą stronę (HTML + JS lub n8n):
- Przycisk "Zaloguj przez Google"
- Callback zapisuje token + refresh_token do Postgres
- Wysyła WhatsApp powitalny przez Hermes API

## Task 6: Cron reminders

```bash
# crontab -e
0 7 * * * curl -s -X POST https://n8n.local/webhook/skippy-daily-reminder
```

Workflow n8n: pobierz userki premium/family → Google Calendar → WhatsApp.

## Task 7: Stripe integration

- Stripe Checkout (produkty: Premium 19 PLN, Family 29 PLN)
- Webhook endpoint w n8n
- Obsługa: checkout.completed, invoice.paid, subscription.deleted

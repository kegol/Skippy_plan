# Taski do wykonania przez Copilota/Codexa

> Dawid nie rusza terminala. Wszystko robi Copilot.

## Task 1: PostgreSQL schema

**Lokalizacja:** `~/skippy/db/schema.sql` → przenieś na serwer i wykonaj

```bash
# Na VPS:
scp schema.sql user@vps:/tmp/
psql -h localhost -U skippy_user -d skippy -f /tmp/schema.sql
```

Wymagane minimum w SQL:
- `CREATE SCHEMA IF NOT EXISTS skippy;`
- tabela `skippy.whatsapp_users` do first-message onboardingu
- indeks po `phone`

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

## Task 3: WhatsApp bridge i start połączeń

**Cel:** uruchomić live połączenie WhatsApp dla profilu `skippy` zgodnie ze specyfikacją projektu.

**Wymagany stan:**
- `WHATSAPP_ENABLED=true`
- `WHATSAPP_MODE=bot`
- tylko WhatsApp, bez innych kanałów

```bash
# Znajdź bridge
find / -path "*/whatsapp-bridge/bridge.js" 2>/dev/null | head -1
cd $(dirname $(...))
npm install

# Uruchom
hermes -p skippy whatsapp
# Zeskanuj QR → bot gotowy
```

**Procedura testowa:**
1. Zaloguj bridge na WhatsApp.
2. Wyślij testową wiadomość z telefonu.
3. Potwierdź, że odpowiedź wraca przez Hermesa.

## Task 4: n8n rate limiter pipeline

Stwórz workflow n8n:
1. **Webhook** (POST /skippy-incoming)
2. **Postgres node** — sprawdź usera po numerze telefonu
3. **Postgres node** — sprawdź daily_quota vs queries_used
4. **IF** OK → UPSERT usage + HTTP POST do Hermesa API
5. **IF** limit → odpowiedź "Wykorzystałaś limit na dziś"

## Task 4a: First-message onboarding (obowiązkowe przed normalnym flow)

Skrypt ma działać przed routingiem do głównego agenta.

Runtime:
- `/opt/data/profiles/skippy_plan/bin/first_message_onboarding.py`
- `/opt/data/profiles/skippy_plan/bin/first_message_onboarding.sh`

Wymagane statusy:
- `NEED_NAME` — brak imienia, numer zapisany jako `pending`
- `UPDATED_NAME` lub `CREATED` — imię zapisane
- `FOUND` — numer już znany

Smoke test:

```bash
docker exec hermes-agent sh -lc "/opt/data/profiles/skippy_plan/bin/first_message_onboarding.sh +48555111333 hej"
docker exec hermes-agent sh -lc "/opt/data/profiles/skippy_plan/bin/first_message_onboarding.sh +48555111333 Ania"
docker exec hermes-agent sh -lc "/opt/data/profiles/skippy_plan/bin/first_message_onboarding.sh +48555111333 'co mam dzisiaj'"
docker exec beautyai-n8n-db sh -lc "psql -U n8n -d skippy -c \"SELECT phone, full_name, onboarding_status FROM skippy.whatsapp_users WHERE phone='+48555111333';\""
```

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

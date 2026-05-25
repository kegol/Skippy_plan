# Architektura Skippy

## Przepływ wiadomości

```
Mama (WhatsApp)
    │ voice notka / tekst
    ▼
n8n webhook
    │
    ├─ First message onboarding (Postgres: skippy.whatsapp_users)
    │   ├─ Nieznany numer + brak imienia -> NEED_NAME
    │   ├─ Nieznany numer + imię -> CREATED
    │   └─ Znany numer -> FOUND
    │   └─ Output do n8n: needs_name, needs_google_auth, auth_url, reply_text
    │
    ├─ Sprawdź usera (Postgres: phone)
    ├─ Rate limit (user_usage dzienny)
    │   ├─ OK → kontynuuj
    │   └─ LIMIT → "Wykorzystałaś limit na dziś"
    │
    ├─ STT (jeśli voice) → Whisper tiny
    │
    ▼
Hermes API (profil skippy)
    │
    ├─ agentmemory (namespaced per phone)
    ├─ Google Calendar API (per-user token)
    │
    ▼
Odpowiedź tekstem → n8n → WhatsApp
```

## Baza danych runtime

- Kontener: `beautyai-n8n-db`
- Baza: `skippy`
- Schema: `skippy`
- Tabele onboardingowe:
    - `skippy.whatsapp_users` (mapowanie numer ↔ imię + status onboardingu)
    - `skippy.google_oauth_tokens` (tokeny Google OAuth pod użytkowniczki)

Wniosek architektoniczny: n8n i Hermes korzystają z jednego silnika Postgres, ale logika Skippy jest izolowana przez osobną bazę i schemat.

## Uruchomienie WhatsApp bridge

Minimalna sekwencja startowa dla `skippy`:

1. W profilu Hermesa ustaw `WHATSAPP_ENABLED=true`.
2. Ustaw `WHATSAPP_MODE=bot`.
3. Uruchom profil `skippy` i zainicjuj WhatsApp bridge.
4. Zeskanuj QR z telefonu operatora.
5. Zweryfikuj, że pierwszy testowy tekst z telefonu trafia do Hermesa i wraca jako odpowiedź tekstowa.

Na tym etapie nie uruchamiamy innych kanałów komunikacji.

## Rate limiting

| Plan | Dzienny limit | Mechanizm |
|------|--------------|-----------|
| Basic | 5 | UPSERT user_usage, SELECT count |
| Premium | 50 | j.w. |
| Family | 100 | j.w. |

Reset: codziennie o 00:00 (CURRENT_DATE w PostgreSQL).

## Google OAuth

- Scope: `https://www.googleapis.com/auth/calendar.events`
- Access type: `offline` (żeby dostać refresh_token)
- Token odświeżany cronem co 6 dni lub przy błędzie 401
- Start autoryzacji jest wysyłany po onboardingu imienia, a callback tokenów jest domykany przez n8n: `skippy/google/oauth/callback`
- Runtime helper `google_auth_link.sh` zwraca `AUTH_OK` albo `AUTH_REQUIRED_URL=...` i nie wymaga już ręcznego wklejania URL przez użytkowniczkę.
- Numer wejściowy jest normalizowany do E.164 (`+48` dla 9-cyfrowych numerów PL), aby link autoryzacji był zawsze tworzony dla właściwej userki.
- Odpowiedzi onboardingowe są celowo krótkie i operacyjne (bez opisu kroków wewnętrznych).

### Troubleshooting OAuth

- W przypadku błędu `401 invalid_client` sprawdź, czy runtime używa aktywnego klienta OAuth Web.
- Redirect URI w Google musi być identyczny z callbackiem n8n, bez różnic w ścieżce/protokole.
- Aktualny runtime (2026-05-25) działa na aktywnym kliencie i poprawnym callbacku.

## Przypomnienia poranne

Cron `0 7 * * *` → n8n webhook:
1. Pobierz userki z planem premium/family z Postgres
2. Dla każdej: Google Calendar API → wydarzenia dziś
3. Wyślij WhatsApp przez Hermes API

## System płatności

**Decyzja:** Stripe (start na PESEL, działalność nierejestrowana)

- Stripe Checkout → webhook → n8n → Postgres (plan = premium/family)
- Trial 7 dni bez karty
- Po trialu downgrade do basic (5 zapytań/dzień, tylko kalendarz)
- Upgrade/downgrade/cancel przez Stripe Customer Portal

Zobacz [payments.md](payments.md) po szczegóły.

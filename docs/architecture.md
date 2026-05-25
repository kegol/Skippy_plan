# Architektura Skippy

## Przepływ wiadomości

```
Mama (WhatsApp)
    │ voice notka / tekst
    ▼
n8n webhook
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

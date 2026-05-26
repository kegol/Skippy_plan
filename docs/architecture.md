# Architektura Skippy

## Cel architektury

Skippy ma być osobistym asystentem rodzinnym przez WhatsApp, a nie prostym chatbotem. Architektura musi jednocześnie zapewnić wygodne użycie, izolację danych użytkowniczek, kontrolę kosztów AI oraz możliwość skalowania pakietów subskrypcyjnych.

## Przepływ wiadomości

```
Mama (WhatsApp)
    │ tekst / głosówka
    ▼
n8n webhook
    │
    ├─ normalizacja numeru telefonu do E.164
    ├─ First Message Onboarding
    │   ├─ nieznany numer + brak imienia -> NEED_NAME
    │   ├─ nieznany numer + imię -> CREATED / ACTIVE
    │   └─ znany numer -> FOUND
    │
    ├─ pobranie userki z PostgreSQL
    ├─ pobranie planu z skippy.plans_config
    ├─ kontrola limitów dziennych i miesięcznych
    ├─ kontrola limitu minut voice
    ├─ feature gating na podstawie flags z planu
    ├─ STT, jeśli wejściem jest głosówka
    │
    ▼
Hermes API (profil skippy)
    │
    ├─ agentmemory namespaced per phone
    ├─ Google Calendar API, jeśli calendar_enabled = TRUE
    ├─ lista zakupów, jeśli shopping_enabled = TRUE
    ├─ współdzielone funkcje, jeśli shared_enabled = TRUE
    │
    ▼
Odpowiedź tekstem → n8n → WhatsApp
```

## Źródło prawdy o pakietach

Źródłem prawdy nie jest prompt, tylko PostgreSQL.

Tabela `skippy.plans_config` przechowuje:

```sql
plan_name
monthly_price
daily_message_limit
monthly_message_limit
voice_minutes_limit
memory_days
family_members_limit
proactive_enabled
calendar_enabled
shopping_enabled
shared_enabled
```

n8n pobiera konfigurację pakietu i przekazuje Hermesowi tylko aktualny kontekst użytkowniczki:
- nazwa planu,
- dostępne funkcje,
- limity,
- zakres pamięci,
- czy można działać proaktywnie.

Hermes nie powinien samodzielnie interpretować cennika ani decydować, co jest dostępne w pakiecie.

## Pakiety

| Plan | Cena | Główna rola |
|------|-----:|-------------|
| Free | 0 PLN | Test produktu i podstawowe użycie |
| Beta Mama | 19 PLN | Promocja dla pierwszych testerek |
| Mama | 29 PLN | Codzienna organizacja |
| Mama Plus | 49 PLN | Planowanie, pamięć i sugestie |
| Family | 79 PLN | Organizacja rodziny i współdzielenie |

## Rate limiting i kontrola kosztów

Kontrola kosztów odbywa się przed wysłaniem wiadomości do Hermesa.

Mechanizm:
1. `user_usage_daily` albo dzienny zapis w `user_usage` kontroluje limit dzienny.
2. Miesięczne usage kontroluje realny koszt aktywnych użytkowniczek.
3. Voice ma osobny limit minut, bo głosówki obciążają STT i serwer.
4. Długi kontekst i pamięć są ograniczane przez `memory_days`.
5. Proaktywność jest dostępna tylko tam, gdzie `proactive_enabled = TRUE`.

Komunikat dla użytkowniczki po przekroczeniu limitu powinien być prosty, bez słów „tokeny” i bez technicznego języka.

Przykład:

```txt
Dzisiaj wykorzystałaś już dostępny limit w swoim pakiecie. Możesz wrócić jutro albo rozszerzyć plan, jeśli chcesz korzystać częściej.
```

## Baza danych runtime

- Kontener: `beautyai-n8n-db`
- Baza: `skippy`
- Schema: `skippy`
- Tabele kluczowe:
    - `skippy.users`
    - `skippy.whatsapp_users`
    - `skippy.google_oauth_tokens`
    - `skippy.user_usage`
    - `skippy.plans_config`

Wniosek architektoniczny: n8n i Hermes korzystają z jednego silnika Postgres, ale logika Skippy jest izolowana przez osobną bazę i schemat.

## WhatsApp bridge

Minimalna sekwencja startowa dla `skippy`:

1. W profilu Hermesa ustaw `WHATSAPP_ENABLED=true`.
2. Ustaw `WHATSAPP_MODE=bot`.
3. Uruchom profil `skippy` i zainicjuj WhatsApp bridge.
4. Zeskanuj QR z telefonu operatora.
5. Zweryfikuj, że pierwszy testowy tekst z telefonu trafia do Hermesa i wraca jako odpowiedź tekstowa.

Na etapie MVP używamy jednego numeru botowego. Przed skalowaniem produkcyjnym konieczna jest stabilniejsza konfiguracja WhatsApp Business / Meta.

## Google OAuth

- Scope: `https://www.googleapis.com/auth/calendar.events`
- Access type: `offline`
- Token odświeżany cronem albo przy błędzie 401
- Start autoryzacji jest wysyłany po onboardingu, jeśli plan ma `calendar_enabled = TRUE`
- Callback tokenów jest domykany przez n8n: `skippy/google/oauth/callback`
- Runtime helper `google_auth_link.sh` zwraca `AUTH_OK` albo `AUTH_REQUIRED_URL=...`
- Numer wejściowy jest normalizowany do E.164

## Przypomnienia poranne

Cron `0 7 * * *` → n8n webhook.

Workflow:
1. Pobierz aktywne użytkowniczki.
2. Sprawdź plan i feature flags.
3. Jeśli `calendar_enabled = TRUE`, pobierz wydarzenia z Google Calendar.
4. Jeśli plan pozwala na proaktywne działanie, dodaj krótką sugestię.
5. Wyślij tekst przez WhatsApp.

## System płatności

- Stripe Checkout → webhook → n8n → Postgres
- Stripe Customer Portal do zmian planu i anulowania subskrypcji
- Trial może kończyć się downgradem do Free
- Po nieudanej płatności działa okres karencji, opisany w `docs/payments.md`

## Zasady bezpieczeństwa i separacji danych

- Numer telefonu jest kluczem identyfikacyjnym użytkowniczki.
- Każda użytkowniczka ma osobny namespace pamięci.
- Hermes nie może mieszać kontekstu między użytkowniczkami.
- Dane rodzinne są używane wyłącznie do organizacji zadań, kalendarza, zakupów i przypomnień.
- Informacje techniczne nie są pokazywane użytkowniczce.

# Skippy — Finalny Plan v4.1

> Dokumentacja produktowo-techniczna dla Copilota/Codexa. Jeden WhatsApp bot numer, użytkowniczki logują się przez Google, a dostęp do funkcji wynika z konfiguracji pakietu w PostgreSQL.

## Architektura

```
Rejestracja / pierwszy kontakt WhatsApp
                               ↓
First Message Onboarding → Postgres
                               ↓
Google OAuth, jeśli funkcja kalendarza jest dostępna w planie
                               ↓
Mama pisze voice/tekst na numer Skippy
                               ↓
n8n: identyfikacja userki, plan, limity, usage, feature flags
                               ↓
Hermes: profil skippy + agentmemory namespaced per phone
                               ↓
Google Calendar / lista zakupów / przypomnienia / pamięć
                               ↓
Odpowiedź tekstem przez WhatsApp
```

## Pozycjonowanie produktu

Skippy nie jest prostym botem do przypomnień. To osobisty asystent rodzinny przez WhatsApp, który z czasem uczy się rytmu domu, dzieci, stałych zajęć, zakupów i codziennych preferencji.

## Wymagania serwera

**Minimum do MVP i pierwszych testów:**
- RAM: 4 GB
- CPU: 2 vCPU
- Dysk: 20 GB

**Rekomendowane do pierwszych 100–200 użytkowniczek:**
- RAM: 8 GB
- CPU: 4 vCPU
- Dysk: 40 GB NVMe

Serwer musi utrzymać Hermesa, n8n, PostgreSQL, lokalne STT, webhooki, logi, backupy i monitoring. Koszt VPS jest częścią ekonomii subskrypcji.

## Model pakietów

| Plan | Cena | Cel | Limit operacyjny |
|------|-----:|-----|------------------|
| Free | 0 PLN | Test produktu | 5 wiadomości/dzień |
| Beta Mama | 19 PLN | Promocja dla pierwszych testerek | jak Mama |
| Mama | 29 PLN | Codzienna organizacja | ok. 600–800 wiadomości/mies. |
| Mama Plus | 49 PLN | Planowanie, pamięć, sugestie | ok. 1500 wiadomości/mies. |
| Family | 79 PLN | Organizacja całej rodziny | ok. 2500 wiadomości/mies. |

Limity nie są komunikowane jako tokeny. Użytkowniczka widzi prosty komunikat o rozsądnym limicie użycia, aby Skippy działał szybko i stabilnie.

## Task 1: PostgreSQL schema

Źródłem prawdy jest `db/schema.sql`.

Najważniejsze założenie: prompt nie decyduje samodzielnie o pakiecie. n8n pobiera konfigurację planu z `skippy.plans_config` i przekazuje Hermesowi tylko aktualny kontekst użytkowniczki.

Kluczowe pola w `plans_config`:

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

## Task 2: Profil Hermesa `skippy`

Profil Hermesa ma być bezpieczny, krótki i zadaniowy, ale nie może niszczyć relacji z użytkowniczką. Skippy może odpowiedzieć empatycznie, jeśli mama pisze o przeciążeniu, ale delikatnie wraca do organizacji.

Zasady:
- odpowiedzi krótkie,
- brak logów i technicznych komunikatów,
- brak nazw narzędzi,
- brak opisu procesów wewnętrznych,
- odpowiedź tekstem, bez TTS,
- głosówki są wejściem, odpowiedzi są tekstem,
- każdy numer telefonu ma własny namespace pamięci.

## Task 3: WhatsApp bridge

Stan docelowy:
- tylko WhatsApp jako kanał wejścia/wyjścia,
- brak Discord/Telegram,
- odpowiedzi tekstowe,
- jeden numer botowy na start,
- przed skalowaniem wymagane przejście na stabilniejszą konfigurację WhatsApp Business / Meta.

## Task 4: Onboarding pierwszej wiadomości

Cel: pierwsza wiadomość z nieznanego numeru nie trafia od razu do normalnego flow zadań. Najpierw ustalamy imię i zapisujemy użytkowniczkę.

Reguły:
- nieznany numer + brak imienia: `NEED_NAME`, rekord `pending`, krótka prośba o imię,
- ten sam numer + odpowiedź imieniem: zapis `full_name`, status `active`,
- znany numer: normalny flow,
- numer telefonu normalizowany do E.164,
- brak pytania o numer telefonu w rozmowie, jeśli numer jest już znany z WhatsApp.

## Task 5: n8n rate limiter i feature gating

n8n jest warstwą kontroli kosztów.

Flow:
1. Odbierz wiadomość.
2. Znormalizuj numer telefonu.
3. Pobierz użytkowniczkę z `skippy.users`.
4. Pobierz plan z `skippy.plans_config`.
5. Sprawdź dzienny i miesięczny limit wiadomości.
6. Jeśli voice: sprawdź miesięczny limit minut głosówek.
7. Jeśli funkcja nie jest dostępna w planie: zwróć krótką informację o możliwości rozszerzenia pakietu.
8. Jeśli limit OK: zapisz usage i przekaż do Hermesa.
9. Hermes otrzymuje tylko potrzebny kontekst: plan, dostępne funkcje, memory_days, proactive_enabled.

## Task 6: Google OAuth onboarding

Google OAuth jest wymagany tylko wtedy, gdy użytkowniczka korzysta z funkcji kalendarza.

Flow:
1. Użytkowniczka przechodzi onboarding.
2. n8n sprawdza, czy plan ma `calendar_enabled = TRUE`.
3. Jeśli tak, Skippy wysyła krótki link autoryzacji Google.
4. Callback n8n zapisuje token i refresh token.
5. Po poprawnej autoryzacji Skippy wysyła krótkie potwierdzenie.

Nie wymagamy ręcznego wklejania URL przez użytkowniczkę.

## Task 7: Przypomnienia poranne

Cron `0 7 * * *` → n8n webhook.

Workflow:
1. Pobierz aktywne użytkowniczki z planem, który ma `calendar_enabled = TRUE`.
2. Sprawdź, czy plan ma dostęp do porannego podsumowania.
3. Pobierz wydarzenia z Google Calendar.
4. Wyślij krótkie podsumowanie dnia przez WhatsApp.

Przykład:

```txt
Dzień dobry Aniu. Dziś: pediatra 15:00 i zakupy po pracy. Chcesz, żebym przypomniała godzinę wcześniej?
```

## Task 8: Pamięć i personalizacja

Pamięć nie jest nielimitowana. Zakres pamięci wynika z planu:
- Free: krótka pamięć testowa,
- Mama: podstawowe preferencje i rytm dnia,
- Mama Plus: dłuższa pamięć, rutyny i sugestie,
- Family: pamięć rodzinna, kilku domowników i wspólne zadania.

Przechowujemy tylko informacje potrzebne do organizacji:
- imiona dzieci,
- stałe zajęcia,
- preferencje zakupowe,
- cykliczne obowiązki,
- ważne daty,
- typowe godziny i rutyny.

## Task 9: Kontrola kosztów

Kontrola kosztów jest obowiązkowa od MVP.

Mierzymy:
- liczba wiadomości dziennie i miesięcznie,
- liczba minut voice,
- liczba zapytań do LLM,
- średni koszt AI na użytkowniczkę,
- średni koszt infrastruktury na użytkowniczkę,
- wykorzystanie limitów,
- liczba przekroczeń limitu,
- liczba upgrade'ów po przekroczeniu limitu.

## Oczekiwane opóźnienia

| Scenariusz | Czas |
|------------|------|
| Tekst → odpowiedź | ~5–8s |
| Voice 20s → STT → odpowiedź | ~7–10s |
| Voice 60s → STT → odpowiedź | ~10–15s |

Największy wpływ na opóźnienie mają STT, model LLM, długość kontekstu i liczba wywołań narzędzi.

## Pułapki

| Problem | Ryzyko | Rozwiązanie |
|---------|--------|-------------|
| Za tanie pakiety | Brak marży na rozwój | Pakiety 29/49/79 PLN i kontrola usage |
| Zbyt duży Free | Użytkowniczki nie konwertują | Free tylko jako test produktu |
| Zbyt agresywny prompt | Skippy brzmi jak automat | Krótko, ale empatycznie |
| Brak kontroli voice | Głosówki zjadają zasoby | `voice_minutes_limit` per plan |
| Limity tylko dzienne | Aktywne userki generują duży koszt | dzienny + miesięczny limit |
| Prompt steruje pakietami | Chaos i trudny rozwój | plan i feature flags z Postgres |
| WhatsApp blokada | Ryzyko przy skali | Meta/WhatsApp Business przed produkcją |

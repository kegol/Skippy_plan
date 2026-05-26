# Skippy — droga od pomysłu do pierwszych użytkowniczek

## Cel

Celem nie jest zbudowanie od razu pełnego systemu dla tysięcy użytkowniczek. Celem MVP jest sprawdzenie, czy mamy faktycznie wracają do Skippy same, bez przypominania.

Pierwszy produkt powinien działać szybko, prosto i przewidywalnie.

## Aktualny stan

Założenia startowe:

- działa autoryzacja Google,
- działa połączenie z WhatsAppem,
- istnieje `soul.md` / profil zachowania Skippy,
- istnieje koncepcja pakietów,
- baza główna: PostgreSQL,
- szybka pamięć: Redis albo cache w procesie,
- RAG/wektory odłożone na później.

## Decyzja: fast path + background path

Skippy musi być płynny w rozmowie. Pełna ścieżka przez n8n i PostgreSQL przed każdą odpowiedzią może być zbyt wolna.

Dlatego system dzielimy na dwie ścieżki.

### Fast path — rozmowa dzienna

```txt
WhatsApp
↓
Skippy Router / Hermes
↓
Redis albo cache profilu
↓
tani szybki model
↓
WhatsApp reply
```

Fast path ma odpowiadać możliwie szybko. Tu nie robimy ciężkiej analizy, segmentacji ani pełnego zapisu profilu.

### Background path — zapis i analiza

```txt
zdarzenie rozmowy
↓
n8n / worker / kolejka
↓
PostgreSQL
↓
analiza intencji
↓
aktualizacja profilu
↓
Markdown snapshot
```

Background path nie blokuje odpowiedzi użytkowniczce.

### Nocna analiza

Raz dziennie, np. w nocy, system może używać mocniejszego modelu do:

- analizy wiadomości,
- porządkowania profilu,
- wykrywania rutyn,
- aktualizacji preferencji,
- segmentacji użytkowniczki,
- czyszczenia nieistotnej pamięci,
- uzupełniania profilu w PostgreSQL i Markdown.

```txt
PostgreSQL
↓
lepszy model nocny
↓
profile_summary
↓
rutyny, preferencje, segmenty
↓
PostgreSQL + Markdown snapshot
```

## Rola PostgreSQL

PostgreSQL jest źródłem prawdy dla:

- użytkowniczek,
- pakietów,
- limitów,
- płatności,
- zadań,
- przypomnień,
- zakupów,
- profili,
- preferencji,
- analityki,
- kosztów,
- segmentacji.

PostgreSQL nie powinien być wąskim gardłem każdej odpowiedzi.

## Rola Redis/cache

Redis albo cache w procesie jest warstwą szybkości.

Przechowuje:

- aktualny kontekst użytkowniczki,
- plan i feature flags,
- krótkie `profile_summary`,
- ostatnie wiadomości,
- tymczasowy stan rozmowy,
- szybkie liczniki usage.

Postgres jest trwały. Redis jest szybki.

## Rola n8n

n8n nie powinien być głównym mózgiem rozmowy, jeśli zależy nam na płynności.

n8n powinien obsługiwać:

- Google OAuth,
- Stripe webhooki,
- zapisy asynchroniczne,
- nocne analizy,
- raporty,
- aktualizacje profili,
- generowanie snapshotów Markdown,
- zadania cykliczne.

## Rola Hermesa

Hermes może być głównym silnikiem rozmowy, jeśli pozwala na:

- szybkie odpowiedzi przez WhatsApp,
- dostęp do cache/profilu użytkowniczki,
- dynamiczne przekazywanie kontekstu planu,
- wywołanie prostych narzędzi,
- wysyłanie eventów do background path,
- pracę bez blokowania się na n8n/PostgreSQL przy każdej wiadomości.

## Ryzyko: ograniczenia Hermesa

Jeśli Hermes nie pozwoli na wystarczająco dużą kontrolę nad routingiem, cache, eventami i modelami, trzeba dodać cienką warstwę przed Hermesem.

Robocza nazwa: `Skippy Router`.

### Skippy Router robiłby:

- odbiór wiadomości z WhatsApp bridge,
- identyfikację userki,
- szybki odczyt Redis/cache,
- wybór modelu,
- budowę krótkiego kontekstu,
- wywołanie Hermesa albo LLM API,
- wysłanie odpowiedzi,
- asynchroniczne wysłanie eventu do n8n/PostgreSQL.

Wtedy Hermes zostaje silnikiem AI, ale nie musi odpowiadać za całą architekturę produktu.

## MVP — 5 intencji

Pierwsza wersja Skippy powinna obsługiwać tylko 5 intencji:

```txt
add_reminder
add_calendar_event
read_calendar
add_shopping_item
small_talk_to_task
```

To wystarczy, aby sprawdzić, czy produkt daje realną wartość.

## Minimalne tabele MVP

```txt
users
plans_config
user_usage
user_messages
user_tasks
user_reminders
shopping_items
user_profile_summary
user_preferences
family_members
event_outbox
```

## Minimalny onboarding

1. Użytkowniczka pisze do Skippy.
2. Skippy prosi o imię, jeśli go nie zna.
3. Jeśli potrzebny jest kalendarz, wysyła link Google OAuth.
4. Po aktywacji pokazuje 3 przykłady użycia.

Przykład:

```txt
Cześć Aniu, jestem Skippy. Możesz pisać do mnie tak: „przypomnij mi jutro o stroju na basen”, „dodaj mleko do zakupów” albo „co mam dziś w kalendarzu?”.
```

## Pierwsze użytkowniczki

Nie zaczynamy od kampanii reklamowej.

Pierwsza grupa:

- 5–10 zaufanych mam,
- znajome,
- osoby z otoczenia,
- użytkowniczki, które realnie korzystają z WhatsAppa,
- osoby mające dużo obowiązków rodzinnych.

Cel testu:

- czy rozumieją, co napisać,
- czy Skippy odpowiada wystarczająco szybko,
- czy zadania trafiają tam, gdzie powinny,
- czy wracają następnego dnia,
- co jest dla nich naprawdę przydatne.

## Metryki MVP

Mierzymy tylko najważniejsze rzeczy:

- liczba wiadomości dziennie,
- czas odpowiedzi,
- liczba powrotów następnego dnia,
- liczba dodanych przypomnień,
- liczba dodanych wydarzeń,
- liczba użyć listy zakupów,
- liczba głosówek,
- błędy i niezrozumiane intencje,
- ręczny feedback testerek.

Najważniejsza metryka:

```txt
Czy mama sama wraca do Skippy następnego dnia?
```

## Kiedy Skippy jest gotowy na pierwsze testy

Skippy jest gotowy do pierwszych 5–10 użytkowniczek, gdy:

- odpowiada w kilka sekund,
- potrafi dodać przypomnienie,
- potrafi dodać coś do kalendarza,
- potrafi odczytać kalendarz,
- potrafi dodać zakupy,
- nie gubi użytkowniczki po pierwszej wiadomości,
- ma podstawowy log błędów,
- można ręcznie naprawić problem, jeśli coś pójdzie źle.

## Kolejność prac

1. Domknąć 5 intencji MVP.
2. Ustalić, czy Hermes sam obsłuży fast path.
3. Jeśli nie, zaprojektować cienki `Skippy Router`.
4. Uporządkować PostgreSQL pod MVP.
5. Dodać Redis/cache dla profilu użytkowniczki.
6. Dodać `event_outbox` i background path.
7. Dodać nocną analizę profilu.
8. Zaprosić 5–10 testerek.
9. Obserwować 7 dni.
10. Dopiero potem poprawiać pakiety, onboarding i sprzedaż.

# Skippy — strategia Google Calendar first

## Decyzja

MVP Skippy startuje od Google Calendar jako pierwszej i jedynej obowiązkowej integracji wizualnej.

Nie wymagamy od użytkowniczki instalowania Google Tasks, Google Keep ani dodawania kilku widgetów na pulpit.

## Dlaczego Google Calendar jako pierwszy

Google Calendar daje natychmiastowy wizualny ślad dla spraw z datą i godziną:

- wizyty lekarskie,
- zajęcia dzieci,
- spotkania,
- przypomnienia czasowe,
- obowiązki o konkretnej godzinie,
- plan dnia.

To rozwiązuje największy problem samego WhatsAppa: użytkowniczka nie musi wracać do rozmowy, żeby zobaczyć wydarzenia czasowe.

## Co jest w MVP

Obowiązkowe na start:

- WhatsApp jako kanał rozmowy,
- Google Calendar jako wizualny kalendarz,
- PostgreSQL jako źródło prawdy,
- Skippy jako asystent dodawania i odczytu wydarzeń.

Opcjonalne później:

- Google Tasks,
- Google Keep,
- widgety,
- własna aplikacja Android,
- mini panel webowy / PWA.

## Zadania i zakupy na start

Zadania i lista zakupów nie są synchronizowane z Google Tasks ani Google Keep w pierwszym MVP.

Na start są przechowywane w Skippy/PostgreSQL i pokazywane w rozmowie.

Przykład:

```txt
Dodałem mleko, chleb i banany do zakupów.

Lista zakupów:
1. mleko
2. chleb
3. banany
```

Jeśli lista będzie długa, docelowo Skippy powinien odsyłać do prostego panelu webowego lub PWA.

## Google Tasks

Google Tasks może być integracją opcjonalną w późniejszym etapie.

Nie jest wymagany w onboardingu, bo zwiększa tarcie:

```txt
zainstaluj aplikację
↓
zaloguj się
↓
dodaj widget
↓
naucz się korzystać
```

To jest zbyt dużo jak na pierwszy kontakt z produktem.

## Google Keep

Google Keep również nie jest elementem MVP.

Może być rozważony później jako opcjonalny eksport notatek, ale nie powinien być wymagany do podstawowego działania Skippy.

## Podział odpowiedzialności

```txt
WhatsApp = rozmowa i szybkie dodawanie
Google Calendar = wydarzenia z datą/godziną
PostgreSQL = zadania, zakupy, profil, usage
Skippy = warstwa asystenta i pamięci
PWA / Android = późniejszy wizualny panel zadań i zakupów
```

## Onboarding MVP

Pierwszy onboarding nie powinien wymagać instalowania dodatkowych aplikacji.

Flow:

1. Użytkowniczka pisze do Skippy na WhatsAppie.
2. Skippy pyta o imię.
3. Skippy pokazuje 3 przykłady użycia.
4. Jeśli użytkowniczka chce dodać lub odczytać wydarzenia, Skippy wysyła link do Google Calendar OAuth.
5. Po połączeniu kalendarza Skippy może dodawać i odczytywać wydarzenia.

## Przykładowe komunikaty

### Dodawanie wydarzenia

```txt
Dodałem wizytę u dentysty do Google Calendar na piątek o 16:00.
```

### Brak połączonego kalendarza

```txt
Żeby dodać to do kalendarza, połącz Google Calendar. Kliknij link i wróć tutaj po połączeniu.
```

### Lista zakupów

```txt
Dodałem mleko do zakupów. Na liście masz teraz: mleko, chleb i banany.
```

### Zadania

```txt
Dodałem zadanie: spakować strój na basen. Chcesz przypomnienie dziś wieczorem?
```

## Wniosek

Na start Skippy nie powinien wymagać od mamy budowania systemu organizacji z kilku aplikacji Google.

Google Calendar wystarczy jako pierwsza integracja wizualna. Reszta zostaje w Skippy i może zostać przeniesiona do PWA lub aplikacji Android w kolejnych etapach.

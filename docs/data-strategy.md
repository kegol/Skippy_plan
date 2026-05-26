# Strategia danych Skippy: Markdown + PostgreSQL

## Decyzja

Skippy powinien używać modelu hybrydowego:

- PostgreSQL jako źródło prawdy dla aplikacji, analityki, personalizacji i automatyzacji.
- Markdown jako czytelna warstwa dokumentacyjna, backupowa i operatorska.

Nie należy opierać działania aplikacji wyłącznie na plikach `.md`, ponieważ utrudni to segmentację, analizę zachowań, kontrolę kosztów, limity, automatyzacje i rozwój produktu.

## Co trzymamy w PostgreSQL

PostgreSQL przechowuje dane operacyjne i analityczne:

- użytkowniczki,
- plany i subskrypcje,
- usage dzienne i miesięczne,
- wiadomości i typy intencji,
- zadania,
- przypomnienia,
- wydarzenia kalendarza,
- listy zakupów,
- preferencje,
- segmenty,
- consent/privacy,
- koszty AI,
- konwersje,
- retencję.

## Co trzymamy w Markdown

Markdown przechowuje czytelny snapshot wiedzy o użytkowniczce:

- podsumowanie profilu,
- rytm dnia,
- dzieci i stałe zajęcia,
- ważne preferencje,
- aktualne obserwacje,
- notatki operatorskie,
- wnioski z analizy,
- podsumowania tygodniowe/miesięczne.

Markdown nie jest źródłem limitów, płatności ani stanu aplikacji.

## Dlaczego hybryda

| Obszar | PostgreSQL | Markdown |
|--------|------------|----------|
| Aplikacja | TAK | NIE |
| Limity i plany | TAK | NIE |
| Analityka | TAK | pomocniczo |
| Personalizacja | TAK | pomocniczo |
| Czytelność dla człowieka | średnia | bardzo dobra |
| Backup wiedzy | TAK | TAK |
| Segmentacja | TAK | NIE |
| Dashboard | TAK | NIE |
| Eksport profilu | TAK | TAK |

## Proponowana struktura Markdown

```txt
/user-profiles/
  /+48500111222/
    profile.md
    weekly-summary-2026-05-26.md
    preferences.md
    observations.md
```

## Przykład `profile.md`

```md
# Profil użytkowniczki

## Dane podstawowe
- Imię: Ania
- Plan: Mama Plus
- Status: active

## Rodzina
- Dzieci: Zosia, Kuba
- Stałe zajęcia: basen we wtorki, angielski w czwartki

## Rytm dnia
- Poranki intensywne między 7:00 a 8:30
- Zakupy zwykle w piątki

## Preferencje
- Lubi krótkie przypomnienia
- Nie lubi długich list rano

## Obserwacje
- Często prosi o plan tygodnia w niedzielę wieczorem
```

## Synchronizacja Postgres → Markdown

Markdown powinien być generowany okresowo z bazy:

- po onboardingu,
- po większej zmianie profilu,
- raz dziennie dla aktywnych użytkowniczek,
- raz tygodniowo jako podsumowanie.

Kierunek podstawowy:

```txt
PostgreSQL → generator profilu → Markdown snapshot
```

Nie zaleca się dwukierunkowej synchronizacji na starcie, bo zwiększa ryzyko konfliktów.

## Minimalny model danych do personalizacji

Tabele, które powinny istnieć lub zostać dodane:

```txt
skippy.users
skippy.user_profiles
skippy.user_preferences
skippy.family_members
skippy.user_events
skippy.user_tasks
skippy.shopping_items
skippy.user_messages
skippy.user_intents
skippy.user_segments
skippy.user_usage
skippy.ai_costs
skippy.user_consents
```

## Zasada prywatności

Nie zapisujemy wszystkiego bezrefleksyjnie. Skippy powinien zapisywać tylko dane, które pomagają w organizacji życia użytkowniczki.

Przykłady danych uzasadnionych:
- imiona dzieci,
- stałe zajęcia,
- preferencje przypomnień,
- godziny rutyn,
- częste zakupy,
- ważne daty.

Przykłady danych wrażliwych lub zbędnych:
- szczegółowe problemy zdrowotne,
- konflikty rodzinne,
- dane finansowe,
- treści prywatne niezwiązane z organizacją.

## Wniosek

PostgreSQL powinien być mózgiem aplikacji. Markdown powinien być czytelną kartą użytkowniczki, backupiem i warstwą dla operatora/AI podczas audytu lub ręcznej analizy.

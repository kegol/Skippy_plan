# Skippy — strategia kanałów komunikacji

## Cel

Skippy ma być asystentem, z którym mama może rozmawiać szybko, naturalnie i bez tarcia. Kanał komunikacji musi być wygodny, ale nie może ograniczać rozwoju produktu.

## Decyzja na start

Na MVP używamy WhatsAppa, bo:

- użytkowniczki już go mają,
- nie trzeba instalować nowej aplikacji,
- wejście do testów jest szybkie,
- można sprawdzić realną potrzebę bez budowania pełnego produktu mobilnego.

WhatsApp jest kanałem walidacji, niekoniecznie kanałem docelowym na lata.

## Największe ograniczenia WhatsAppa

1. Zależność od Meta.
2. Brak pełnej kontroli nad UX.
3. Brak własnego wywołania głosem.
4. Ryzyko ograniczeń regulaminowych i technicznych.
5. Głosówki mogą wymagać własnej transkrypcji po stronie backendu.
6. Trudniejsza kontrola nad płynnym doświadczeniem użytkowniczki.
7. Ryzyko problemów z nieoficjalnym bridge przy większej skali.

## Transkrypcja WhatsApp

Nie zakładamy, że bot dostanie gotową transkrypcję głosówki z WhatsAppa.

Bezpieczne założenie techniczne:

```txt
WhatsApp dostarcza audio
↓
Skippy robi własne STT
↓
AI dostaje tekst
```

Jeśli WhatsApp pokazuje transkrypcję użytkowniczce lokalnie na telefonie, nie oznacza to automatycznie, że backend Skippy ma dostęp do tej transkrypcji.

## Rola WhatsAppa

WhatsApp służy do:

- pierwszych testów,
- walidacji potrzeby,
- sprawdzenia języka użytkowniczek,
- zebrania pierwszych danych,
- nauczenia się, jak mamy naprawdę korzystają z asystenta.

## Docelowy kierunek: własna aplikacja Android

Docelowo Skippy powinien mieć własną aplikację Android albo lekki komunikator/asystent.

Aplikacja daje:

- własny przycisk głosu,
- własny interfejs zadań,
- push notifications,
- listę zakupów,
- widok przypomnień,
- onboarding bez ograniczeń WhatsAppa,
- lepszą personalizację,
- niezależność od Meta,
- możliwość budowy prawdziwego asystenta głosowego.

## Docelowy flow głosowy

```txt
Mama mówi: Skippy, przypomnij mi jutro o stroju na basen
↓
Aplikacja Android
↓
STT
↓
Skippy Router / AI
↓
Potwierdzenie tekstem lub głosem
↓
Przypomnienie / kalendarz / zadanie
```

## Rocket.Chat

Rocket.Chat nie jest rekomendowany jako główny kanał dla mam na start.

Powód:

```txt
Użytkowniczki prawdopodobnie nie będą chciały instalować osobnego komunikatora tylko dla Skippy.
```

Rocket.Chat może mieć sens jako:

- panel operatorski,
- wewnętrzny inbox,
- środowisko testowe,
- komunikator dla wersji B2B,
- zaplecze supportu,
- miejsce monitorowania błędów i rozmów.

## Etapy kanałów

### Etap 1 — MVP

```txt
WhatsApp + Hermes
```

Cel: 5–10 testerek.

### Etap 2 — Beta

```txt
WhatsApp + Hermes + Postgres + Redis/cache + background analysis
```

Cel: 20–50 użytkowniczek.

### Etap 3 — Stabilizacja

```txt
WhatsApp Business / Meta + Skippy Router
```

Cel: kontrola skalowania i ryzyk.

### Etap 4 — Własna aplikacja Android

```txt
Android app + voice trigger + push + Skippy backend
```

Cel: pełna kontrola UX i głosu.

### Etap 5 — Dedykowany komunikator / companion app

Dopiero po potwierdzeniu retencji i realnej potrzeby.

## Wniosek

Największym ograniczeniem na start nie jest serwer, tylko kanał komunikacji i kontrola nad doświadczeniem użytkowniczki.

WhatsApp jest dobry do walidacji. Własna aplikacja Android jest lepszym kierunkiem docelowym.
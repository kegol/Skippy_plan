⚠️ ZANIM COKOLWIEK ZROBISZ W TYM REPO:

1. **OTWÓRZ I PRZECZYTAJ** `~/BeautyAI_hub/AGENTS.md` — to KANON. Ten plik jest NADRZĘDNY.
2. Sprawdź `git status`.
3. Wróć do tego pliku po specyfikę projektu.
4. Po sesji: log do `~/BeautyAI_hub/05-AGENTS/agent-log.md`.

---

# Skippy_plan — Instrukcje dla agentów AI

To repozytorium zawiera **wyłącznie dokumentację planu produktu Skippy** (asystent AI dla mam przez WhatsApp). Żaden kod produkcyjny tu nie leży.

## Struktura

```
Skippy_plan/
├── README.md              ← Główny wpis, tabela z linkami do wszystkich dokumentów
├── AGENTS.md              ← ← jesteś tutaj
├── .github/
│   └── copilot-instructions.md  ← Instrukcje dla GitHub Copilot
├── docs/
│   ├── plan.md            ← Kompletny plan implementacji v4 (PRZECZYTAJ NAJPIERW)
│   ├── architecture.md    ← Architektura systemu
│   └── payments.md        ← System płatności (Stripe vs Autopay)
├── plans/
│   ├── roadmap.md         ← Roadmapa rozwoju
│   └── tasks.md           ← Taski do wdrożenia przez Copilota
├── prompts/
│   └── system-prompt.md   ← System prompt dla profilu Hermesa
└── db/
    └── schema.sql         ← PostgreSQL schema
```

## Zasady edycji dokumentów

1. **README.md** to spis treści — aktualizuj go gdy dodajesz/uswasz dokumenty.
2. **docs/plan.md** to główny dokument — zmiany w architekturze, cenniku, stacku technologicznym lądują TUTAJ.
3. **docs/architecture.md** — szczegóły techniczne, przepływy, diagramy.
4. **docs/payments.md** — wszystko co dotyczy systemu płatności.
5. **plans/roadmap.md** — zmiany w harmonogramie, fazach, KPI.
6. **plans/tasks.md** — konkretne taski dla Copilota.
7. **prompts/system-prompt.md** — system prompt i konfiguracja profilu Hermesa.
8. **db/schema.sql** — schema bazy danych PostgreSQL.

## Kluczowe zasady

- **NIE mieszaj treści między dokumentami** — każdy plik ma swoją rolę.
- Jeśli zmieniasz coś w architekturze → zaktualizuj zarówno `docs/plan.md` (główny) jak i `docs/architecture.md` (szczegóły).
- Jeśli zmieniasz cennik → zaktualizuj `docs/plan.md` i README.md.
- Dokumenty są dla ludzi i dla AI — pisz czytelnie, konkretnie, bez lania wody.
- Zachowaj formatowanie markdown, tabele, listy, code blocki.

## Bezpieczeństwo

To repo jest publiczne. NIE zapisuj:
- haseł, tokenów, kluczy API
- prawdziwych danych klientów
- konfiguracji z sekretami

Wszystkie wartości konfiguracyjne w dokumentach to przykłady/placeholdery.

## Koniec zadania

Na koniec:
- zaktualizuj `agent-log.md` w `~/BeautyAI_hub/05-AGENTS/`
- podaj zmienione pliki
- wskaz rzeczy do zrobienia ręcznie

# 🗺️ Skippy Plan — Dokumentacja Produktu

> **Pełny plan budowy i rozwoju Skippy — asystenta AI dla mam przez WhatsApp.**

To repo zawiera kompletną dokumentację produktu **Skippy** — od architektury, przez model biznesowy, po konkretne taski implementacyjne dla Copilota.

## 📄 Dokumenty

| Plik | Opis |
|------|------|
| **[📋 Plan budowy i rozwoju](docs/plan.md)** | Kompletny plan implementacji v4 — schema bazy, konfiguracja profilu, n8n pipeline, cennik |
| **[🏗️ Architektura systemu](docs/architecture.md)** | Przepływ wiadomości, rate limiting, Google OAuth, cron reminders |
| **[🧠 Specyfikacja startu rozmowy](docs/conversation-onboarding-spec.md)** | Dokładna logika onboardingu: stany, warunki, kontrakt JSON, testy akceptacyjne |
| **[💰 System płatności](docs/payments.md)** | Stripe vs Autopay analiza + flow subskrypcji |
| **[🗺️ Roadmapa](plans/roadmap.md)** | Fazy rozwoju: MVP → Beta → Produkcja → Skalowanie |
| **[✅ Taski do wdrożenia](plans/tasks.md)** | Konkretne polecenia dla Copilota/Codexa |
| **[🤖 System Prompt](prompts/system-prompt.md)** | System prompt dla profilu Hermesa + konfiguracja YAML |
| **[🗄️ Schema bazy](db/schema.sql)** | PostgreSQL — schema `skippy`, users, user_usage, plans_config, whatsapp_users |
| **[🌐 Landing page](index.html)** | Prosta strona "Skippy" pod domenę skippyplan.pl |

## 🎯 Produkt

Skippy pomaga mamom zarządzać dniem przez WhatsApp:
- **Kalendarz** — Google Calendar (per-user OAuth)
- **Lista zakupów** — agentmemory (bez zewnętrznych API)
- **Notatki** — agentmemory
- **Przypomnienia** — Postgres + cron 7:00
- **Pamięć rodziny** — imiona dzieci, rytm dnia, stałe zajęcia, preferencje i nawyki
- **Planowanie tygodnia** — w płatnych pakietach jako funkcja premium

## 💰 Model subskrypcyjny

Skippy nie jest wyceniany jako prosty bot do przypomnień, tylko jako rodzinny asystent organizacyjny przez WhatsApp. Cena musi pokrywać tokeny LLM, transkrypcję głosówek, serwer VPS, n8n, PostgreSQL, monitoring, utrzymanie WhatsApp bridge, rozwój produktu i realną obsługę użytkowniczek.

| Plan | Cena/mies. | Charakter pakietu | Limit operacyjny |
|------|-----------:|-------------------|------------------|
| Free | 0 PLN | Test produktu i podstawowe przypomnienia | 5 wiadomości/dzień |
| Beta Mama | 19 PLN | Cena promocyjna dla pierwszych testerek | limit jak Mama |
| Mama | 29 PLN | Codzienna organizacja mamy | ok. 600–800 wiadomości/mies. |
| Mama Plus | 49 PLN | Aktywne planowanie, pamięć i sugestie | ok. 1500 wiadomości/mies. |
| Family | 79 PLN | Rodzinny organizator dla kilku osób | ok. 2500 wiadomości/mies. |

### Zasada komunikacji limitów

Na landing page i w komunikacji do użytkowniczek nie mówimy o tokenach, promptach ani kosztach AI. Zamiast tego stosujemy prosty komunikat:

> W ramach pakietu obowiązuje rozsądny limit codziennego użycia, żeby Skippy działał szybko i stabilnie dla wszystkich.

### Pozycjonowanie

Nie sprzedajemy Skippy jako „bota do przypomnień za 19 zł”, tylko jako:

> Osobistego asystenta rodzinnego przez WhatsApp, który pamięta rytm domu i odciąża mamę z codziennej organizacji.

## 🏗️ Stack technologiczny

- **Komunikacja:** WhatsApp (Hermes + Baileys)
- **AI:** model przez API, startowo tani model flash; docelowo routing modeli zależnie od pakietu i typu zadania
- **Backend:** Hermes + n8n + PostgreSQL
- **STT:** Whisper tiny / lokalna transkrypcja głosówek
- **TTS:** Wyłączone (odpowiedź tekstem)
- **Pamięć:** agentmemory namespaced per user
- **Płatności:** Stripe (PESEL, działalność nierejestrowana na start)

---

**Autor:** Dawid Skwira  
**Wersja:** v4.1 (2026-05)  
**Status:** Dokumentacja produktowo-techniczna do wdrożenia przez Copilota/Codexa

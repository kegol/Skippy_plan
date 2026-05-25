# 🗺️ Skippy Plan — Dokumentacja Produktu

> **Pełny plan budowy i rozwoju Skippy — asystenta AI dla mam przez WhatsApp.**

To repo zawiera kompletną dokumentację produktu **Skippy** — od architektury, przez model biznesowy, po konkretne taski implementacyjne dla Copilota.

## 📄 Dokumenty

| Plik | Opis |
|------|------|
| **[📋 Plan budowy i rozwoju](docs/plan.md)** | Kompletny plan implementacji v4 — schema bazy, konfiguracja profilu, n8n pipeline, cennik |
| **[🏗️ Architektura systemu](docs/architecture.md)** | Przepływ wiadomości, rate limiting, Google OAuth, cron reminders |
| **[💰 System płatności](docs/payments.md)** | Stripe vs Autopay analiza + flow subskrypcji |
| **[🗺️ Roadmapa](plans/roadmap.md)** | Fazy rozwoju: MVP → Beta → Produkcja → Skalowanie |
| **[✅ Taski do wdrożenia](plans/tasks.md)** | Konkretne polecenia dla Copilota/Codexa |
| **[🤖 System Prompt](prompts/system-prompt.md)** | System prompt dla profilu Hermesa + konfiguracja YAML |
| **[🗄️ Schema bazy](db/schema.sql)** | PostgreSQL — users, user_usage, plans_config |
| **[🌐 Landing page](index.html)** | Prosta strona "Skippy" pod domenę skippyplan.pl |

## 🎯 Produkt

Skippy pomaga mamom zarządzać dniem przez WhatsApp:
- **Kalendarz** — Google Calendar (per-user OAuth)
- **Lista zakupów** — agentmemory (bez zewnętrznych API)
- **Notatki** — agentmemory
- **Przypomnienia** — Postgres + cron 7:00

## 💰 Cennik

| Plan | Cena/mies. | Zapytania/dzień |
|------|-----------|-----------------|
| Basic | Darmowy | 5 |
| Premium | 19 PLN | 50 |
| Family | 29 PLN | 100 |

## 🏗️ Stack technologiczny

- **Komunikacja:** WhatsApp (Hermes + Baileys)
- **AI:** DeepSeek v4 flash
- **Backend:** Hermes + n8n + PostgreSQL
- **STT:** Whisper tiny
- **TTS:** Wyłączone (odpowiedź tekstem)
- **Pamięć:** agentmemory namespaced per user
- **Płatności:** Stripe (PESEL, działalność nierejestrowana)

---

**Autor:** Dawid Skwira  
**Wersja:** v4 (2026-05)  
**Status:** Gotowe do wdrożenia przez Copilota

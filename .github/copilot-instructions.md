# Skippy_plan — GitHub Copilot Instructions

## Project Overview

**Skippy_plan** contains the complete product documentation for **Skippy** — an AI assistant for mothers that works via WhatsApp. This is a documentation-only repository: no production code, no workflows, no deployments.

**Purpose**: Serve as the single source of truth for building Skippy — architecture, pricing, implementation plan, tasks for Codex/Copilot.

## File Roles

| File | Role | Who edits |
|------|------|-----------|
| `README.md` | Entry point, table of contents | Dawid, AI |
| `docs/plan.md` | **Master plan v4** — architecture, server requirements, tasks, pricing, pitfalls | Dawid, AI |
| `docs/architecture.md` | Technical deep-dive — message flow, rate limiting, OAuth, cron | AI |
| `docs/payments.md` | Payment system analysis — Stripe vs Autopay, subscription flow | Dawid, AI |
| `plans/roadmap.md` | Development roadmap — MVP through scale, KPIs | Dawid, AI |
| `plans/tasks.md` | Concrete commands for Codex/Copilot (Dawid never touches terminal) | AI |
| `prompts/system-prompt.md` | Hermes profile config + system prompt | AI |
| `db/schema.sql` | PostgreSQL schema — `users`, `user_usage`, `plans_config` | AI |

## Editing Conventions

1. **Polish language** for all documentation content. English only for technical comments, code blocks, and this file.
2. **Markdown** with tables, code blocks, lists. Readable for both humans and AI.
3. **When updating architecture**: update BOTH `docs/plan.md` (overview) and `docs/architecture.md` (details).
4. **When updating pricing**: update `docs/plan.md`, `README.md`, and `db/schema.sql` (plans_config inserts).
5. **Preserve the ⚠️ ZANIM COKOLWIEK ZROBISZ header** in AGENTS.md — it's critical.
6. **No secrets, no tokens, no real credentials** anywhere in this repo.

## Key Technical Facts (for AI context)

- **Stack**: Hermes Agent, n8n, PostgreSQL, agentmemory
- **AI Model**: DeepSeek v4 flash
- **Channel**: WhatsApp (Baileys via Hermes)
- **Auth**: Google OAuth (offline access, scope: calendar.events)
- **Auth provider**: Stripe on PESEL (unregistered business)
- **STT**: Whisper tiny
- **TTS**: DISABLED (text-only responses)
- **Memory**: agentmemory namespaced per user (isolated sessions)
- **Rate limiting**: PostgreSQL daily quotas per plan (basic 5, premium 50, family 100)

## Tasks for This Repo

When Dawid says "update the plan" or "change the pricing":
1. Read `docs/plan.md` first
2. Check if related files need updates (`README.md`, `docs/architecture.md`, `db/schema.sql`)
3. Update all relevant files in one commit
4. Inform Dawid what changed

When Dawid says "add a feature":
1. Update `docs/plan.md` (main plan)
2. Update `docs/architecture.md` if the feature changes system design
3. Update `plans/roadmap.md` if it affects timeline
4. Update `plans/tasks.md` if it adds implementation tasks for Copilot

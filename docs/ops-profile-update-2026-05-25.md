# Podsumowanie zmian profili Hermes (2026-05-25)

Ten wpis dokumentuje zmiany wykonane operacyjnie na serwerze Hermes (`/opt/hermes-agent/data`).

## Zakres zmian

### 1) Profil `skippy`
- Ustawiono model główny na `deepseek/deepseek-v4-flash`.
- Utrzymano routing przez 9Router:
  - `model.provider: custom`
  - `model.base_url: https://9r.beautyai.pl/v1`

### 2) Profil domyślny (globalny)
- Usunięto globalne ograniczenia narzędzi (`toolsets` i `agent.disabled_toolsets`) w celu przywrócenia pełnego dostępu.
- Terminal backend pozostał aktywny (`local`).

### 3) Profil `dawid`
- Utworzono profil `dawid` jako kopię profilu domyślnego (config + env + SOUL).
- Następnie przepięto model główny na `deepseek/deepseek-v4-flash` przez 9Router:
  - `model.provider: custom`
  - `model.base_url: https://9r.beautyai.pl/v1`
- Integracja Discord pozostaje dostępna (dziedziczona z kopii domyślnej konfiguracji).

### 4) Profil `skippy_plan` (separacja i ograniczenia)
- Pozostawiono tylko platformę WhatsApp (`platforms.whatsapp`).
- Dodano ograniczenia narzędziowe przez `agent.disabled_toolsets` (m.in. terminal/file/browser/debugging/code_execution).
- Potwierdzono brak konfiguracji Discord/Telegram dla tego profilu.

## Dlaczego w 9Router było głównie zużycie `gpt-4o-mini`
- Ruch do 9Router szedł przez provider `custom`, ale część profili miała domyślny model `openai/gpt-4o-mini`.
- Po zmianach profile `skippy` i `dawid` są już ustawione na `deepseek/deepseek-v4-flash`.
- Profil `skippy_plan` nadal ma model `openai/gpt-4o-mini` (świadoma separacja funkcjonalna).

## Uwagi bezpieczeństwa
- W repo nie zapisano żadnych sekretów ani tokenów.
- Ten dokument zawiera wyłącznie podsumowanie konfiguracji i decyzji operacyjnych.

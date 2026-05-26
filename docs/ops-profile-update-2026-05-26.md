# Podsumowanie zmian profili Hermes (2026-05-26)

Ten dokument opisuje operacyjne zmiany wykonane na serwerze Hermes w profilach `skippy_plan` i `dawid`.

## Cel zmian

Ustabilizowanie działania profili po błędach modeli free i dostosowanie domyślnych modeli do aktualnych wymagań:
- `skippy_plan` na model z niskim opóźnieniem i stabilnym routingiem,
- profil domyślny użytkownika `dawid` na model klasy Sonnet.

## Zakres wykonanych zmian

### 1) Profil `skippy_plan`
- Zmieniono model główny na `ag/gemini-3-flash`.
- Zsynchronizowano model w plikach:
  - `config.yaml` (`model.default`),
  - `.env` (`CUSTOM_MODEL`, `OPENAI_MODEL`).
- Utrzymano routing przez 9Router (`provider: custom`, `base_url: https://9r.beautyai.pl/v1`).

### 2) Profil `dawid` (domyślny)
- Zmieniono model główny na `ag/claude-sonnet-4-6`.
- Zsynchronizowano model w plikach:
  - `config.yaml` (`model.default`),
  - `.env` (`OPENAI_MODEL`).
- Utrzymano routing przez 9Router (`provider: custom`, `base_url: https://9r.beautyai.pl/v1`).

### 3) Restart runtime
- Zrestartowano kontenery:
  - `hermes-skippy-plan`,
  - `hermes-agent`.

## Walidacja

Wykonano testy endpointu OpenAI-compatible (`/v1/chat/completions`) przez 9Router dla obu aliasów:
- `ag/gemini-3-flash` -> HTTP 200,
- `ag/claude-sonnet-4-6` -> HTTP 200.

## Incydenty po drodze (dla kontekstu)

- `oc/qwen3.6-plus-free` przestał działać (zakończona promocja free po stronie upstream).
- `ds/deepseek-v4-flash` zwracał błąd salda (`Insufficient Balance`) dla aktywnego klucza.
- Dla modelu `gh/gpt-5.4-mini` występował błąd pomocniczego generatora tytułów (nieobsługiwany parametr `temperature`).

Aktualna konfiguracja omija te problemy przez aliasy `ag/*`.

## Uwagi bezpieczeństwa

- W repo nie zapisano żadnych sekretów, tokenów ani haseł.
- Dokument zawiera wyłącznie opis zmian i wyników walidacji.

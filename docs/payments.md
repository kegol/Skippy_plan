# System płatności Skippy

## Decyzja: Stripe

Stripe na działalność nierejestrowaną na start, z możliwością późniejszego przejścia na działalność gospodarczą bez migracji klientów i subskrypcji.

| Kryterium | Stripe | Autopay/HotPay |
|-----------|--------|----------------|
| Aktywacja | 0 zł | 199 zł |
| Prowizja | ok. 1.4% + 0.30 PLN | ok. 1.19% + 0.25 zł |
| Subskrypcje | Wbudowane | Wymagają dodatkowego setupu |
| Trial | Wbudowany | Do weryfikacji |
| Webhook → n8n | Gotowe | Możliwe, ale bardziej manualne |
| BLIK | Dostępny | Dostępny |
| Skalowanie na firmę | Możliwa aktualizacja danych | Często wymaga nowej konfiguracji |

**Wniosek:** Stripe wygrywa prostotą, szybkością wdrożenia i mniejszym tarciem operacyjnym. Różnice prowizyjne są mniej istotne niż czas wdrożenia, niezawodność webhooków i łatwe zarządzanie subskrypcjami.

## Pakiety płatne

| Plan | Cena/mies. | Rola w produkcie |
|------|-----------:|------------------|
| Free | 0 PLN | Test produktu, podstawowe przypomnienia, krótka pamięć |
| Beta Mama | 19 PLN | Promocja dla pierwszych testerek, limitowana czasowo lub ilościowo |
| Mama | 29 PLN | Główny plan codziennej organizacji |
| Mama Plus | 49 PLN | Planowanie tygodnia, większa pamięć, proaktywne sugestie |
| Family | 79 PLN | Rodzinny organizator dla kilku osób i wspólnych zadań |

## Założenie ekonomiczne

Cena pakietów musi pokrywać:
- tokeny LLM,
- transkrypcję głosówek,
- VPS,
- n8n,
- PostgreSQL,
- monitoring i backupy,
- utrzymanie WhatsApp bridge,
- obsługę użytkowniczek,
- rozwój produktu.

Skippy nie powinien być komunikowany jako tani chatbot, tylko jako osobisty asystent rodzinny przez WhatsApp.

## Flow subskrypcji

1. Mama rejestruje się lub pisze do Skippy przez WhatsApp.
2. Onboarding zapisuje numer telefonu i imię w Postgres.
3. Jeśli potrzebny jest kalendarz, użytkowniczka otrzymuje link Google OAuth.
4. Użytkowniczka wybiera plan w Stripe Checkout.
5. Stripe webhook `checkout.session.completed` trafia do n8n.
6. n8n aktualizuje Postgres: `plan`, `stripe_customer_id`, `stripe_subscription_id`, `trial_ends_at`.
7. n8n wysyła krótką wiadomość aktywacyjną przez WhatsApp.
8. Po trialu następuje pierwsza płatność albo automatyczny downgrade do planu Free.

## Obsługa płatności

| Event Stripe | Akcja n8n |
|-------------|-----------|
| `checkout.session.completed` | Ustaw plan, zapisz customer/subscription ID, wyślij powitanie |
| `invoice.paid` | Utrzymaj aktywny plan |
| `invoice.payment_failed` | Wyślij krótkie przypomnienie i daj okres karencji |
| `customer.subscription.deleted` | Downgrade do Free |
| `customer.subscription.updated` | Zmień plan w Postgres |

## Okres karencji

Po nieudanej płatności:
1. Dzień 0: wiadomość informacyjna na WhatsApp.
2. Dzień 1–3: użytkowniczka zachowuje dostęp do aktualnego planu.
3. Po 3 dniach bez płatności: downgrade do Free.
4. Po ponownej płatności: automatyczny powrót do poprzedniego planu.

## Zmiana na firmę w przyszłości

Gdy projekt urośnie powyżej działalności nierejestrowanej:
1. Założyć firmę.
2. Zaktualizować dane podatkowe w Stripe.
3. Zachować istniejących klientów, subskrypcje i webhooki.
4. Dodać faktury oraz regulamin zgodny z modelem SaaS.

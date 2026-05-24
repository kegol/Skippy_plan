# System płatności Skippy

## Decyzja: Stripe

Stripe na działalność nierejestrowaną (PESEL jako tax ID).

| Kryterium | Stripe | Autopay/HotPay |
|-----------|--------|----------------|
| Aktywacja | 0 zł | 199 zł |
| Prowizja | 1.4% + 0.30 PLN | 1.19% + 0.25 zł |
| Subskrypcje | ✅ w panelu, 3 kliknięcia | ☎️ kontakt z handlowcem |
| Trial | ✅ wbudowany | ❌? Trzeba pytać |
| Webhook → n8n | ✅ gotowe | ✅ ale manualny setup |
| BLIK | ✅ | ✅ |
| Skalowanie na firmę | ✅ zmiana NIP | ❌ nowe konto |

**Wniosek:** Stripe wygrywa prostotą i brakiem tarcia. Różnica kosztów (~151 zł/rok przy 50 mamach × 19 PLN) jest pomijalna wobec oszczędności czasu na setupie.

## Flow subskrypcji

1. Mama rejestruje się → Google OAuth → podaje telefon
2. Stripe Checkout → wybiera plan (Premium 19 PLN / Family 29 PLN)
3. Stripe webhook `checkout.session.completed` → n8n
4. n8n aktualizuje Postgres: `plan = 'premium'`, `stripe_customer_id`, `stripe_subscription_id`
5. n8n wysyła WhatsApp: "Konto Skippy aktywowane! 🎉"
6. Po 7 dniach trial → pierwsza płatność lub downgrade do basic

## Obsługa płatności

| Event Stripe | Akcja n8n |
|-------------|-----------|
| `checkout.session.completed` | Ustaw plan, wyślij powitanie |
| `invoice.paid` | Przedłuż dostęp (domyślnie) |
| `invoice.payment_failed` | Wyślij przypomnienie WhatsApp, 3 dni → downgrade |
| `customer.subscription.deleted` | Downgrade do basic |
| `customer.subscription.updated` | Zmień plan w Postgres |

## Zmiana na firmę (przyszłość)

Gdy urośniesz powyżej działalności nierejestrowanej:
1. Załóż firmę → zaktualizuj dane w Stripe (NIP, konto bankowe)
2. **Bez migracji** — Stripe pozwala zmienić tax ID i dane konta
3. Wszystkie subskrypcje, klienci, webhooki zostają bez zmian

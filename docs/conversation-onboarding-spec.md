# Specyfikacja logiki bota na starcie rozmowy (audytowalna)

## Cel dokumentu

Ten dokument opisuje dokładnie i jednoznacznie logikę pierwszych wiadomości Skippy na WhatsApp.
Zakres obejmuje wyłącznie etap identyfikacji użytkowniczki i decyzję, czy trzeba uruchomić Google OAuth.

Cel operacyjny:
- najpierw rozpoznać osobę,
- jeśli nie rozpoznano: poprosić o imię,
- po rozpoznaniu: sprawdzić autoryzację Google,
- jeśli brak autoryzacji: zwrócić poprawny link OAuth,
- komunikaty do użytkowniczki mają być krótkie i zadaniowe.

## Komponenty runtime

- Skrypt główny: /opt/data/profiles/skippy_plan/bin/first_message_onboarding.py
- Wrapper shell: /opt/data/profiles/skippy_plan/bin/first_message_onboarding.sh
- Generator linku OAuth: /opt/data/profiles/skippy_plan/bin/google_auth_link.sh
- Baza: PostgreSQL, baza skippy, schema skippy
- Tabele: skippy.whatsapp_users, skippy.google_oauth_tokens

## Dane wejściowe

- phone: numer z metadanych WhatsApp (wymagany)
- message: treść wiadomości użytkowniczki (opcjonalna)
- name: imię przekazane explicite z workflow (opcjonalne)

## Normalizacja numeru telefonu

Wymagany format końcowy: E.164, prefiks +.

Reguły:
1. Usuń znaki nienumeryczne.
2. Jeśli numer ma 9 cyfr (PL lokalny), dodaj prefiks kraju 48.
3. Jeśli numer ma 10 cyfr i zaczyna się od 0, zamień na 48 + 9 ostatnich cyfr.
4. Zwróć numer jako +<cyfry>.
5. Jeśli po normalizacji brak cyfr: błąd wejścia.

Przykłady:
- 783776529 -> +48783776529
- 0783776529 -> +48783776529
- +48 783 776 529 -> +48783776529

## Ekstrakcja imienia z treści

Logika działa dwuetapowo:

1. Wzorce zdań:
- mam na imie <tekst>
- nazywam sie <tekst>
- jestem <tekst>

2. Krótka odpowiedź jako kandydat imienia:
- tylko litery i spacje, 2-40 znaków,
- maksymalnie 2 słowa,
- odrzucane typowe stopwordy (np. hej, czesc, ok, tak, nie).

Źródło imienia (priorytet):
1. name z wejścia workflow,
2. wynik ekstrakcji ze wzorca zdania,
3. krótki kandydat z wiadomości.

## Model stanów i decyzji

Tabela decyzji:

1. Numer niepoprawny
- Warunek: phone po normalizacji jest puste
- Wynik: status ERROR
- Działanie: zakończ bez zmian w DB

2. Numer istnieje, brak imienia w DB, brak imienia w wejściu
- Warunek: rekord istnieje, full_name puste, final_name puste
- Wynik: status NEED_NAME
- Działanie: aktualizacja last_seen_at

3. Numer istnieje, brak imienia w DB, imię wykryte
- Warunek: rekord istnieje, full_name puste, final_name niepuste
- Wynik: status UPDATED_NAME
- Działanie: zapis full_name, onboarding_status=active, last_seen_at
- Dalszy krok: sprawdź token Google

4. Numer istnieje, imię już zapisane
- Warunek: rekord istnieje, full_name niepuste
- Wynik: status FOUND
- Działanie: aktualizacja last_seen_at
- Dalszy krok: sprawdź token Google

5. Numer nowy, imię wykryte
- Warunek: rekord nie istnieje, final_name niepuste
- Wynik: status CREATED
- Działanie: insert phone + full_name + onboarding_status=active
- Dalszy krok: sprawdź token Google

6. Numer nowy, brak imienia
- Warunek: rekord nie istnieje, final_name puste
- Wynik: status NEED_NAME
- Działanie: insert phone + onboarding_status=pending

## Sprawdzenie autoryzacji Google

Źródło prawdy:
- tabela skippy.google_oauth_tokens
- klucz logiczny: phone

Reguła:
- jeśli istnieje rekord tokenu dla phone -> needs_google_auth=false
- jeśli brak rekordu tokenu -> needs_google_auth=true

## Budowa linku OAuth

Link tworzony tylko gdy needs_google_auth=true.

Parametry:
- endpoint: https://accounts.google.com/o/oauth2/v2/auth
- client_id: GOOGLE_CLIENT_ID lub wartość z google_client_secret.json
- redirect_uri: GOOGLE_REDIRECT_URI lub domyślnie callback n8n
- response_type: code
- scope: calendar.events + userinfo.email + userinfo.profile + openid
- access_type: offline
- prompt: consent
- state: base64url(JSON)

state JSON:
- phone: numer po normalizacji E.164
- name: imię użytkowniczki (lub Uzytkowniczka)
- email: techniczny alias <digits>@skippy.local

Wymaganie jakości:
- state zawsze musi zawierać numer po normalizacji, nigdy surową wartość wejściową.

## Kontrakt odpowiedzi JSON (wyjście do n8n)

Pola obowiązkowe:
- status
- phone
- ts
- needs_name
- needs_google_auth
- reply_text

Pola warunkowe:
- name (gdy znane)
- auth_url (gdy needs_google_auth=true)
- message (gdy status ERROR)

Znaczenie pól sterujących:
- needs_name=true: n8n kończy flow onboardingiem i wysyła reply_text
- needs_google_auth=true: n8n wysyła reply_text + auth_url i kończy flow
- needs_name=false i needs_google_auth=false: n8n przekazuje wiadomość do głównej logiki asystentki

## Zasady treści komunikatów

Wymagania:
- krótko,
- bez opisu procesu wewnętrznego,
- bez pytań o numer telefonu,
- jasny kolejny krok.

Dozwolony styl:
- Czesc! Jak masz na imie?
- Zaloguj Google, zeby ruszyc dalej.
- Super, Judyta. Mozemy dzialac.

Niedozwolony styl:
- Zapisuje Cie i przeprowadzam przez proces autoryzacji.
- Teraz poprosze o Twoj numer telefonu.

## Integracja z n8n (deterministyczna)

Sekwencja decyzji w workflow:
1. Wywołaj first_message_onboarding.sh.
2. Odczytaj JSON.
3. Gdy status=ERROR: log + fallback komunikat techniczny.
4. Gdy needs_name=true: wyślij reply_text i STOP.
5. Gdy needs_google_auth=true: wyślij reply_text, nowa linia, auth_url i STOP.
6. W przeciwnym razie: przejście do normalnego flow zadań.

Wymóg audytowy:
- dla każdej gałęzi loguj status, phone, needs_name, needs_google_auth i decyzję workflow.

## Macierz testów akceptacyjnych

1. Nowy numer, wiadomość Hej
- Oczekiwane: NEED_NAME, needs_name=true, brak auth_url

2. Ten sam numer, wiadomość Judyta
- Oczekiwane: UPDATED_NAME, needs_name=false, name=Judyta

3. Numer z tokenem Google
- Oczekiwane: needs_google_auth=false, brak auth_url

4. Numer bez tokenu Google
- Oczekiwane: needs_google_auth=true, auth_url niepuste

5. Numer 9-cyfrowy bez +48
- Oczekiwane: phone po normalizacji +48...

6. Numer z formatowaniem +48 783 776 529
- Oczekiwane: phone po normalizacji +48783776529

7. Wiadomość: mam na imie Anna Kowalska
- Oczekiwane: name=Anna Kowalska

8. Wiadomość: czesc
- Oczekiwane: brak fałszywego wykrycia imienia

9. Błąd połączenia DB
- Oczekiwane: status ERROR, message z opisem błędu

10. Użytkowniczka już znana, zwykła wiadomość zadaniowa
- Oczekiwane: FOUND + routing do głównego flow, jeśli auth gotowe

## Kryteria gotowości pod analizę

Warunki, które muszą być spełnione, aby uznać logikę za analitycznie domkniętą:
- Jednoznaczny kontrakt wejście/wyjście.
- Brak nieokreślonych gałęzi decyzyjnych.
- Każda gałąź ma oczekiwany efekt w DB i w komunikacie.
- Numer telefonu zawsze normalizowany przed DB i OAuth.
- Jedna, jawna reguła przejścia z onboardingu do normalnego flow.
- Pełna macierz testowa z oczekiwanym wynikiem.

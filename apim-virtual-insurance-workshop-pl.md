# Warsztat: Wirtualny Doradca Ubezpieczeniowy z Obsługą Wielokanałową

Celem warsztatu jest stworzenie interfejsu API do integracji z chatbotem generatywnym, który może odpowiadać na pytania klientów dotyczące polis ubezpieczeniowych, przetwarzając dane w czasie rzeczywistym i korzystając z Azure API Management do zarządzania, monitorowania i zabezpieczania API.

## Wymagania dla uczestników

Przed przystąpieniem do warsztatu, upewnij się że posiadasz:

- Aktywną subskrypcję Azure (lub darmowe środki)
- Wdrożoną usługę Microsoft Foundry z dostępnym modelem np. "gpt-4o-mini"
https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/create-resource?pivots=web-portal
- Wdrożoną usługe "Azure Log Analytics"
https://learn.microsoft.com/en-us/azure/api-management/monitor-api-management
- Wdrożoną usługe "Application Insight"
https://learn.microsoft.com/en-us/azure/api-management/api-management-howto-app-insights?tabs=rest
- Zainstalowane narzędzia:
    - Azure CLI (wersja 2.40.0 lub wyższa)
    - Visual Studio Code lub inne IDE
    - Postman lub inny klient REST (opcjonalnie)
- Podstawową znajomość REST API: żądania HTTP, nagłówki, kody odpowiedzi

---

## 1. TWORZENIE PIERWSZEGO API (BAZA WIEDZY O POLISACH)

### 1.1 Przygotowanie środowiska

1. Zaloguj się do Azure Portal (portal.azure.com)  
2. Sprawdź czy posiadasz aktywną subskrypcję

### 1.2 Tworzenie usługi Azure API Management

https://learn.microsoft.com/en-us/azure/api-management/get-started-create-service-instance

1. W Azure Portal, wyszukaj "API Management" w pasku wyszukiwania  
2. Kliknij "+ Create" lub "Utwórz"  
3. Wypełnij formularz:
    - **Subscription**: wybierz swoją subskrypcję
    - **Resource Group**: utwórz nową (np. "rg-workshop-apim")
    - **Region**: wybierz najbliższy (np. France Central)
    - **Name**: np. "workshop-apim"
    - **Organization name**: nazwa Twojej organizacji
    - **Administrator email**: Twój adres email
    - **Pricing tier**: Developer (najtańsza, nieprodukcyjna opcja)
4. W zakładce "Monitor + Secure", zaznacz opcje "Log Analytics" oraz "Application Insights", wybierz wcześniej utworzone zasoby.
5. W zakładce "Virtual Network", zaznacz opcję "Virtual Network" a następnie z "Type" wybierz "External" poprzez opcję "Create new" utwórz nową sieć wirtualną, wprowadź nazwę i możesz zaakceptować domyślną adresację. 
6. W zakładce "Managed identity" w polu "Status" zaznacz "checkbox"
7. Kliknij "Review + create", a następnie "Create"
8. Poczekaj na zakończenie wdrażania (może potrwać 30-40 minut)

### 1.3 Definiowanie modelu danych dla polis

https://learn.microsoft.com/en-us/azure/api-management/add-api-manually

Dla naszego API będziemy używać następującego modelu danych polisy:

- ID (unikalny identyfikator)
- Rodzaj polisy (np. zdrowotna, samochodowa, mieszkaniowa)
- Dostępne pakiety (np. premium, standard)
- Cena (miesięczna)
- Opis (co polisa obejmuje)

### 1.4 Tworzenie API dla bazy wiedzy o polisach

1. Przejdź do utworzonego zasobu API Management
2. W menu bocznym wybierz "APIs", następnie jeszcze raz APIs.
3. Kliknij "+ Add API" i wybierz "HTTP API"
4. Wypełnij formularz:
    - **Display name**: PolisyAPI
    - **Name**: polisyapi
    - **Web service URL**: można tymczasowo wpisać "https://example.org"
    - **API URL suffix**: polisy
5. Kliknij "Create"

### 1.5 Dodawanie operacji GET /polisy

1. Wybierz utworzone API "PolisyAPI"
2. Kliknij "+ Add operation"
3. Wypełnij formularz:
    - **Display name**: GetPolisy
    - **Name**: getpolisy
    - **URL**: GET /polisy
    - **Description**: Pobiera listę dostępnych polis
4. W sekcji "Responses" kliknij "+ Add response"
    - **Status code**: 200 OK
    - W "Representations" kliknij "Add representation" wybierz "application/json"
    - Wklej przykładowy schemat:

```json
[
  {
    "polisaId": "123456",
    "rodzajPolisy": "zdrowotna",
    "pakiet": "premium",
    "cena": 100,
    "opis": "Ubezpieczenie zdrowotne premium."
  },
  {
    "polisaId": "123457",
    "rodzajPolisy": "samochodowa",
    "pakiet": "standard",
    "cena": 75,
    "opis": "Podstawowe ubezpieczenie samochodu."
  }
]
```

5. Kliknij "Save"
6. Przejdź do zakładki "Settings" W sekcji "Subscription" odznacz opcję "Subscription required" (dla celów testowych)
7. Kliknij "Save"
8. Wybierz Design i przejdź do "Inbound processing"
9. Kliknij "Add policy", wybierz "mock-response"
10. Kliknij "Save"

### 1.6 Testowanie API

https://learn.microsoft.com/en-us/azure/api-management/api-management-howto-api-inspector

1. Wybierz utworzone API i przejdź do zakładki "Test"
2. Wybierz operację GET /polisy
3. Kliknij "Send"
4. Sprawdź czy otrzymujesz odpowiedź z przykładowymi danymi polis

---

## 2. UDOSTĘPNIENIE OPEN AI POPRZEZ APIM

https://learn.microsoft.com/en-us/azure/api-management/azure-ai-foundry-api
https://learn.microsoft.com/en-us/azure/api-management/azure-openai-api-from-specification

### 2.1 Dodawanie API Azure OpenAI

1. W zasobie API Management przejdź do sekcji "APIs"
2. Kliknij "+ Add API" i wybierz "Azure AI Foundry"
3. W Zakładce "Select AI Service" wybierz usługę Microsoft Foundry 
4. Kliknij "Next"
3. Wypełnij formularz:
    - **Display name**: polisy-ai
    - **name**: polisy-ai
    - Podaj dowolny opis
    - Zaznacz opcję "Azure OpenAI"
4. Kliknij "Next"
5. Zaznacz opcję "Track token usage" (potrzebne do rozliczalności) - zaposnaj się z linkami https://learn.microsoft.com/en-us/azure/api-management/azure-openai-emit-token-metric-policy oraz https://learn.microsoft.com/en-us/azure/api-management/azure-openai-token-limit-policy

6. Wybierz dostępną instancję Application Insights jako miejsce do odkładania metryk tokenów
7. W opcji "dimension" wybierz: API ID, Subscription ID, Operation ID
8. Kliknij "Next" - zapoznaj się z opcją "Semantic caching"
https://learn.microsoft.com/en-us/azure/api-management/azure-openai-enable-semantic-caching
9. Kliknij "Next" - zapoznaj się z opcją "AI content safety"
https://learn.microsoft.com/en-us/azure/api-management/llm-content-safety-policy
10. Kliknij "Next"
11. kliknij "Create"

Samo skonfigurowanie "Track token usage" nie wystraczy aby metryki pojawiły się w "Application Insight" nalezy jeszcze wykonać konfiguracje z linka poniżej https://learn.microsoft.com/en-us/azure/api-management/api-management-howto-app-insights?tabs=rest takie jak "Create a connection between Application Insights and API Management", "Enable Application Insights logging for your API" jak również uruchomienie "Emit custom metrics". Dla ułatwienia ustawienie opcji "metrics" możesz zrobić poprzez cloudshell https://shell.azure.com

```
az rest --method put \
  --url "https://management.azure.com/subscriptions/{SubscriptionId}/resourceGroups/{ResourceGroupName}/providers/Microsoft.ApiManagement/service/{APIManagementServiceName}/diagnostics/applicationinsights?api-version=2025-03-01-preview" \
  --body '{
    "properties": {
      "loggerId": "/subscriptions/{SubscriptionId}/resourceGroups/{ResourceGroupName}/providers/Microsoft.ApiManagement/service/{APIManagementServiceName}/loggers/{ApplicationInsightsLoggerName}",
      "metrics": true
    }
  }'
```

Metryki możesz zobaczyć w "Log Analytics" wpisując w "Search" zapytanie "customMetrics".

### 2.2 Testowanie dostępności OpenAI API

1. Po utworzeniu API, wybierz je z listy
2. Wybierz operacje "Creates a completion for the chat message"
3. Przejdź do zakładki "Test"
4. Dla deploymentu wpisz "gpt-4o-mini" (lub inny dostępny)
5. Dla api-version wpisz "2024-05-01-preview"
6. W body umieść poniższy JSON:

```json
{
  "messages": [
    {
      "role": "system",
      "content": "Say Hello World"
    }
  ]
}
```

7. Kliknij "Send" i sprawdź odpowiedź
8. Tym razem nie wyłączylismy w zakładce "Settings" opcji "Subscription required", a jednak udało się nam wysłać zapytanie. Dzieje się to dlatego że portal automatycznie podkłada klucz, możesz to sprawdzić poprzez wysłanie zapytania przyciskiem "Trace".
### 2.3 Weryfikacja ustawień subskrypcji dla API polisy-ai

1. Przejdź do "APIs" i wybierz "polisy-ai"
2. Przejdź do zakładki "Settings"
3. W sekcji "Subscription" upewnij się że jest zaznaczona opcję "Subscription required"
4. Upewnij się że w "Header name" wartość to "Ocp-Apim-Subscription-Key" a w "Query parameter name" widnieje wartość "subscription-key"
5. Kliknij "Save"

### 2.4 Dodawanie uwierzytelniania Managed Identity do Microsoft Foundry

https://learn.microsoft.com/en-us/azure/api-management/api-management-howto-use-managed-service-identity

Sprawdź czy został włączony dla "API Management" "system managed identity" i czy zostało nadane uprawnienie dla tej tożsamości do "Microsoft Foundry". "Managed Identity" powinno zostać utworzone podczas tworzenia API Managemnt, rola powinna zostać nadana podczas dodawania API "polisy-ai".

1. Przejdź do swojego API Management
2. W menu bocznym wybierz "Managed identities"
3. Włącz opcję "System assigned" i kliknij "Save"
4. Przejdź do zasobu Microsoft Foundry
5. Wybierz "Access control (IAM)"
6. Kliknij "+ Add" i wybierz "Add role assignment"
7. Wybierz rolę "Cognitive Services OpenAI User"
8. W zakładce "Members" wybierz "Managed identity" i wskaż swój APIM
9. Kliknij "Review + assign"

---

## 3. KLUCZE

### 3.1 Konfiguracja kluczy API w Azure API Management

https://learn.microsoft.com/en-us/azure/api-management/api-management-subscriptions

1. W zasobie API Management przejdź do sekcji "Subscriptions"
2. Stwórz nową subskrypcję klikając "+ Add":
    - **Name**: WorkshopSubscription
    - **Display name**: WorkshopSubscription
    - **Scope**: All APIs (lub konkretne API)
3. Po utworzeniu, kliknij na subskrypcję i skopiuj wygenerowany klucz

### 3.2 Włączanie wymogu klucza subskrypcji dla API

1. Przejdź do "APIs" i wybierz "PolisyAPI"
2. Przejdź do zakładki "Settings"
3. W sekcji "Subscription" zaznacz opcję "Subscription required"
4. Upewnij się że w "Header name" wartość to "Ocp-Apim-Subscription-Key" a w "Query parameter name" widnieje wartość "subscription-key"
5. Kliknij "Save"

### 3.3 Testowanie API z kluczem

1. Przejdź do zakładki "Test"
2. Wybierz operację GET /polisy
3. Kliknij "Send" i zweryfikuj, że otrzymujesz prawidłową odpowiedź
4. Sprawdź jak wygląda pełny request (ikonka oka po prawej stronie w sekcji HTTP request). Narzędzie do testowania samo dodaje header "Ocp-Apim-Subscription-Key". Jeśli będziesz korzystał z innych narzędzi pamiętaj o dodaniu header "Ocp-Apim-Subscription-Key" wraz z prawidłowym kluczem.

---

## 4. RATE LIMITS

### 4.1 Konfiguracja Rate Limiting

https://learn.microsoft.com/en-us/azure/api-management/rate-limit-policy

1. Przejdź do "APIs" i wybierz "PolisyAPI"
2. Wybierz zakładkę "Designs", pozostań w "All operations", przejdź do sekcji "Inbound processing", kliknij w </>.
3. W edytorze XML, w sekcji `<inbound>` dodaj za znacznikiem `<base />`:

```xml
<rate-limit calls="5" renewal-period="30" />
```

4. Kliknij "Save"

Ta polityka ogranicza liczbę wywołań do 5 na 30 sekund.

### 4.2 Testowanie ograniczenia liczby wywołań

1. Przejdź do zakładki "Test"
2. Wybierz operację GET /polisy
3. Kliknij "Send" co najmniej 6 razy w ciągu 30 sekund
4. Zauważ, że po 5 wywołaniach otrzymujesz błąd 429 Too Many Requests

### 4.3 Usuwanie Rate Limiting

1. Wróć do zakładki "Policies"
2. W edytorze XML usuń linię

```xml
<rate-limit calls="5" renewal-period="30" />
```

3. Kliknij "Save"

---

## 5. OAUTH 2.0

### 5.1 Rejestracja aplikacji w Microsoft Entra ID

**W przypadku braku możliwości rejestracji aplikacji w Microsoft Entra ID (SPN), informacje dotyczące wymaganych danych dostępowych, takich jak clientId, tenantId oraz secret, zostaną Ci dostarczone.**

https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-register-app

1. W Azure Portal przejdź do "Microsoft Entra ID"
2. Wybierz "App registrations" i kliknij "+ New registration"
3. Wypełnij formularz:
    - **Name**: PolisyAPI-OAuth-username (wprowadź nazwę swojego użytkownika)
    - **Supported account types**: wybierz "Accounts in this organizational directory only"
4. Kliknij "Register"
5. Zanotuj wartości "Application (client) ID" oraz "Directory (tenant) ID"
6. Przejdź do "Mange" następnie "Certificates & secrets" 
7. Wygeneruj secret i zapisz klucz (pamiętaj o zapisaniu klucza po wygenerowaniu – będzie tylko widoczny przez chwilę). W polu "Description" wpisz dowolną wartość, w polu "Expires" wybierz "90 days"

### 5.2 Implementacja polityki uwierzytelniania Azure AD

https://learn.microsoft.com/en-us/azure/api-management/validate-azure-ad-token-policy

1. Przejdź do "Policies" dla "PolisyAPI"
2. W edytorze XML dodaj w sekcji `<inbound>` po `<base />`:

```xml
        <validate-azure-ad-token tenant-id="xxxx">
            <client-application-ids>
                <application-id>xxxx</application-id>
            </client-application-ids>
        </validate-azure-ad-token>
```

3. Zastąp "xxxxxxxxxxx" swoim Tenant ID oraz "xxxxxxxxxx" swoim Client ID
4. Kliknij "Save"

### 5.3 Utwórz prostą Azure LogicApp która pomoże ci przetestować uwierzytelnianie.

https://learn.microsoft.com/en-us/azure/logic-apps/quickstart-create-example-consumption-workflow

1. Na głównej stronie https://portal.azure.com, wybierz opcję "Create a resource".
2. Wyszukaj "Logic App", kliknij "Create"
3. Wybierz "Multi-tenant"
4. Wybierz "Select"
5. Wybierz "Subscription" na której wdrożyłeś API Management
6. Wybierz "Resource Group" na której wdrożyłeś API Management
7. W polu "Logic App name" wpisz "la-test01"
8. W polu "Region" wybierz ten sam region w którym wdrożyłeś API Management.
9. Kliknij "Review + Create" a następnie "Create".
10. Po utworzeniu zasobu kliknij "Go to resource".
11. Kliknij "Edit"
12. Kliknij "Add a trigger", wybierz "Request", następnie "When a HTTP request is received", kliknij "Save".
13. Kliknij znaczek + który znajduje się poniżej kafelka "When a HTTP request is received", wybierz "Add an action"
14. Wyszukaj "Azure API Management" - wybierz "Choose an Azure API Management action", zaznacz swoją instancję Azure API Management.
15. Wybierz "PolisyAPI", kliknij "Add action".
16. W polu "Operation Id" wybierz "GetPolisy".
17. W polu "Advanced parameters" zaznacz zarówno "Authentication" jak i "Subscription key".
18. W polu "Authentication" wybierz Active Directory OAuth a następnie wypełnij wszystkie wymagane pola takie jak "Tenant", "Audience", "Client ID" oraz "Secret", w polu "Audience" wpisz "https://management.azure.com/".
19. W polu "Subscription key" wpisz klucz który wygenerowałeś w punkcie "3.1", kliknij "Save".
20. Kliknij "Run" następnie "Run".
21. Przejdź na "Overview" i sprawdź w zakładce "Run History" wynik wysłania zapytania do "API" wystawionego przez "Azure API Management".
22. Możesz poeksperymentować i pozmieniać wartości np. zmienić klucz na błędny aby sprawdzić że uwierzytelnianie działa. Błędy możesz sprawdzić w "History".

---

## 6. OPEN AI TOKEN LIMIT

### 6.1 Skonfiguruj "Azure Logic App" aby umożliwiało wykorzystanie "Managed Identity" do łączenia się z innymi usługami takimi jak np. "Azure API Management".

**W przypadku braku uprawnień do Microsoft Entra ID użyj polecenia Azure CLI, aby wyświetlić identyfikator aplikacji (Application ID). Możesz to zrobić poprzez Azure Cloud Shell.**

```bash
az ad sp show --id '[Object (principal) ID]' | ConvertFrom-Json | select displayName, appId
```

1. Przejdź do "Azure Logic App" o nazwie "la-test01".
2. Przejdź do zakładki "Identity", kliknij "System assigned", wybierz "ON" a następnie "Save".
3. W EntraID znajdź "Application ID", który dotyczy "Managed Identity" utworzonego dla "Azure Logic App". Przejdź do "Entra ID" następnie "Enterprise applications", w "Application type" wybierz "Managed Identity", wyszukaj nazwę "la-test01". Zanotuj "Application ID".

### 6.1 Dodawanie polityki limitu tokenów OpenAI

https://learn.microsoft.com/en-us/azure/api-management/azure-openai-token-limit-policy

1. Znajdż "Azure API Managment" w portalu azure, następnie przejdź do "APIs" i wybierz API dla OpenAI o nazwie "polisy-ai"
2. Przejdź do sekcji "Inbound processing" a następnie "Policies", kliknij w oznaczenie </>
3. W edytorze XML dodaj w sekcji `<inbound>` po `<base />`:

```xml
<azure-openai-token-limit counter-key="@(context.Subscription.Id)" tokens-per-minute="10000" estimate-prompt-tokens="true" />
```

4. Dodaj również politykę uwierzytelniania Managed Identity do Azure OpenAI:

https://learn.microsoft.com/en-us/azure/api-management/authentication-managed-identity-policy

```xml
<authentication-managed-identity resource="https://cognitiveservices.azure.com" output-token-variable-name="managed-id-access-token" ignore-error="false" />
<set-header name="Authorization" exists-action="override">
  <value>@("Bearer " + (string)context.Variables["managed-id-access-token"])</value>
</set-header>
```

5. Sprawdź czy jest ustawiony backend OpenAI:

Backend-id musi mieć tą samą nazwę co "Backend name" w zakłade "Backends".

```xml
<set-backend-service id="apim-generated-policy" backend-id="polisy-ai-openai-endpoint" />
```

6. Kliknij "Save"

https://learn.microsoft.com/en-us/azure/api-management/validate-azure-ad-token-policy

8. Zmień politykę "validate-azure-ad-token tenant-id" w celu uwierzytelniania komunikacji tylko z określonego Managed Identity w tym przypadku podłączonego pod Azure Logic App, podaj "application-id" z punktu 6.1.3.

```xml
    <validate-azure-ad-token tenant-id="xxxxxxxxxxx">
      <client-application-ids>
        <application-id>xxxxxxxxxx</application-id>
      </client-application-ids>
    </validate-azure-ad-token>
```

Pełna polityka powinna wyglądać następująco:

```xml
<policies>
  <inbound>
    <base />
    <validate-azure-ad-token tenant-id="xxxxxxxxxxx">
      <client-application-ids>
        <application-id>xxxxxxxxxx</application-id>
      </client-application-ids>
    </validate-azure-ad-token>
    <azure-openai-token-limit counter-key="@(context.Subscription.Id)" tokens-per-minute="10000" estimate-prompt-tokens="true" />
    <set-backend-service id="apim-generated-policy" backend-id="polisy-ai-openai-endpoint" />
    <authentication-managed-identity resource="https://cognitiveservices.azure.com" output-token-variable-name="managed-id-access-token" ignore-error="false" />
    <set-header name="Authorization" exists-action="override">
      <value>@("Bearer " + (string)context.Variables["managed-id-access-token"])</value>
    </set-header>
  </inbound>
  <backend>
    <base />
  </backend>
  <outbound>
    <base />
  </outbound>
  <on-error>
    <base />
  </on-error>
</policies>
````

### 6.2 Dodanie do już istniejącego Azure Logic App kolejnego konektora który umożliwi komunikację z Azure Open AI.

1. Przejdź do Azure Logic App następnie kliknij "Edit".
2. Kliknij na pierwszy element "When a HTTP request is received" w polu "Request Body JSON Schema" wklej poniższy kod

```
{
    "type": "object",
    "properties": {
        "prompt": {
            "type": "string"
        }
    }
}
```

3. Dodaj na sam koniec przepływu (poprzez znaczek +), akcję o nazwie "API Management", wypełnij formularz, wybierz swoje API Management a następnie wybierz polisy-ai API, kliknij "Add action".
4. W polu "Operation Id" wybierz "Creates a completion for the chat message".
5. W polu "Deployment-ID" wpisz "gpt-4o-mini" lub inny model który jest dostępny w Azure Open AI.
6. W polu "api-version" wpisz "2024-05-01-preview".
7. W polu "Body" wpisz

```
{
  "messages": [
    {
      "role": "system",
      "content": "@{outputs('polisyapi')}"
    },
    {
      "role": "user", 
      "content": "@{triggerBody()?['prompt']}"
    }
  ]
}
```

8. W polu "Advanced parameters" zaznacz "Authentication" oraz "Subscription key". W części "Authentication Types" wybierz "Managed identity" w części "Managed identity" wybierz "System-assigned managed identity", następnie w polu Audience wpisz https://management.azure.com/. W polu "Subscription key" wpisz klucz który wygenerowałeś w punkcie "3.1".
9. Zmień ustawienia pierwszej akcji o nazwie "polisyapi", aby wykorzystywała "System-assigned managed identity".
10. Sprawdź działanie Azure Logic App, wybierz przycisk "Run" a następnie "Run with payload". W sekcji "Body" wprowadź poniższy kod

```
{
    "prompt": "Proszę podać id oraz ceny dotyczące polis ubezpieczeniowych. Napisz którą polise lepiej wybrać?"
}
```

https://learn.microsoft.com/en-us/azure/logic-apps/monitor-logic-apps-overview

10. Poczekaj kilka sekund na odpowiedź z Azure Open AI i kliknij na "View monitoring view", sprawdź jak wyglądał przepływ zdarzeń w Azure Logic App. Przejdź do klocka o nazwie "polisy-ai" i w sekcji "Outputs" znajdź "Body", sprawdź odpowiedź od modelu.

---

## 7. TRANSFORMACJA/ANONIMIZACJA

### 7.1 Stosowanie polityk transformacji

https://learn.microsoft.com/en-us/azure/api-management/json-to-xml-policy

1. Przejdź do "APIs" i wybierz "polisy-ai"
2. Przejdź do "Policies"
3. W edytorze XML, w sekcji `<outbound>` po znaczniku `<base />` dodaj politykę konwersji JSON do XML:

```
        <json-to-xml apply="always" consider-accept-header="false" parse-date="false" />
```

### 7.2 Dodawanie polityki anonimizacji danych

https://learn.microsoft.com/en-us/azure/api-management/find-and-replace-policy

1. Pozostając w edytorze polityk, dodaj w sekcji `<outbound>` po polityce transformacji:

```
        <find-and-replace from="123456" to="xxxxxx" />
```

2. Kliknij "Save"

### 7.3 Testowanie transformacji i anonimizacji v1

1. Uruchom Azure Logic App tak jak w części 6.2.10 i sprawdź że obecnie "Body" na "Outputs" jest w postaci xml, oraz że id polisy zostało zastąpione z 123456 na xxxxxx.

---

### 7.4 Zmiana find-and-replace na RegularExpressions

1. W edytorze polityk zmień 

```
        <find-and-replace from="123" to="xxx" />
```

na

https://learn.microsoft.com/en-us/azure/api-management/api-management-policy-expressions

```
        <set-body>@{
        string body = context.Response.Body.As<string>(preserveContent: true);
        body = System.Text.RegularExpressions.Regex.Replace(body,  @"\b\d{6}\b", "xxxxxx");
        return body;}
        </set-body>
```
2. Kliknij "Save"
3. Zaakceptuj komunikat "Warning".

### 7.5 Testowanie transformacji i anonimizacji v2

1. Uruchom Azure Logic App tak jak w części 6.2.10 i sprawdź że obecnie "Body" na "Outputs" jest w postaci xml, oraz że wszystkie id polisy zostały zastąpione z 123456 oraz 123457 na xxxxxx.

## 8. MONITOROWANIE I DIAGNOSTYKA W APIM

### 8.1 Konfiguracja Application Insights

https://learn.microsoft.com/en-us/azure/api-management/api-management-howto-app-insights?tabs=rest

1. Jeśli nie masz jeszcze zasobu Application Insights, utwórz go:
    - Wyszukaj "Application Insights" w Azure Portal
    - Kliknij "+ Create"
    - Wypełnij formularz i utwórz zasób
2. Przejdź do zasobu API Management
3. W menu bocznym wyszukaj "Application Insights" dodaj wcześniej utworzony zasób Application Insights.
4. Następnie w menu bocznym wybierz "APIs" następnie "All APIs"
5. Kliknij "Settings" i kliknij "Enable" dla "Application Insight"
6. W polu "Destination" wybierz wcześniej utworzony "Application Insight"
7. W polu "Verbosity" zaznacz "Verbose"
8. Kliknij "Save"

### 8.2 Konfiguracja logowania i śledzenia

https://learn.microsoft.com/en-us/azure/api-management/trace-policy

1. Przejdź do "APIs" i wybierz "polisy-ai"
2. Wybierz zakładkę "Policies"
3. W edytorze XML dodaj w sekcji `<inbound>` przed `<base />`:

```xml
        <!--Use consumer correlation id or generate new one-->
        <set-variable name="correlation-id" value="@(context.Request.Headers.GetValueOrDefault("x-ms-client-tracking-id", Guid.NewGuid().ToString()))" />
        <!--Set header for end-to-end correlation-->
        <set-header name="x-correlation-id" exists-action="override">
            <value>@((string)context.Variables["correlation-id"])</value>
        </set-header>
        <trace source="API Management Trace">
            <message>@{
    return "Rozpoczęcie przetwarzania żądania " + context.Request.Method + " " + context.Request.Url.Path;
  }</message>
            <metadata name="User-Agent" value="@(context.Request.Headers.GetValueOrDefault("User-Agent", ""))" />
            <metadata name="Subscription-Id" value="@(context.Subscription?.Id ?? "anonymous")" />
            <metadata name="correlation-id" value="@((string)context.Variables["correlation-id"])" />
        </trace>
```

4. W sekcji `<outbound>` po `<base />` dodaj:

```xml
        <trace source="API Management Trace">
            <message>@{
    return "Zakończenie przetwarzania, status: " + context.Response.StatusCode;
  }</message>
            <metadata name="User-Agent" value="@(context.Request.Headers.GetValueOrDefault("User-Agent", ""))" />
            <metadata name="Subscription-Id" value="@(context.Subscription?.Id ?? "anonymous")" />
            <metadata name="correlation-id" value="@((string)context.Variables["correlation-id"])" />
        </trace>
```

5. Kliknij "Save"

Pełna polityka powinna wyglądać następująco:

```xml
<policies>
    <inbound>
        <base />
        <!--Use consumer correlation id or generate new one-->
        <set-variable name="correlation-id" value="@(context.Request.Headers.GetValueOrDefault("x-ms-client-tracking-id", Guid.NewGuid().ToString()))" />
        <!--Set header for end-to-end correlation-->
        <set-header name="x-correlation-id" exists-action="override">
            <value>@((string)context.Variables["correlation-id"])</value>
        </set-header>
        <trace source="API Management Trace">
            <message>@{
    return "Rozpoczęcie przetwarzania żądania " + context.Request.Method + " " + context.Request.Url.Path;
  }</message>
            <metadata name="User-Agent" value="@(context.Request.Headers.GetValueOrDefault("User-Agent", ""))" />
            <metadata name="Subscription-Id" value="@(context.Subscription?.Id ?? "anonymous")" />
            <metadata name="correlation-id" value="@((string)context.Variables["correlation-id"])" />
        </trace>
        <validate-azure-ad-token tenant-id="xxxxxxxxxxx">
            <client-application-ids>
                <application-id>xxxxxxxxxxx</application-id>
            </client-application-ids>
        </validate-azure-ad-token>
        <azure-openai-token-limit counter-key="@(context.Subscription.Id)" tokens-per-minute="10000" estimate-prompt-tokens="true" />
        <set-backend-service id="apim-generated-policy" backend-id="polisy-ai-openai-endpoint" />
        <authentication-managed-identity resource="https://cognitiveservices.azure.com" output-token-variable-name="managed-id-access-token" ignore-error="false" />
        <set-header name="Authorization" exists-action="override">
            <value>@("Bearer " + (string)context.Variables["managed-id-access-token"])</value>
        </set-header>
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
        <trace source="API Management Trace">
            <message>@{
    return "Zakończenie przetwarzania, status: " + context.Response.StatusCode;
  }</message>
            <metadata name="User-Agent" value="@(context.Request.Headers.GetValueOrDefault("User-Agent", ""))" />
            <metadata name="Subscription-Id" value="@(context.Subscription?.Id ?? "anonymous")" />
            <metadata name="correlation-id" value="@((string)context.Variables["correlation-id"])" />
        </trace>
        <json-to-xml apply="always" consider-accept-header="false" parse-date="false" />
        <set-body>@{
        string body = context.Response.Body.As<string>(preserveContent: true);
        body = System.Text.RegularExpressions.Regex.Replace(body,  @"\b\d{6}\b", "xxxxxx");
        return body;}</set-body>
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
```

### 8.3 Analiza metryk i logów

https://learn.microsoft.com/en-us/azure/azure-monitor/app/transaction-search-and-diagnostics?tabs=transaction-search

1. Wykonaj kilka zapytań do API
2. Przejdź do zasobu Application Insights
3. W menu bocznym wybierz "Investigate" a następnie "Transaction search"
4. Sprawdź jak wyglądają wyniki.

---

## 9. Zapoznaj się z innymi politykami

Na stronie https://learn.microsoft.com/en-us/azure/api-management/api-management-policies możesz zapoznać się z pełną listą polityk dostępnych w Azure API Management. Warto abyś sprawdził polityki takie jak Caching czy np. Rewrite URL. Dla Azure Open AI warto również zapoznać się z informacjami o semantic caching, znajdziesz więcej informacji na tej stronie: https://learn.microsoft.com/en-us/azure/api-management/azure-openai-enable-semantic-caching

---

## 10. 

Orson

## 11. Udostępnianie API jako MCP dla Agenta w Microsoft Foundry

https://learn.microsoft.com/en-us/azure/api-management/export-rest-mcp-server

### 11.1 Udostępnienie REST API jako MCP

1. Przejdź do swojego API Management
2. Następnie przejdź do "MCP Servers"
3. Kliknij na "Create MCP server" wybierz "Expose an API as MCP server"
4. W polu "API" wybierz "PolisyAPI"
5. W polu "API operations" wybierz "[Get] GetPolisy"
6. W polu "Display name" wprowadź nazwę "PolisyAPIMCP"
7. W polu "Name" wprowadź nazwę "polisyapimcp"
8. W polu "Description" wprowadź "Lista dostępnych polis"
9. Kliknij "Create"
10. Wejdź do stworzonego MCP o nazwie "PolisyAPIMCP" i zanotuj "MCP server URL", np. https://xxxxxxx.azure-api.net/polisyapimcp/mcp

### 11.2 Konfiguracja agenta w Microsoft Foundry

1. Przejdź na stronę "https://ai.azure.com"
2. Wyszukaj swój Microsoft Foundry, w którym chcesz utworzyć agenta, korzystaj z nowego wyglądu Microsoft Foundry. Zmianę projektu Microsoft Foundry znajdziesz w lewym górnym rogu.
3. Przejdź na zakładkę "Build" - znajdziesz tę opcję w prawym górnym rogu
4. Kliknij na opcję "Create agent"
5. W polu "Create an agent" wpisz "Agent-Ubezpieczeniowy"
6. W polu wyboru modeli wybierz dowolny dostępny model
7. W polu "Instructions" wpisz "Jesteś agentem ubezpieczeniowym, pomagasz klientowi wybrać odpowiednie ubezpieczenie. Masz dostęp do listy ubezpieczeń poprzez serwer MCP."
8. Przejdź do opcji "Tools" wybierz "Add" następnie "Custom" z listy wybierz "Model Context Protocol (MCP)", kliknij "Create"
9. W polu "Name" wprowadź "PolisyAPIMCP"
10. W polu "Remote MCP Server endpoint" wprowadź adres MCP serwera, który zanotowałeś w punkcie 11.1.10
11. W polu "Authentication" wybierz "Microsoft Entra" - będziemy w kolejnych krokach konfigurować politykę po stronie API Management, aby dopuszczała do MCP tego agenta/projektu
12. W polu "Type" wybierz "Agent Identity"
13. Ze względu na to, że Microsoft Foundry Agent Service v2 obecnie nie ma możliwości dodania kilku metod uwierzytelniania jednocześnie, dodamy "Subscription key" do query stringa. Zmień "Remote MCP Server endpoint" na https://xxxxxxx.azure-api.net/polisyapimcp/mcp?api_key=xxxxxxxxxxxxxxxxxxxxx, gdzie "Subscription key" wygenerowałeś w punkcie "3.1".
14. W polu "Audience" wpisz "https://ai.azure.com". 

**Uwaga:** W kolejnej sekcji skonfigurujemy politykę `validate-azure-ad-token` po stronie API Management, która będzie walidować tokeny Microsoft Entra wysyłane przez agenta. Pole "Audience" określa, dla którego odbiorcy token powinien zostać wystawiony, jednak w naszej implementacji skupimy się głównie na walidacji `client-application-id` (identyfikatora aplikacji agenta). Dodatkowo używamy klucza subskrypcji (Subscription key) przekazanego w query stringu jako dodatkowej warstwy zabezpieczeń.

15. Kliknij "Create" aby zapisać konfigurację MCP w agencie.
16. Kliknij "Save"
17. Możesz przetestować działanie agenta, wpisując w okno czatu "Podaj listę dostępnych polis ubezpieczeniowych?". Powinna pojawić się informacja, czy akceptujesz wykonanie zapytania "getPolisy". Ze względu na nieskonfigurowaną politykę system powinien odrzucić dostęp do serwera MCP.

### 11.3 Konfiguracja polityki dla MCP server

1. Przejdź do "https://portal.azure.com", wyszukaj "Microsoft Foundry Project", w którym utworzyłeś agenta z kroku 11.2, przejdź do "Microsoft Foundry Project", a następnie kliknij "JSON View" w prawym górnym rogu i zanotuj "agentIdentityId".
2. Innym sposobem na wyszukanie "agentIdentityId" jest skorzystanie z portalu "https://entra.microsoft.com/" w zakładce "Agent ID". W zakładce "All agent identities" wyszukaj tożsamość z nazwą twojego zasobu "Microsoft Foundry project" z dopiskiem AgentIdentity, np. "Aaifblamis01-aifblamis01-project01-AgentIdentity".
3. Przejdź do swojego API Management.
4. Następnie przejdź do "MCP Servers".
5. Przejdź do "MCP Server" o nazwie "polisyapimcp".
6. Przejdź do zakładki "Policies".
7. Wprowadź poniższą politykę. Zmień w polityce linię dotyczącą "tenant-id" oraz "<application-id>" - wprowadź "application-id" z punktu 11.3.1.

```xml
<!--
    - Policies are applied in the order they appear.
    - Position <base/> inside a section to inherit policies from the outer scope.
    - Comments within policies are not preserved.
-->
<!-- Add policies as children to the <inbound>, <outbound>, <backend>, and <on-error> elements -->
<policies>
	<!-- Throttle, authorize, validate, cache, or transform the requests -->
	<inbound>
		<base />
		<choose>
			<when condition="@(context.Request.Url.Query.ContainsKey("api_key"))">
				<!-- 2. Ustaw nagłówek x-api-key na wartość z query -->
				<set-header name="Ocp-Apim-Subscription-Key" exists-action="override">
					<value>@(context.Request.Url.Query.GetValueOrDefault("api_key", ""))</value>
				</set-header>
				<!-- 3. (Opcjonalnie) usuń api_key z query zanim wyślesz do backendu -->
				<set-query-parameter name="api_key" exists-action="delete" />
			</when>
		</choose>
		<validate-azure-ad-token tenant-id="tenant-id xxxxxxxx" header-name="Authorization" failed-validation-httpcode="401" failed-validation-error-message="Unauthorized. Access token is missing or invalid.">
			<client-application-ids>
				<application-id>xxxxxxxxxxxxxxxxxxxxxx</application-id>
			</client-application-ids>
		</validate-azure-ad-token>
	</inbound>
	<!-- Control if and how the requests are forwarded to services  -->
	<backend>
		<base />
	</backend>
	<!-- Customize the responses -->
	<outbound>
		<base />
	</outbound>
	<!-- Handle exceptions and customize error responses  -->
	<on-error>
		<base />
	</on-error>
</policies>
```

8. Przejdź na stronę "https://ai.azure.com".
9. Wyszukaj swój Microsoft Foundry, w którym został utworzony agent. Korzystaj z nowego wyglądu Microsoft Foundry. Zmianę projektu Microsoft Foundry znajdziesz w lewym górnym rogu.
10. Przejdź na zakładkę "Build" - znajdziesz tę opcję w prawym górnym rogu.
11. Kliknij na opcję "Agents", następnie wybierz "Agent-Ubezpieczeniowy".
12. Możesz przetestować działanie agenta, wpisując w okno czatu "Podaj listę dostępnych polis ubezpieczeniowych?". Powinna pojawić się informacja, czy akceptujesz wykonanie zapytania "getPolisy". Tym razem API Management powinno wyświetlić dane.

## 12

Jakub

## Podsumowanie

Gratulacje! Stworzyłeś kompletny interfejs API za pomocą Azure API Management, który:

- Dostarcza informacje o polisach ubezpieczeniowych
- Integruje się z Azure OpenAI Service
- Jest zabezpieczony przez klucze API i OAuth 2.0
- Kontroluje ruch za pomocą limitów wywołań
- Limit tokenów dla zapytań AI
- Transformuje i anonimizuje dane

- Jest monitorowany w Application Insights


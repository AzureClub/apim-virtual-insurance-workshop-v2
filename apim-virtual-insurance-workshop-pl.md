# Warsztat: Wirtualny Doradca Ubezpieczeniowy z Obsługą Wielokanałową

Celem warsztatu jest stworzenie interfejsu API do integracji z chatbotem generatywnym, który może odpowiadać na pytania klientów dotyczące polis ubezpieczeniowych, przetwarzając dane w czasie rzeczywistym i korzystając z Azure API Management do zarządzania, monitorowania i zabezpieczania API.

## Wymagania dla uczestników

Przed przystąpieniem do warsztatu, upewnij się, że posiadasz:

- Aktywną subskrypcję Azure (lub darmowe środki)
- Wdrożoną usługę Microsoft Foundry z dostępnym modelem np. "gpt-4o-mini"
https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/create-resource?pivots=web-portal
- Wdrożoną usługę "Azure Log Analytics"
https://learn.microsoft.com/en-us/azure/api-management/monitor-api-management
- Wdrożoną usługę "Application Insight"
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
2. Sprawdź, czy posiadasz aktywną subskrypcję

### 1.2 Tworzenie usługi Azure API Management

> 📋 **Ściągawka**: Sprawdź dokument z danymi otrzymany od organizatorów. Znajdziesz tam dokładne nazwy zasobów i endpointy dla Twojego numeru użytkownika `{usernumber}`. Jeśli dla Ciebie nie został utworzony zasób Azure API Management, wykonaj poniższe kroki.

https://learn.microsoft.com/en-us/azure/api-management/get-started-create-service-instance

1. W Azure Portal, wyszukaj "API Management" w pasku wyszukiwania  
2. Kliknij "+ Create" lub "Utwórz"  
3. Wypełnij formularz:
    - **Subscription**: wybierz swoją subskrypcję
    - **Resource Group**: utwórz nową (np. "rg-azureclubworkshopint-{usernumber}")
    - **Region**: wybierz najbliższy (np. France Central lub Sweden Central)
    - **Name**: np. "apim-azureclubworkshopint-{usernumber}"
    - **Organization name**: nazwa Twojej organizacji
    - **Administrator email**: Twój adres email
    - **Pricing tier**: Developer (najtańsza, nieprodukcyjna opcja)
4. W zakładce "Monitor + Secure" zaznacz opcje "Log Analytics" oraz "Application Insights", wybierz wcześniej utworzone zasoby.
5. W zakładce "Virtual Network" zaznacz opcję "Virtual Network", a następnie z "Type" wybierz "External". Poprzez opcję "Create new" utwórz nową sieć wirtualną, wprowadź nazwę i możesz zaakceptować domyślną adresację. 
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
    - W "Representations" kliknij "Add representation"  
    - W polu „Content Type” wybierz "application/json" (jeżeli na liście nie ma application/json wyszukaj w polu na początku listy po application/json lub wpisz „z ręki”) 
    - W pole „Sample” wklej przykładowy schemat: 

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
4. W sekcji „HTTP Response” sprawdź czy otrzymujesz odpowiedź z przykładowymi danymi polis 

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
    - **Base path**: polisy-ai 
    - W polu **Description** podaj dowolny opis 
    - Zaznacz opcję "Azure OpenAI"
4. Kliknij "Next"
5. Zaznacz opcję "Track token usage" (potrzebne do rozliczalności) - zapoznaj się z linkami https://learn.microsoft.com/en-us/azure/api-management/azure-openai-emit-token-metric-policy oraz https://learn.microsoft.com/en-us/azure/api-management/azure-openai-token-limit-policy

6. Wybierz dostępną instancję Application Insights jako miejsce do odkładania metryk tokenów
7. W opcji "dimension" wybierz: API ID, Subscription ID, Operation ID
8. Kliknij "Next" - zapoznaj się z opcją "Semantic caching"
https://learn.microsoft.com/en-us/azure/api-management/azure-openai-enable-semantic-caching
9. Kliknij "Next" - zapoznaj się z opcją "AI content safety"
https://learn.microsoft.com/en-us/azure/api-management/llm-content-safety-policy
10. Kliknij "Next"
11. kliknij "Create"

Samo skonfigurowanie "Track token usage" nie wystarczy, aby metryki pojawiły się w "Application Insight". Należy jeszcze wykonać konfigurację z linka poniżej https://learn.microsoft.com/en-us/azure/api-management/api-management-howto-app-insights?tabs=rest takie jak "Create a connection between Application Insights and API Management", "Enable Application Insights logging for your API" jak również uruchomienie "Emit custom metrics". Dla ułatwienia ustawienie opcji "metrics" możesz zrobić poprzez cloudshell https://shell.azure.com

Aby logować "LLM messages" czyli "prompts" oraz "completions" należy wykonać kroki opisane w tym dokumencie https://learn.microsoft.com/en-us/azure/api-management/api-management-howto-llm-logs

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
8. Tym razem nie wyłączyliśmy w zakładce "Settings" opcji "Subscription required", a jednak udało się nam wysłać zapytanie. Dzieje się to dlatego, że portal automatycznie podkłada klucz. Możesz to sprawdzić poprzez wysłanie zapytania przyciskiem "Trace".
### 2.3 Weryfikacja ustawień subskrypcji dla API polisy-ai

1. Przejdź do "APIs" i wybierz "polisy-ai"
2. Przejdź do zakładki "Settings"
3. W sekcji "Subscription" upewnij się, że jest zaznaczona opcja "Subscription required"
4. Upewnij się że w "Header name" wartość to "Ocp-Apim-Subscription-Key" a w "Query parameter name" widnieje wartość "subscription-key"
5. Kliknij "Save"

### 2.4 Dodawanie uwierzytelniania Managed Identity do Microsoft Foundry

https://learn.microsoft.com/en-us/azure/api-management/api-management-howto-use-managed-service-identity

Sprawdź, czy został włączony dla "API Management" "system managed identity" i czy zostało nadane uprawnienie dla tej tożsamości do "Microsoft Foundry". "Managed Identity" powinno zostać utworzone podczas tworzenia API Management, rola powinna zostać nadana podczas dodawania API "polisy-ai".

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
4. Upewnij się, że w "Header name" wartość to "Ocp-Apim-Subscription-Key", a w "Query parameter name" widnieje wartość "subscription-key"
5. Kliknij "Save"

### 3.3 Testowanie API z kluczem

1. Przejdź do zakładki "Test"
2. Wybierz operację GET /polisy
3. Kliknij "Send" i zweryfikuj, że otrzymujesz prawidłową odpowiedź
4. Sprawdź jak wygląda pełny request (ikonka oka po prawej stronie w sekcji HTTP request). Narzędzie do testowania samo dodaje header "Ocp-Apim-Subscription-Key". Jeśli będziesz korzystał z innych narzędzi, pamiętaj o dodaniu header "Ocp-Apim-Subscription-Key" wraz z prawidłowym kluczem.

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
4. Zauważ, że po 5 wywołaniach otrzymujesz błąd "429 Too Many Requests"

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
    - **Name**: PolisyAPI-OAuth-{usernumber} (wprowadź swój numer użytkownika)
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

### 5.3 Utwórz prostą Azure Logic App, która pomoże Ci przetestować uwierzytelnianie.

https://learn.microsoft.com/en-us/azure/logic-apps/quickstart-create-example-consumption-workflow

1. Na głównej stronie https://portal.azure.com, wybierz opcję "Create a resource".
2. Wyszukaj "Logic App", kliknij "Create"
3. Wybierz "Multi-tenant"
4. Wybierz "Select"
5. Wybierz "Subscription", na której wdrożyłeś API Management
6. Wybierz "Resource Group", w której wdrożyłeś API Management
7. W polu "Logic App name" wpisz "la-azureclubworkshopint-{usernumber}"
8. W polu "Region" wybierz ten sam region, w którym wdrożyłeś API Management.
9. Kliknij "Review + Create" a następnie "Create".
10. Po utworzeniu zasobu kliknij "Go to resource".
11. Kliknij "Edit"
12. Kliknij "Add a trigger", wybierz "Request", następnie "When a HTTP request is received", kliknij "Save".
13. Kliknij znaczek +, który znajduje się poniżej kafelka "When a HTTP request is received", wybierz "Add an action"
14. Wyszukaj "Azure API Management" - wybierz "Choose an Azure API Management action", zaznacz swoją instancję Azure API Management.
15. Wybierz "PolisyAPI", kliknij "Add action".
16. W polu "Operation Id" wybierz "GetPolisy".
17. W polu "Advanced parameters" zaznacz zarówno "Authentication" jak i "Subscription key".
18. W polu "Authentication" wybierz Active Directory OAuth, a następnie wypełnij wszystkie wymagane pola takie jak "Tenant", "Audience", "Client ID" oraz "Secret". W polu "Audience" wpisz "https://management.azure.com/".
19. W polu "Subscription key" wpisz klucz, który wygenerowałeś w punkcie "3.1", kliknij "Save".
20. Kliknij "Run" następnie "Run".
21. Przejdź na "Overview" i sprawdź w zakładce "Run History" wynik wysłania zapytania do "API" wystawionego przez "Azure API Management".
22. Możesz poeksperymentować i pozmieniać wartości, np. zmienić klucz na błędny, aby sprawdzić, że uwierzytelnianie działa. Błędy możesz sprawdzić w "History".

---

## 6. OPEN AI TOKEN LIMIT

### 6.1 Skonfiguruj "Azure Logic App", aby umożliwiało wykorzystanie "Managed Identity" do łączenia się z innymi usługami, takimi jak np. "Azure API Management".

**W przypadku braku uprawnień do Microsoft Entra ID, użyj polecenia Azure CLI, aby wyświetlić identyfikator aplikacji (Application ID). Możesz to zrobić poprzez Azure Cloud Shell.**

```bash
az ad sp show --id '[Object (principal) ID]' | ConvertFrom-Json | select displayName, appId
```

1. Przejdź do "Azure Logic App" o nazwie "la-azureclubworkshopint-{usernumber}".
2. Przejdź do zakładki "Identity", kliknij "System assigned", wybierz "ON", a następnie "Save".
3. W Entra ID znajdź "Application ID", który dotyczy "Managed Identity" utworzonego dla "Azure Logic App". Przejdź do "Entra ID", następnie "Enterprise applications". W "Application type" wybierz "Managed Identity", wyszukaj nazwę "la-azureclubworkshopint-{usernumber}". Zanotuj "Application ID".

### 6.2 Dodawanie polityki limitu tokenów OpenAI

https://learn.microsoft.com/en-us/azure/api-management/azure-openai-token-limit-policy

1. Znajdź "Azure API Management" w portalu Azure, następnie przejdź do "APIs" i wybierz API dla Microsoft Foundry o nazwie "polisy-ai"
2. Przejdź do sekcji "Inbound processing", a następnie "Policies", kliknij w oznaczenie </>
3. W edytorze XML dodaj w sekcji `<inbound>` po `<base />`:

```xml
<azure-openai-token-limit counter-key="@(context.Subscription.Id)" tokens-per-minute="10000" estimate-prompt-tokens="true" />
```

**Uwaga:** Obecnie nie jest już wymagana poniższa polityka (punkty 4,5,6), API MGMT w zakładce "Backend" automatycznie dodaje Managed Identity API MGMT do łączenia się do Microsoft Foundry, warto jednak prześledzić politykę może przydać się w innych integracjach.

4. Dodaj również politykę uwierzytelniania Managed Identity do Azure OpenAI:

https://learn.microsoft.com/en-us/azure/api-management/authentication-managed-identity-policy

```xml
<authentication-managed-identity resource="https://cognitiveservices.azure.com" output-token-variable-name="managed-id-access-token" ignore-error="false" />
<set-header name="Authorization" exists-action="override">
  <value>@("Bearer " + (string)context.Variables["managed-id-access-token"])</value>
</set-header>
```

5. Sprawdź czy jest ustawiony backend OpenAI:

Backend-id musi mieć tę samą nazwę co "Backend name" w zakładce "Backends".

```xml
<set-backend-service id="apim-generated-policy" backend-id="polisy-ai-openai-endpoint" />
```

6. Kliknij "Save"

https://learn.microsoft.com/en-us/azure/api-management/validate-azure-ad-token-policy

8. Zmień politykę "validate-azure-ad-token tenant-id" w celu uwierzytelniania komunikacji tylko z określonego Managed Identity - w tym przypadku podłączonego pod Azure Logic App. Podaj "application-id" z punktu 6.1.3.

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
            <llm-emit-token-metric>
            <dimension name="User ID" />
            <dimension name="Subscription ID" />
            <dimension name="Operation ID" />
        </llm-emit-token-metric>
    <set-backend-service id="apim-generated-policy" backend-id="polisy-ai-openai-endpoint" />
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

### 6.3 Dodanie do już istniejącego Azure Logic App kolejnego konektora, który umożliwi komunikację z Azure OpenAI.

1. Przejdź do Azure Logic App, następnie kliknij "Edit".
2. Kliknij na pierwszy element "When a HTTP request is received". W polu "Request Body JSON Schema" wklej poniższy kod

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

3. Dodaj na sam koniec przepływu (poprzez znaczek +) akcję o nazwie "API Management". Wypełnij formularz, wybierz swoje API Management, a następnie wybierz polisy-ai API, kliknij "Add action".
4. W polu "Operation Id" wybierz "Creates a completion for the chat message".
5. W polu "Deployment-ID" wpisz "gpt-4o-mini" lub inny model, który jest dostępny w Azure OpenAI.
6. W polu "api-version" wpisz "2024-05-01-preview".
7. W polu "Advanced parameters" zaznacz "Authentication", "Subscription key" oraz "body".
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

8. W części "Authentication Types" wybierz "Managed identity". W części "Managed identity" wybierz "System-assigned managed identity", następnie w polu Audience wpisz https://management.azure.com/. W polu "Subscription key" wpisz klucz, który wygenerowałeś w punkcie "3.1".
9. Sprawdź działanie Azure Logic App. Wybierz przycisk "Run", a następnie "Run with payload". W sekcji "Body" wprowadź poniższy kod

```
{
    "prompt": "Proszę podać id oraz ceny dotyczące polis ubezpieczeniowych. Napisz, którą polisę lepiej wybrać?"
}
```

https://learn.microsoft.com/en-us/azure/logic-apps/monitor-logic-apps-overview

10. Poczekaj kilka sekund na odpowiedź z Azure OpenAI i kliknij na "View monitoring view". Sprawdź, jak wyglądał przepływ zdarzeń w Azure Logic App. Przejdź do klocka o nazwie "polisy-ai" i w sekcji "Outputs" znajdź "Body", sprawdź odpowiedź od modelu.
11. Zadanie dodatkowe: zmień polityki w "Azure API Management" oraz konfigurację "Azure Logic App", aby "Azure Logic App" dla "polisyapi" wykorzystywał również "Managed Identity".

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

1. Uruchom Azure Logic App tak jak w części 6.3.9 i sprawdź, że obecnie "Body" na "Outputs" jest w postaci XML, oraz że id polisy zostało zastąpione z 123456 na xxxxxx.

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

1. Uruchom Azure Logic App tak jak w części 6.3.9 i sprawdź, że obecnie "Body" na "Outputs" jest w postaci XML, oraz że wszystkie id polisy zostały zastąpione z 123456 oraz 123457 na xxxxxx.

## 8. MONITOROWANIE I DIAGNOSTYKA W APIM

### 8.1 Konfiguracja Application Insights

https://learn.microsoft.com/en-us/azure/api-management/api-management-howto-app-insights?tabs=rest

1. Jeśli nie masz jeszcze zasobu Application Insights, utwórz go:
    - Wyszukaj "Application Insights" w Azure Portal
    - Kliknij "+ Create"
    - Wypełnij formularz i utwórz zasób
2. Przejdź do zasobu API Management
3. W menu bocznym wyszukaj "Application Insights", dodaj wcześniej utworzony zasób Application Insights.
4. Następnie w menu bocznym wybierz "APIs", następnie "All APIs".
5. Kliknij "Settings" i kliknij "Enable" dla "Application Insight".
6. W polu "Destination" wybierz wcześniej utworzony "Application Insight"
7. W polu "Verbosity" zaznacz "Verbose"
8. Kliknij "Save"

### 8.2 Konfiguracja logowania i śledzenia

https://learn.microsoft.com/en-us/azure/api-management/trace-policy

1. Przejdź do "APIs" i wybierz "polisy-ai"
2. Wybierz zakładkę "Policies"
3. W edytorze XML dodaj w sekcji `<inbound>` po `<base />`:

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
        <validate-azure-ad-token tenant-id="xxxxxxxxxxxxxxxxxxxx">
            <client-application-ids>
                <application-id>xxxxxxxxxxxxxxxx</application-id>
            </client-application-ids>
        </validate-azure-ad-token>
        <azure-openai-token-limit counter-key="@(context.Subscription.Id)" tokens-per-minute="10000" estimate-prompt-tokens="true" />
        <set-backend-service id="apim-generated-policy" backend-id="polisy-ai-ai-endpoint" />
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
3. W menu bocznym wybierz "Investigate", a następnie "Search"
4. Sprawdź, jak wyglądają wyniki.

---

## 9. Zapoznaj się z innymi politykami

Na stronie https://learn.microsoft.com/en-us/azure/api-management/api-management-policies możesz zapoznać się z pełną listą polityk dostępnych w Azure API Management. Warto, abyś sprawdził polityki takie jak Caching czy np. Rewrite URL. Dla Azure OpenAI warto również zapoznać się z informacjami o semantic caching. Więcej informacji znajdziesz na tej stronie: https://learn.microsoft.com/en-us/azure/api-management/azure-openai-enable-semantic-caching

---

## 10. Smart Load Balancing dla Azure AI Foundry

## Wstęp

Smart Load Balancing różni się od tradycyjnego round-robin poprzez:
- **Natychmiastowe reagowanie na błędy 429** (Too Many Requests) - bez opóźnień w przełączaniu
- **Respektowanie nagłówka Retry-After** - automatyczne przywracanie backendów po czasie określonym przez Azure AI Foundry
- **Grupy priorytetowe** - np. PTU (Provisioned Throughput) jako Priority 1, S0 jako fallback Priority 2
- **Obsługa błędów 401/5xx** - automatyczne przełączenie na zdrowy backend

**Dokumentacja referencyjna:** https://learn.microsoft.com/en-us/samples/azure-samples/openai-apim-lb/openai-apim-lb/

---

## 10.1 Architektura rozwiązania

```
                    ┌─────────────────────────────────────────┐
                    │           APIM Policy                    │
                    │  ┌─────────────────────────────────┐    │
                    │  │      listBackends (cached)       │    │
                    │  │  ┌───────────────────────────┐   │    │
HTTP Client ───────►│  │  │ Backend 1 (Priority 1)    │   │────► OpenAI Primary
(skrypt/app)        │  │  │ url, isThrottling         │   │    │
                    │  │  │ retryAfter                │   │    │
                    │  │  ├───────────────────────────┤   │    │
                    │  │  │ Backend 2 (Priority 2)    │   │────► OpenAI Secondary
                    │  │  │ ...                       │   │    │
                    │  │  └───────────────────────────┘   │    │
                    │  └─────────────────────────────────┘    │
                    └─────────────────────────────────────────┘
```

---

## 10.2 Twoje zasoby Azure AI Foundry

Dla tego zadania wykorzystasz **dwa zasoby Azure AI Foundry (OpenAI)** przygotowane dla Ciebie:

| Backend | Nazwa zasobu | Region | Priorytet | Rola |
|---------|--------------|--------|-----------|------|
| **Primary** | `aoai-azureclubworkshopint-{usernumber}-01` | France Central | 1 | Główny endpoint |
| **Secondary** | `aoai-azureclubworkshopint-{usernumber}-02` | Sweden Central | 2 | Backup (failover) |

> 📋 **Ściągawka**: Sprawdź dokument z danymi otrzymany od organizatorów. Znajdziesz tam dokładne nazwy zasobów i endpointy dla Twojego numeru użytkownika `{usernumber}`.

### Gdzie znaleźć endpoint Azure AI Foundry?

Jeśli potrzebujesz zweryfikować endpoint:

1. Przejdź do **Azure AI Foundry portal** (https://ai.azure.com)
2. Znajdź zasób Azure OpenAI (np. `aoai-azureclubworkshopint-{usernumber}-01`)
3. W sekcji **Models** → **Deployments** znajdź endpoint
4. Alternatywnie w **Azure Portal** → **Resource Groups** → `rg-azureclubworkshopint-{usernumber}` → zasób AI → **Keys and Endpoint**

### Format URL-i

Zastąp `{usernumber}` Twoim numerem użytkownika (np. `05`):

```
Primary:   https://aoai-azureclubworkshopint-{usernumber}-01.cognitiveservices.azure.com/
Secondary: https://aoai-azureclubworkshopint-{usernumber}-02.cognitiveservices.azure.com/
```

**Przykład dla użytkownika 05:**
```
Primary:   https://aoai-azureclubworkshopint-05-01.cognitiveservices.azure.com/
Secondary: https://aoai-azureclubworkshopint-05-02.cognitiveservices.azure.com/
```

---

## 10.3 Dodanie drugiego backendu Azure AI Foundry do APIM

W poprzednich zadaniach (sekcja 2) dodałeś do APIM jeden zasób Azure AI Foundry jako backend (Primary). Dla Smart Load Balancing potrzebujesz **dwóch backendów**, więc teraz dodamy drugi zasób (Secondary).

### Krok 1: Weryfikacja istniejącego backendu (Primary)

1. Przejdź do swojego **Azure API Management**
2. W menu bocznym wybierz **"Backends"**
3. Powinieneś zobaczyć backend o nazwie podobnej do `polisy-ai-openai-endpoint` - to Twój **Primary backend** z zadania 2
4. Kliknij na niego i zanotuj:
   - **Backend name** (np. `polisy-ai-openai-endpoint`)
   - **Runtime URL** (np. `https://aoai-azureclubworkshopint-{usernumber}-01.cognitiveservices.azure.com/openai`)

### Krok 2: Dodanie drugiego backendu (Secondary)

1. W sekcji **"Backends"** kliknij **"+ Add"**
2. Wypełnij formularz:
   - **Name**: `polisy-ai-openai-endpoint-secondary`
   - **Type**: Custom URL
   - **Runtime URL**: `https://aoai-azureclubworkshopint-{usernumber}-02.cognitiveservices.azure.com/openai`
     
     > ⚠️ Zastąp `{usernumber}` Twoim numerem użytkownika (np. `05`)
   
3. W sekcji **"Authorization credentials"**:
   - Zostaw domyślne ustawienia (bez dodatkowej autoryzacji - użyjemy Managed Identity w polityce)
   
4. Kliknij **"Create"**

### Krok 3: Weryfikacja obu backendów

Po dodaniu, w sekcji **"Backends"** powinieneś widzieć **dwa wpisy**:

| Backend Name | Runtime URL | Rola |
|-------------|-------------|------|
| `polisy-ai-openai-endpoint` | `https://aoai-azureclubworkshopint-{usernumber}-01.cognitiveservices.azure.com/openai` | Primary |
| `polisy-ai-openai-endpoint-secondary` | `https://aoai-azureclubworkshopint-{usernumber}-02.cognitiveservices.azure.com/openai` | Secondary |

> 💡 **Uwaga**: W tym zadaniu Smart Load Balancing nie używamy backendów zdefiniowanych w APIM bezpośrednio (przez `<set-backend-service backend-id="...">`), lecz dynamicznie ustawiamy URL w polityce. Jednak dodanie backendów jest dobrą praktyką dla przejrzystości i ewentualnych przyszłych rozszerzeń.

---

## 10.4 Nadanie uprawnień Managed Identity do obu zasobów Azure AI Foundry

Upewnij się, że Managed Identity Twojego API Management ma dostęp do **obu** zasobów Azure AI Foundry. W zadaniu 2 nadałeś uprawnienia tylko do Primary - teraz musisz powtórzyć to dla Secondary.

### Uprawnienia dla Primary (weryfikacja)

Uprawnienia do Primary powinny być już nadane z zadania 2. Możesz to zweryfikować:

1. Przejdź do zasobu Azure AI Foundry **Primary** (np. `aoai-azureclubworkshopint-{usernumber}-01`)
2. Wybierz **"Access control (IAM)"**
3. Kliknij **"Role assignments"**
4. Sprawdź czy Twój APIM ma rolę **"Cognitive Services OpenAI User"**

### Uprawnienia dla Secondary (nowe)

1. Przejdź do zasobu Azure AI Foundry **Secondary** (np. `aoai-azureclubworkshopint-{usernumber}-02`)
2. Wybierz **"Access control (IAM)"**
3. Kliknij **"+ Add"** i wybierz **"Add role assignment"**
4. Wybierz rolę **"Cognitive Services OpenAI User"**
5. W zakładce **"Members"** wybierz **"Managed identity"**
6. Kliknij **"+ Select members"**
7. W filtrze "Managed identity" wybierz **"API Management"**
8. Znajdź i zaznacz swój APIM (np. `apim-azureclubworkshopint-{usernumber}`)
9. Kliknij **"Select"**, następnie **"Review + assign"

> ⚠️ **Ważne**: Bez tego kroku polityka Smart Load Balancing zwróci błąd 401 Unauthorized przy próbie użycia Secondary backendu!

---

## 10.5 Konfiguracja polityki Smart Load Balancing

### Kluczowe cechy polityki

Ta polityka implementuje **automatyczny retry** przy błędach 429/5xx:

| Cecha | Opis |
|-------|------|
| **Automatyczny retry** | Przy 429 natychmiast wysyła request do innego backendu |
| **Transparentność dla klienta** | Klient zawsze dostaje 200 (jeśli jakikolwiek backend działa) |
| **Header `x-retry-count`** | Pokazuje ile retry było potrzebnych |
| **Header `x-served-by`** | Pokazuje który backend obsłużył request |
| **Do 3 prób** | Maksymalnie 3 próby zanim zwróci błąd |

### Krok po kroku

> ⚠️ **WAŻNE**: W tym kroku **zastępujesz CAŁĄ dotychczasową politykę** nową wersją. Nie próbuj modyfikować istniejącej polityki - po prostu zaznacz wszystko (Ctrl+A) i wklej nowy kod. Dzięki temu unikniesz problemów z brakującymi elementami.

> 💾 **Opcjonalnie - kopia zapasowa**: Jeśli chcesz mieć możliwość powrotu do poprzedniej wersji polityki, przed zastąpieniem skopiuj obecną zawartość edytora (Ctrl+A, Ctrl+C) i wklej ją do notatnika lub pliku tekstowego (np. `polityka-backup.xml`).

1. Przejdź do **"APIs"** i wybierz **"polisy-ai"**
2. Przejdź do sekcji **"Inbound processing"**, kliknij w oznaczenie **`</>`**
3. **Zaznacz CAŁĄ zawartość** edytora (Ctrl+A) i **usuń** ją
4. Wklej poniższy kod XML (Ctrl+V):

```xml
<policies>
    <inbound>
        <base />
        
        <!-- ============================================== -->
        <!-- SMART LOAD BALANCING - z automatycznym retry -->
        <!-- ============================================== -->
        
        <!-- Inicjalizacja licznika prób (max 3) -->
        <set-variable name="remainingAttempts" value="@(3)" />
        
        <!-- Pobranie listy backendów z cache -->
        <cache-lookup-value key="@("listBackends-" + context.Api.Id)" variable-name="listBackends" />
        
        <choose>
            <when condition="@(!context.Variables.ContainsKey("listBackends"))">
                <set-variable name="listBackends" value="@{
                    // Definicja backendów:
                    // - url: endpoint Azure AI Foundry
                    // - priority: 1 = Primary, 2 = Secondary (fallback)
                    // - isThrottling: czy backend zwraca 429
                    // - retryAfter: kiedy backend będzie znów dostępny

                    JArray backends = new JArray();
                    
                    // Primary backend - Priority 1
                    backends.Add(new JObject()
                    {
                        { "url", "https://aoai-azureclubworkshopint-{usernumber}-01.cognitiveservices.azure.com/" },
                        { "priority", 1},
                        { "isThrottling", false }, 
                        { "retryAfter", DateTime.MinValue } 
                    });

                    // Secondary backend - Priority 2 (fallback)
                    backends.Add(new JObject()
                    {
                        { "url", "https://aoai-azureclubworkshopint-{usernumber}-02.cognitiveservices.azure.com/" },
                        { "priority", 2},
                        { "isThrottling", false },
                        { "retryAfter", DateTime.MinValue }
                    });

                    return backends;   
                }" />
                
                <cache-store-value key="@("listBackends-" + context.Api.Id)" value="@((JArray)context.Variables["listBackends"])" duration="60" />
            </when>
        </choose>

        <!-- Health Check - przywracanie backendów po czasie retryAfter -->
        <set-variable name="listBackends" value="@{
            JArray backends = (JArray)context.Variables["listBackends"];

            for (int i = 0; i < backends.Count; i++)
            {
                JObject backend = (JObject)backends[i];
                if (backend.Value<bool>("isThrottling") && DateTime.Now >= backend.Value<DateTime>("retryAfter"))
                {
                    backend["isThrottling"] = false;
                    backend["retryAfter"] = DateTime.MinValue;
                }
            }
            return backends; 
        }" />

        <!-- Wybór najlepszego backendu (najniższy priorytet spośród zdrowych) -->
        <set-variable name="backendIndex" value="@{
            JArray backends = (JArray)context.Variables["listBackends"];
            int selectedPriority = Int32.MaxValue;
            List<int> availableBackends = new List<int>();

            for (int i = 0; i < backends.Count; i++)
            {
                JObject backend = (JObject)backends[i];
                if (!backend.Value<bool>("isThrottling"))
                {
                    int priority = backend.Value<int>("priority");
                    if (priority < selectedPriority)
                    {
                        selectedPriority = priority;
                        availableBackends.Clear();
                        availableBackends.Add(i);
                    }
                    else if (priority == selectedPriority)
                    {
                        availableBackends.Add(i);
                    }
                }
            }

            if (availableBackends.Count == 0) { return 0; }
            return availableBackends[new Random().Next(availableBackends.Count)];
        }" />

        <set-variable name="backendUrl" value="@{
            JArray backends = (JArray)context.Variables["listBackends"];
            int index = context.Variables.GetValueOrDefault<int>("backendIndex");
            return ((JObject)backends[index])["url"].ToString();
        }" />

        <!-- Managed Identity Authentication -->
        <authentication-managed-identity resource="https://cognitiveservices.azure.com" output-token-variable-name="msi-access-token" ignore-error="false" />
        <set-header name="Authorization" exists-action="override">
            <value>@("Bearer " + (string)context.Variables["msi-access-token"])</value>
        </set-header>

        <!-- Ustawienie backend URL -->
        <set-backend-service base-url="@((string)context.Variables["backendUrl"] + "openai")" />
        
        <!-- Zapisanie body requestu do ewentualnego retry -->
        <set-variable name="originalBody" value="@(context.Request.Body.As<string>(preserveContent: true))" />

    </inbound>
    
    <backend>
        <forward-request buffer-request-body="true" />
    </backend>
    
    <outbound>
        <base />
        
        <!-- ============================================== -->
        <!-- AUTOMATYCZNY RETRY przy 429/5xx               -->
        <!-- ============================================== -->
        <choose>
            <when condition="@(context.Response != null && (context.Response.StatusCode == 429 || context.Response.StatusCode >= 500))">
                
                <!-- Oznacz aktualny backend jako throttling -->
                <set-variable name="listBackends" value="@{
                    JArray backends = (JArray)context.Variables["listBackends"];
                    int currentBackendIndex = context.Variables.GetValueOrDefault<int>("backendIndex");
                    int retryAfter = 10;
                    
                    if (context.Response.Headers.ContainsKey("Retry-After"))
                    {
                        int.TryParse(context.Response.Headers.GetValueOrDefault("Retry-After", "10"), out retryAfter);
                    }
                    
                    JObject backend = (JObject)backends[currentBackendIndex];
                    backend["isThrottling"] = true;
                    backend["retryAfter"] = DateTime.Now.AddSeconds(retryAfter);
                    return backends;      
                }" />
                
                <cache-store-value key="@("listBackends-" + context.Api.Id)" value="@((JArray)context.Variables["listBackends"])" duration="60" />
                
                <!-- Zmniejsz licznik prób -->
                <set-variable name="remainingAttempts" value="@(context.Variables.GetValueOrDefault<int>("remainingAttempts") - 1)" />
                
                <!-- Sprawdź czy są dostępne backendy i czy mamy jeszcze próby -->
                <choose>
                    <when condition="@{
                        int remaining = context.Variables.GetValueOrDefault<int>("remainingAttempts");
                        if (remaining <= 0) { return false; }
                        JArray backends = (JArray)context.Variables["listBackends"];
                        for (int i = 0; i < backends.Count; i++)
                        {
                            if (!((JObject)backends[i]).Value<bool>("isThrottling")) { return true; }
                        }
                        return false;
                    }">
                        
                        <trace source="Smart-LB">
                            <message>@("Failover from: " + (string)context.Variables["backendUrl"])</message>
                        </trace>
                        
                        <!-- Wybierz nowy backend -->
                        <set-variable name="backendIndex" value="@{
                            JArray backends = (JArray)context.Variables["listBackends"];
                            int selectedPriority = Int32.MaxValue;
                            List<int> availableBackends = new List<int>();
                            
                            for (int i = 0; i < backends.Count; i++)
                            {
                                JObject backend = (JObject)backends[i];
                                if (!backend.Value<bool>("isThrottling"))
                                {
                                    int priority = backend.Value<int>("priority");
                                    if (priority < selectedPriority)
                                    {
                                        selectedPriority = priority;
                                        availableBackends.Clear();
                                        availableBackends.Add(i);
                                    }
                                    else if (priority == selectedPriority)
                                    {
                                        availableBackends.Add(i);
                                    }
                                }
                            }
                            
                            if (availableBackends.Count == 0) { return 0; }
                            return availableBackends[new Random().Next(availableBackends.Count)];
                        }" />

                        <set-variable name="backendUrl" value="@{
                            JArray backends = (JArray)context.Variables["listBackends"];
                            int index = context.Variables.GetValueOrDefault<int>("backendIndex");
                            return ((JObject)backends[index])["url"].ToString();
                        }" />
                        
                        <!-- Wyślij request do nowego backendu -->
                        <send-request mode="new" response-variable-name="retryResponse" timeout="60" ignore-error="false">
                            <set-url>@((string)context.Variables["backendUrl"] + "openai" + context.Request.OriginalUrl.Path.Substring(context.Api.Path.Length) + context.Request.OriginalUrl.QueryString)</set-url>
                            <set-method>@(context.Request.Method)</set-method>
                            <set-header name="Authorization" exists-action="override">
                                <value>@("Bearer " + (string)context.Variables["msi-access-token"])</value>
                            </set-header>
                            <set-header name="Content-Type" exists-action="override">
                                <value>application/json</value>
                            </set-header>
                            <set-body>@((string)context.Variables["originalBody"])</set-body>
                        </send-request>
                        
                        <!-- Zastąp odpowiedź odpowiedzią z retry -->
                        <return-response response-variable-name="retryResponse">
                            <set-header name="x-served-by" exists-action="override">
                                <value>@((string)context.Variables["backendUrl"])</value>
                            </set-header>
                            <set-header name="x-retry-count" exists-action="override">
                                <value>@((3 - context.Variables.GetValueOrDefault<int>("remainingAttempts")).ToString())</value>
                            </set-header>
                        </return-response>
                        
                    </when>
                </choose>
                
            </when>
        </choose>
        
        <!-- Header pokazujący który backend obsłużył request -->
        <set-header name="x-served-by" exists-action="override">
            <value>@((string)context.Variables["backendUrl"])</value>
        </set-header>
        
    </outbound>
    
    <on-error>
        <base />
    </on-error>
</policies>
```

5. Kliknij **"Save"**

> ✅ **Gotowe!** Polityka Smart Load Balancing jest teraz aktywna. Przejdź do następnego kroku, aby dostosować URL-e backendów.

---

## 10.6 Dostosowanie URL-i backendów

⚠️ **Ważne:** Przed zapisaniem polityki, zastąp placeholder `{usernumber}` Twoim numerem użytkownika.

1. W sekcji `listBackends` znajdź linie z URL-ami:
   ```csharp
   { "url", "https://aoai-azureclubworkshopint-{usernumber}-01.cognitiveservices.azure.com/" },
   ...
   { "url", "https://aoai-azureclubworkshopint-{usernumber}-02.cognitiveservices.azure.com/" },
   ```

2. Zastąp `{usernumber}` Twoim numerem użytkownika (np. `05`):
   ```csharp
   { "url", "https://aoai-azureclubworkshopint-05-01.cognitiveservices.azure.com/" },
   ...
   { "url", "https://aoai-azureclubworkshopint-05-02.cognitiveservices.azure.com/" },
   ```

> 📋 **Tip**: Sprawdź ściągawkę otrzymaną od organizatorów - znajdziesz tam dokładne URL-e Twoich zasobów Azure AI Foundry.

---

## 10.7 Przygotowanie do testu - zmniejszenie limitu TPM

Aby przetestować działanie Smart Load Balancing, musimy wywołać błąd 429 (Too Many Requests) na Primary backendu. W tym celu **tymczasowo zmniejszymy limit TPM** na deploymencie Primary do minimalnej wartości.

### Krok 1: Zmniejszenie TPM na Primary OpenAI

1. Przejdź do **Azure AI Foundry portal** (https://ai.azure.com)
2. Wybierz swój zasób Azure AI Foundry **Primary** (np. `aoai-azureclubworkshopint-XX-01`)
3. Przejdź do sekcji **Deployments**
4. Znajdź deployment `gpt-4o-mini` i kliknij na niego
5. Kliknij **Edit deployment** lub ikonę edycji
6. W polu **Tokens per Minute Rate Limit** zmień wartość na **1K** (1000)
7. Kliknij **Save**

> 💡 **Wyjaśnienie**: Limit 1K TPM oznacza ~10-15 krótkich requestów na minutę. Przy intensywnym ruchu szybko osiągniemy limit i otrzymamy błąd 429.

### Krok 2: Weryfikacja limitu Secondary (opcjonalnie)

Upewnij się, że Secondary Azure AI Foundry ma wyższy limit (np. 10K TPM), aby mógł obsłużyć ruch po failover:

1. Przejdź do zasobu Azure AI Foundry **Secondary** (np. `aoai-azureclubworkshopint-XX-02`)
2. Sprawdź że deployment `gpt-4o-mini` ma limit **10K TPM** lub wyższy

---

## 10.8 Testowanie Smart Load Balancingu

Do testowania Smart Load Balancing użyjemy **skryptu PowerShell** `Test-SmartLoadBalancing.ps1`, który automatycznie:
- Pobiera token Azure AD z Azure CLI (nie wymaga subscription key!)
- Wysyła wiele równoległych requestów
- Wyświetla szczegółowe wyniki z informacją o retry i failover

> ⚠️ **WAŻNE - Wyłączenie wymagania subskrypcji**: Przed uruchomieniem testu upewnij się, że w APIM **wyłączona jest opcja "Subscription required"** dla API `polisy-ai`.
>
> **Jak sprawdzić/wyłączyć:**
> 1. Przejdź do **Azure API Management** → **APIs** → **polisy-ai**
> 2. Kliknij zakładkę **"Settings"**
> 3. W sekcji **"Subscription"** odznacz checkbox **"Subscription required"**
> 4. Kliknij **"Save"**
>
> Dzięki temu skrypt może używać tokenu Azure AD zamiast klucza subskrypcji APIM.

### Nowe headery diagnostyczne

Polityka Smart Load Balancing dodaje dodatkowe headery do odpowiedzi:

| Header | Opis | Przykład |
|--------|------|----------|
| `x-served-by` | URL backendu który obsłużył request | `https://aoai-azureclubworkshopint-XX-01.cognitiveservices.azure.com/` |
| `x-retry-count` | Ile retry było potrzebnych (pusty = 0) | `1` (oznacza failover do innego backendu) |

### Uruchomienie testu

1. **Otwórz terminal PowerShell** w katalogu z materiałami warsztatu

2. **Upewnij się, że jesteś zalogowany do Azure:**
   ```powershell
   az login
   ```

3. **Uruchom skrypt testowy** (zastąp `usernumber` Twoim numerem użytkownika):
   ```powershell
   .\scripts\Test-SmartLoadBalancing.ps1 -TeamNumber "usernumber" -RequestCount 25
   ```

   > 💡 **Rekomendacja**: Wartość **25 requestów** jest optymalna do przetestowania failover. Przy mniejszej liczbie (np. 10-15) może nie dojść do przekroczenia limitu TPM na Primary, a przy większej test trwa niepotrzebnie długo.

### Przykładowy output

```
╔════════════════════════════════════════════════════════════════╗
║       SMART LOAD BALANCING TEST - Azure API Management         ║
╚════════════════════════════════════════════════════════════════╝

[CONFIG] Konfiguracja testu:
  • Uzytkownik:       05
  • APIM:             apim-azureclubworkshopint-05
  • Liczba requestow: 25
  • Tryb rownlegly:   True

[INFO] Pobieranie tokenu Azure AD z Azure CLI...
[OK] Token Azure AD pobrany

[INFO] Rozpoczynam test...

[MODE] Wysylanie 20 requestow ROWNOLEGLE...

╔════════════════════════════════════════════════════════════════╗
║                        WYNIKI TESTU                            ║
╚════════════════════════════════════════════════════════════════╝

[SZCZEGOLY] Wyniki per-request:
─────────────────────────────────────────────────────────────────
  Request  1: PRIMARY              
  Request  2: PRIMARY              
  Request  3: SECONDARY   (retry: 1)  ← FAILOVER!
  Request  4: SECONDARY   (retry: 1)  ← FAILOVER!
  Request  5: PRIMARY              
  ...

─────────────────────────────────────────────────────────────────
[STATYSTYKI]
─────────────────────────────────────────────────────────────────
  Czas trwania testu:     12.3 sekund
  Laczna liczba requestow: 20

  PRIMARY (Priority 1):   15 requestow
  SECONDARY (Priority 2): 5 requestow
  ERRORS:                 0 requestow
  Z automatycznym RETRY:  5 requestow

─────────────────────────────────────────────────────────────────
[PODSUMOWANIE]
─────────────────────────────────────────────────────────────────

  ✅ SUKCES! Smart Load Balancing DZIALA POPRAWNIE!

  Co sie stalo:
  • Primary backend osiagnal limit TPM (429)
  • Polityka automatycznie wykonala RETRY do Secondary
  • Klient otrzymal odpowiedz 200 OK (nie widzial bledu 429)

  Header 'x-retry-count' pokazuje ile retry bylo potrzebnych.
```

### Interpretacja wyników

| Wynik | Znaczenie |
|-------|-----------|
| `PRIMARY` | Request obsłużony przez Primary (Priority 1) - normalna sytuacja |
| `SECONDARY (retry: 1)` | Primary zwrócił 429, automatyczny retry do Secondary - **failover zadziałał!** |
| `ERROR 429` | Wszystkie backendy throttlują - zwiększ limit TPM na Secondary |
| `ERROR 401` | Problem z Managed Identity - sprawdź uprawnienia APIM do OpenAI |

### Parametry skryptu

| Parametr | Opis | Domyślna wartość | Rekomendacja |
|----------|------|------------------|---------------|
| `-UserNumber` | Twój numer użytkownika (wymagany) | - | - |
| `-RequestCount` | Liczba requestów do wysłania | 20 | **25** |
| `-Parallel` | Czy wysyłać równolegle | `$true` | `$true` |

### Co obserwować w wynikach?

1. **Podstawowe działanie**: Pierwsze requesty powinny trafiać do **PRIMARY**
2. **Failover**: Gdy Primary osiągnie limit TPM (1K), zobaczysz przełączenie na **SECONDARY** z oznaczeniem `(retry: 1)`
3. **Automatyczne przywracanie**: Po ~10-60 sekundach Primary wróci do użycia

> 💡 **Kluczowa różnica od tradycyjnego load balancingu**: Dzięki automatycznemu retry, **klient nigdy nie widzi błędu 429** dopóki przynajmniej jeden backend jest dostępny!

---

## 10.9 Obserwacja Load Balancing - metody weryfikacji

Istnieje kilka sposobów obserwacji działania Smart Load Balancing. Poniżej opisujemy wszystkie metody - od najprostszej do najbardziej zaawansowanej.

### Metoda 1: Wyniki skryptu testowego (⭐ REKOMENDOWANA)

**Najłatwiejsza metoda** - skrypt `Test-SmartLoadBalancing.ps1` automatycznie wyświetla:

- **Per-request**: który backend obsłużył każdy request (PRIMARY/SECONDARY)
- **Failover**: oznaczenie `(retry: X)` gdy nastąpiło automatyczne przełączenie
- **Statystyki**: podsumowanie ile requestów obsłużył każdy backend

Przykładowy fragment wyniku:
```
  Request  1: PRIMARY              
  Request  2: PRIMARY              
  Request  3: SECONDARY   (retry: 1)  ← FAILOVER!
  Request  4: SECONDARY   (retry: 1)  ← FAILOVER!
  Request  5: PRIMARY              
```

---

### Metoda 2: Application Insights - Transaction Search

Application Insights zbiera szczegółowe logi z APIM, w tym trace'y i metryki.

1. Przejdź do zasobu **Application Insights** (np. `appi-azureclubworkshopint-XX`)
2. W menu wybierz **"Investigate"** → **"Transaction search"**
3. Ustaw zakres czasowy na ostatnie 30 minut
4. Szukaj requestów do API `polisy-ai`
5. W szczegółach transakcji znajdziesz:
   - Request URL (pokazuje backend)
   - Custom properties z headerami
   - Trace messages: "Backend throttling detected. Switching to another backend."

---

### Metoda 3: Azure AI Foundry Metrics

Metryki per-zasób Azure AI Foundry pokazują ile requestów obsłużył każdy backend.

1. Przejdź do **Azure AI Foundry portal** (https://ai.azure.com)
2. Wybierz zasób Azure AI Foundry (Primary lub Secondary)
3. Przejdź do **Metrics** w menu bocznym
4. Dodaj metrykę: **"Azure OpenAI Requests"** (nazwa metryki pozostaje taka sama)
5. Ustaw agregację: **Count**
6. Zakres: ostatnie 30 minut, granularność 1 minuta

**Interpretacja**:
- **Primary** (`aoai-azureclubworkshopint-XX-01`): dużo requestów, potem nagły spadek
- **Secondary** (`aoai-azureclubworkshopint-XX-02`): początkowo 0, potem wzrost (failover)

---

### Metoda 4: Log Analytics - zapytanie KQL (zaawansowane)

> ⚠️ **Wymagana konfiguracja**: Aby korzystać z tej metody, APIM musi mieć włączoną diagnostykę do Log Analytics z logami `GatewayLogs` w trybie **Resource-specific**. 
> 
> **Uwaga o opóźnieniach:**
> - `requests` (Application Insights) - dane dostępne **natychmiast** (~1-2 minuty)
> - `ApiManagementGatewayLogs` - dane dostępne z opóźnieniem **10-20 minut**

Dla szczegółowej analizy, użyj zapytania KQL:

> ⚠️ **Ważne**: Zapytania do `requests` uruchamiaj w **Application Insights** (`appi-azureclubworkshopint-XX`), a zapytania do `ApiManagementGatewayLogs` w **Log Analytics Workspace** (`log-azureclubworkshopint-XX`).
>
> **Różnica nazewnictwa tabel:**
> | Application Insights | Log Analytics (cross-workspace) |
> |---------------------|--------------------------------|
> | `requests` | `AppRequests` |
> | `timestamp` | `TimeGenerated` |
> | `url` | `Url` |
> | `resultCode` | `ResultCode` |

### Zapytania w Application Insights

1. Przejdź do zasobu **Application Insights** (np. `appi-azureclubworkshopint-XX`)
2. Wybierz **"Logs"** w menu bocznym
3. Wklej poniższe zapytanie:

**Zapytanie 1: Application Insights - rozkład requestów** (⭐ działa natychmiast):

```kusto
// Rozkład requestów do API polisy-ai w czasie
requests
| where timestamp > ago(2h)
| where url contains "polisy-ai"
| summarize RequestCount = count() by bin(timestamp, 1m), resultCode
| render timechart
```

### Zapytania w Log Analytics Workspace

1. Przejdź do zasobu **Log Analytics Workspace** (np. `log-azureclubworkshopint-XX`)
2. Wybierz **"Logs"** w menu bocznym
3. Wklej poniższe zapytanie:

**Zapytanie 2: APIM Gateway Logs - podsumowanie backendów** (⭐ REKOMENDOWANE, wymaga ~15 min na pojawienie się danych):

> 💡 **Dostosuj zakres czasowy**: Domyślnie zapytania używają `ago(2h)` (ostatnie 2 godziny). Jeśli Twoje testy były wcześniej, zwiększ ten zakres, np. `ago(4h)` lub `ago(6h)`. Każdy uczestnik pracuje w swoim tempie!

```kusto
// Podsumowanie requestów per backend - WYRAŹNIE pokazuje rozkład!
ApiManagementGatewayLogs
| where TimeGenerated > ago(2h)  // ← zmień na ago(4h) lub ago(6h) jeśli potrzebujesz
| where ApiId == "polisy-ai"
| extend BackendHost = tostring(split(BackendUrl, "/")[2])
| summarize RequestCount = count() by BackendHost
| order by RequestCount desc
```

**Przykładowy wynik:**
| BackendHost | RequestCount |
|-------------|--------------|
| `aoai-azureclubworkshopint-XX-01.cognitiveservices.azure.com` | 31 |
| `aoai-azureclubworkshopint-XX-02.cognitiveservices.azure.com` | 9 |

> 👆 **Interpretacja**: Primary (`XX-01`) obsłużył 31 requestów, Secondary (`XX-02`) obsłużył 9 requestów po failover!

**Zapytanie 3: Porównanie latencji między backendami** ⭐:

```kusto
// Porównanie średniego czasu odpowiedzi (ms) per backend
ApiManagementGatewayLogs
| where TimeGenerated > ago(2h)
| where ApiId == "polisy-ai"
| extend BackendHost = tostring(split(BackendUrl, "/")[2])
| summarize 
    AvgLatency = round(avg(todouble(BackendTime)), 0),
    MaxLatency = max(todouble(BackendTime)),
    MinLatency = min(todouble(BackendTime)),
    RequestCount = count() 
    by BackendHost
| order by RequestCount desc
```

**Przykładowy wynik:**
| BackendHost | AvgLatency | MaxLatency | MinLatency | RequestCount |
|-------------|------------|------------|------------|--------------|
| `XX-01.cognitiveservices.azure.com` | **7653** | 56544 | 197 | 31 |
| `XX-02.cognitiveservices.azure.com` | **281** | 367 | 257 | 9 |

> 👆 **Interpretacja**: Primary (`XX-01`) ma znacznie wyższą latencję (~7.6s) bo throttluje i czeka na retry. Secondary (`XX-02`) odpowiada szybko (~280ms) bo ma zapas capacity!

---

**Zapytanie 4: Success vs Throttled vs Errors per backend** ⭐:

```kusto
// Rozkład status codes per backend - pokazuje ile requestów było throttlowanych
ApiManagementGatewayLogs
| where TimeGenerated > ago(2h)
| where ApiId == "polisy-ai"
| extend BackendHost = tostring(split(BackendUrl, "/")[2])
| summarize 
    Success = countif(BackendResponseCode == "200"),
    Throttled = countif(BackendResponseCode == "429"),
    Errors = countif(BackendResponseCode != "200" and BackendResponseCode != "429")
    by BackendHost
```

**Przykładowy wynik:**
| BackendHost | Success | Throttled | Errors |
|-------------|---------|-----------|--------|
| `XX-01.cognitiveservices.azure.com` | 23 | **8** | 0 |
| `XX-02.cognitiveservices.azure.com` | 9 | 0 | 0 |

> 👆 **Interpretacja**: Primary (`XX-01`) zwrócił 8 razy błąd 429 (throttling), ale polityka automatycznie wykonała retry do Secondary - dlatego klient zawsze dostał 200!

---

**Zapytanie 5: APIM Gateway Logs - rozkład backendów w czasie** (wykres):

```kusto
// Rozkład requestów między backendami w czasie (wykres)
ApiManagementGatewayLogs
| where TimeGenerated > ago(1h)
| where ApiId == "polisy-ai"
| extend BackendHost = tostring(split(BackendUrl, "/")[2])
| summarize RequestCount = count() by BackendHost, bin(TimeGenerated, 1m)
| render timechart
```

> 💡 **Jeśli `ApiManagementGatewayLogs` jest puste**: Tabela tworzy się automatycznie po włączeniu diagnostyki, ale pierwsze dane pojawiają się z opóźnieniem 10-20 minut. Użyj `AppRequests` (w Application Insights) do natychmiastowej weryfikacji.

4. Kliknij **"Run"**
5. Tabela/wykres pokaże rozkład requestów między backendami

### Zapytanie w Application Insights (podsumowanie)

> ⚠️ **Uwaga**: To zapytanie uruchom w **Application Insights** (`appi-azureclubworkshopint-XX`), nie w Log Analytics!
>
> **Różnica nazewnictwa**: W Application Insights tabela nazywa się `requests` (nie `AppRequests`), a kolumny używają camelCase (`timestamp`, `url`, `resultCode`).

**Zapytanie 6: Application Insights - tabela podsumowująca**:

```kusto
// Podsumowanie requestów per status code
// URUCHOM W: Application Insights → Logs
requests
| where timestamp > ago(2h)
| where url contains "polisy-ai"
| summarize 
    TotalRequests = count(),
    SuccessfulRequests = countif(resultCode == "200"),
    FailedRequests = countif(resultCode != "200")
    by bin(timestamp, 5m)
| order by timestamp desc
```

> 💡 **Tip**: Jeśli chcesz widzieć szczegółowe logi z headerami `x-served-by`, użyj **Application Insights → Transaction Search** (Metoda 2) - tam zobaczysz pełne szczegóły każdego requestu.

---

### Podsumowanie metod obserwacji

| Metoda | Łatwość | Szczegółowość | Najlepsze zastosowanie |
|--------|---------|---------------|------------------------|
| **Skrypt testowy** | ⭐⭐⭐ Łatwe | Podstawowa | Szybka weryfikacja per-request |
| **App Insights** | ⭐⭐ Średnie | Średnia | Trace'y i debugging |
| **OpenAI Metrics** | ⭐⭐ Średnie | Per-zasób | Ogólny obraz obciążenia |
| **Log Analytics KQL** | ⭐ Zaawansowane | Najwyższa | Szczegółowa analiza i raporty |

---

## 10.10 Przywrócenie normalnego limitu TPM

⚠️ **Po zakończeniu testów**, przywróć normalny limit TPM na Primary:

1. Przejdź do **Azure AI Foundry portal** (https://ai.azure.com)
2. Wybierz zasób Azure AI Foundry **Primary**
3. Edytuj deployment `gpt-4o-mini`
4. Zmień **Tokens per Minute Rate Limit** z powrotem na **10K** lub wyższą wartość
5. Kliknij **Save**

> 💡 Ten krok jest ważny, aby zapewnić normalną przepustowość dla kolejnych zadań lub użytkowników.

---

## 10.11 Jak działa algorytm Smart Load Balancing

### Przepływ dla każdego requestu:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           INBOUND PROCESSING                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│  1. Inicjalizacja: remainingAttempts = 3                                    │
│  2. Pobranie listy backendów z cache (lub inicjalizacja)                   │
│  3. Health Check - przywracanie backendów po czasie retryAfter             │
│  4. Wybór backendu z najniższym priorytetem spośród zdrowych               │
│  5. Zapisanie originalBody (do ewentualnego retry)                         │
│  6. Forward request do wybranego backendu                                   │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                          OUTBOUND PROCESSING                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│  Response 200?                                                               │
│       │                                                                      │
│      YES ──────────────────────► Zwróć odpowiedź klientowi                  │
│       │                          + header x-served-by                        │
│      NO (429/5xx)                                                           │
│       │                                                                      │
│       ▼                                                                      │
│  1. Oznacz backend jako throttling                                          │
│  2. remainingAttempts--                                                     │
│  3. Czy remainingAttempts > 0 AND są zdrowe backendy?                       │
│       │                                                                      │
│      YES ──► Wybierz nowy backend ──► send-request ──► return-response     │
│       │      + header x-retry-count                                         │
│      NO                                                                      │
│       │                                                                      │
│       ▼                                                                      │
│  Zwróć oryginalną odpowiedź 429/5xx                                         │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Kluczowa różnica: Automatyczny Retry

**Tradycyjny load balancing:**
- Przy 429 tylko oznacza backend jako throttling
- Klient dostaje błąd 429
- Dopiero **następny request** trafi do innego backendu

**Smart Load Balancing (ta polityka):**
- Przy 429 **natychmiast** wybiera inny backend
- Wysyła **nowy request** do zdrowego backendu (używając `send-request`)
- Klient dostaje **200 OK** z odpowiedzią
- Header `x-retry-count` informuje ile retry było potrzebnych

### Maksymalna liczba prób

Polityka wykonuje **maksymalnie 3 próby**:
1. Pierwsza próba do Primary (Priority 1)
2. Jeśli 429 → retry do Secondary (Priority 2) 
3. Jeśli znów 429 → ostatnia próba

Jeśli wszystkie próby zawiodą lub wszystkie backendy throttlują → klient dostaje błąd.

---

## 10.12 Kluczowe elementy polityki

| Element | Cel |
|---------|-----|
| `remainingAttempts` | Licznik prób (max 3) |
| `listBackends` | Tablica JSON z backendami, priorytetami i statusem |
| `originalBody` | Zapisane body requestu do retry |
| `cache-store-value` | Przechowuje stan backendów między requestami |
| `isThrottling` | Flaga czy backend zwraca 429 |
| `retryAfter` | Timestamp kiedy backend będzie znów zdrowy |
| `priority` | Niższa wartość = wyższy priorytet |
| `send-request` | Wysyła retry request do nowego backendu |
| `return-response` | Podmienia odpowiedź na wynik retry |
| `x-served-by` | Header - który backend obsłużył request |
| `x-retry-count` | Header - ile retry było wykonanych |

---

## 10.13 Rozszerzenia (opcjonalne)

### Dodanie trzeciego backendu

Aby dodać kolejny backend, w sekcji `listBackends` dodaj:

```xml
backends.Add(new JObject()
{
    { "url", "https://aoai-azureclubworkshopint-XX-03.cognitiveservices.azure.com/" },
    { "priority", 3},
    { "isThrottling", false },
    { "retryAfter", DateTime.MinValue }
});
```

### Użycie zewnętrznego Redis Cache

Dla środowisk z wieloma instancjami APIM, rozważ użycie zewnętrznego Redis Cache:
https://learn.microsoft.com/azure/api-management/api-management-howto-cache-external

---

## Podsumowanie

Po wykonaniu tego zadania Twoje API:
- ✅ Automatycznie przełącza się między backendami Azure AI Foundry
- ✅ Respektuje limity rate limiting (429)
- ✅ Wykorzystuje priorytety (PTU przed S0)
- ✅ Natychmiast reaguje na błędy bez opóźnień
- ✅ Loguje informacje o failover do Application Insights

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
9. W polu "Description" wprowadź "Lista dostępnych polis".
10. Kliknij "Create"
11. Wejdź do stworzonego MCP o nazwie "PolisyAPIMCP" i zanotuj "MCP server URL", np. https://xxxxxxx.azure-api.net/polisyapimcp/mcp

### 11.2 Konfiguracja agenta w Microsoft Foundry

1. Przejdź na stronę "https://ai.azure.com".
2. Wyszukaj swój Microsoft Foundry, w którym chcesz utworzyć agenta. Korzystaj z nowego wyglądu Microsoft Foundry. Zmianę projektu Microsoft Foundry znajdziesz w lewym górnym rogu.
3. Przejdź na zakładkę "Build" - znajdziesz tę opcję w prawym górnym rogu.
4. Kliknij na opcję "Create agent".
5. W polu "Create an agent" wpisz "Agent-Ubezpieczeniowy".
6. W polu wyboru modeli wybierz dowolny dostępny model.
7. W polu "Instructions" wpisz "Jesteś agentem ubezpieczeniowym, pomagasz klientowi wybrać odpowiednie ubezpieczenie. Masz dostęp do listy ubezpieczeń poprzez serwer MCP."
8. Przejdź do opcji "Tools", wybierz "Add", następnie "Custom". Z listy wybierz "Model Context Protocol (MCP)", kliknij "Create".
9. W polu "Name" wprowadź "PolisyAPIMCP".
10. W polu "Remote MCP Server endpoint" wprowadź adres MCP serwera, który zanotowałeś w punkcie 11.1.11.
11. W polu "Authentication" wybierz "Microsoft Entra" - będziemy w kolejnych krokach konfigurować politykę po stronie API Management, aby dopuszczała do MCP tego agenta/projektu
12. W polu "Type" wybierz "Agent Identity"
13. Ze względu na to, że Microsoft Foundry Agent Service v2 obecnie nie ma możliwości dodania kilku metod uwierzytelniania jednocześnie, dodamy "Subscription key" do query stringa. Zmień "Remote MCP Server endpoint" na https://xxxxxxx.azure-api.net/polisyapimcp/mcp?api_key=xxxxxxxxxxxxxxxxxxxxx, gdzie "Subscription key" został wygenerowany w punkcie "3.1".
14. W polu "Audience" wpisz "https://ai.azure.com". 

**Uwaga:** W kolejnej sekcji skonfigurujemy politykę `validate-azure-ad-token` po stronie API Management, która będzie walidować tokeny Microsoft Entra wysyłane przez agenta. Pole "Audience" określa, dla którego odbiorcy token powinien zostać wystawiony, jednak w naszej implementacji skupimy się głównie na walidacji `client-application-id` (identyfikatora aplikacji agenta). Dodatkowo używamy klucza subskrypcji (Subscription key) przekazanego w query stringu jako dodatkowej warstwy zabezpieczeń.

15. Kliknij "Create", aby zapisać konfigurację MCP w agencie.
16. Kliknij "Save".
17. Możesz przetestować działanie agenta, wpisując w okno czatu "Podaj listę dostępnych polis ubezpieczeniowych?". Powinna pojawić się informacja, czy akceptujesz wykonanie zapytania "getPolisy". Ze względu na nieskonfigurowaną politykę, system powinien odrzucić dostęp do serwera MCP.

### 11.3 Konfiguracja polityki dla MCP server

1. Przejdź do "https://portal.azure.com", wyszukaj "Microsoft Foundry Project", w którym utworzyłeś agenta z kroku 11.2. Przejdź do "Microsoft Foundry Project", a następnie kliknij "JSON View" w prawym górnym rogu i zanotuj "agentIdentityId".
2. Innym sposobem na wyszukanie "agentIdentityId" jest skorzystanie z portalu "https://entra.microsoft.com/" w zakładce "Agent ID". W zakładce "All agent identities" wyszukaj tożsamość z nazwą Twojego zasobu "Microsoft Foundry project" z dopiskiem AgentIdentity, np. "Aaifblamis01-aifblamis01-project01-AgentIdentity".
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

## 12 Integracja z bazą wiedzy

### 12.1 Konfiguracja Azure Database for PostgreSQL flexible server

1. Jeśli nie masz jeszcze zasobu Azure Database for PostgreSQL flexible server, utwórz go:
    - Wyszukaj "Azure Database for PostgreSQL flexible server" w Azure Portal
    - Kliknij "+ Create"
    - Wypełnij formularz i utwórz zasób (Uwaga! Authentication method: PostgreSQL and Microsoft Entra authentication. Utwórz użytkownika i zapisz jego hasło.)
2. Po utworzeniu zasobu, otwórz go w portalu.
3. Przejdź do opcji "Settings" -> "Server parameters".
4. Na zakładce "All", dla parametru "azure.extensions" wybierz: AZURE_AI, PG_DISKANN oraz VECTOR.
5. Upewnij się czy w opcji "Settings" -> "Networking" jest ustawiona reguła firewall dopuszczająca ruch z Twojego adresu IP - niezbędne dla uzyskania połączenia z bazą w następnym kroku.
6. Skorzystaj z Visual Studio Code z rozszerzeniem PostgreSQL lub pgAdmin (https://www.pgadmin.org/download/) aby uzyskać połączenie z bazą. Parametry połączenia: adres serwera, nazwa bazy, użytkownik i hasło dostępne są w widoku zasobu w portalu.


### 12.2 Zasilenie danymi, embedding, zakładanie indeksu DiskANN

1. Skorzystaj z domyślnej bazy "postgres".
2. W schemacie "public" utwórz nową tabelę "policies" korzystając z poniższego skryptu.

```sql
DROP TABLE IF EXISTS policies;

CREATE TABLE IF NOT EXISTS policies (
    polisa_id    TEXT PRIMARY KEY,
    rodzaj_polisy TEXT NOT NULL,
    pakiet       TEXT,
    cena         NUMERIC(10,2) NOT NULL,
    opis         TEXT
);
```

3. Zasil nowo utworzoną tabelę danymi:

```sql
INSERT INTO policies (polisa_id, rodzaj_polisy, pakiet, cena, opis)
VALUES
  ('123456', 'zdrowotna', 'premium', 100, 'Ubezpieczenie zdrowotne premium.'),
  ('123457', 'samochodowa', 'standard', 75, 'Podstawowe ubezpieczenie samochodu.'),
  ('123458', 'turystyczna', 'premium', 120, 'Kompleksowe ubezpieczenie podróżne z ochroną bagażu i assistance.'),
  ('123459', 'mieszkaniowa', 'standard', 90, 'Podstawowe ubezpieczenie mieszkania od zdarzeń losowych.'),
  ('123460', 'na życie', 'premium', 150, 'Ubezpieczenie na życie z wysoką sumą ubezpieczenia i dodatkowymi świadczeniami.'),
  ('123461', 'OC', 'standard', 60, 'Obowiązkowe ubezpieczenie odpowiedzialności cywilnej dla kierowców.'),
  ('123462', 'firmowa', 'premium', 200, 'Ubezpieczenie dla przedsiębiorstw obejmujące mienie i odpowiedzialność cywilną.'),
  ('123463', 'rowerowa', 'standard', 40, 'Ubezpieczenie roweru od kradzieży i uszkodzeń.')
  ;
```

4. Włącz rozszerzenia AZURE_AI, PG_DISKANN oraz VECTOR:

```sql
CREATE EXTENSION IF NOT EXISTS azure_ai;
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_diskann;
```

5. Skonfiguruj parametry połączenia z OpenAI. Będziemy wykorzystywać model do tworzenia embedding-ów (Uwaga! Upewnij się, że masz w Microsoft Foundry wdrożony model "text-embedding-ada-002"):

```sql
 SELECT azure_ai.set_setting('azure_openai.auth_type', 'managed-identity');
SELECT azure_ai.set_setting('azure_openai.endpoint', '<endpoint>');
```

6. W tabeli "policies" dodaj kolumnę "embedding" typu wektorowego:

```sql
ALTER TABLE policies ADD COLUMN embedding vector(1536);
```

7. Zbuduj embeddingi dla danych w tabeli "policies":

```sql
WITH po AS (
    SELECT po.polisa_id
    FROM
        policies po
    WHERE
        po.embedding is null
        LIMIT 500 --limit aby nie przekroczyć limitu requestów; jeśli jest więcej niż 500 rekordów, kod wykonujemy kilkukrotnie
)
UPDATE
    policies p
SET
    embedding = azure_openai.create_embeddings('text-embedding-ada-002', p.rodzaj_polisy||' '||p.pakiet||' '||p.cena||' '||p.opis)
FROM
    po
WHERE
    p.polisa_id = po.polisa_id;
```

8. Zbuduj indeks DiskANN na tabeli "policies":

```sql
CREATE INDEX ON policies USING diskann (embedding vector_cosine_ops);
```

9. Przetestuj działanie wyszukiwania wektorowego:

```sql
SELECT
    p.*
FROM
    policies p
ORDER BY
    p.embedding <#> azure_openai.create_embeddings('text-embedding-ada-002', 'Polisa samochodowa')::vector
LIMIT 1;
```

### 12.3 Tworzenie interfejsu obsługi zapytań z wyszukiwaniem wektorowym (vector search) w Azure Function

1. Jeśli nie masz jeszcze zasobu Azure Function, utwórz go:
    - Wyszukaj "Azure Function" w Azure Portal
    - Kliknij "+ Create"
    - Wypełnij formularz i utwórz zasób (Runtime: Python)
2. Korzystając z rozszerzenia Azure Functions w Visual Studio Code utwórz nowy projekt (HTTP Triggered).
3. W razie potrzeby skorzystaj z kodu funkcji dołączonego do repozytorium.
4. Zdefiniuj funkcję realizującą połączenie z bazą danych:

```python
def _get_db_conn():
    """Create and return a new psycopg2 connection using env vars."""
    return psycopg2.connect(
        host=os.getenv("PG_HOST"),
        port=int(os.getenv("PG_PORT", "5432")),
        dbname=os.getenv("PG_DATABASE"),
        user=os.getenv("PG_USER"),
        password=os.getenv("PG_PASSWORD"),
    )
```

5. Zdefiniuj funkcję realizującą wyszukiwanie wektorowe:

```python
def vector_search(
    query: str,
    table: str = "policies",
    id_column: str = "polisa_id",
    content_column: str = "opis",
) -> List[Dict]:
    """Perform a vector similarity search against an Azure PostgreSQL DB with `pgvector`.

    - `query`: text to search for. 
    - Returns a list of dicts with `id`, `content`.
    """
    conn = _get_db_conn()
    try:
        with conn.cursor() as cur:
            q = sql.SQL(
                "SELECT {id_col}, {content_col} "
                "FROM {table} "
                "ORDER BY embedding <#> azure_openai.create_embeddings('text-embedding-ada-002', {query})::vector "
                "LIMIT 1"
            ).format(
                id_col=sql.Identifier(id_column),
                content_col=sql.Identifier(content_column),
                query=sql.Literal(query),
                table=sql.Identifier(table),
            )

            cur.execute(q)
            rows = cur.fetchall()

            results = []
            for r in rows:
                results.append({"id": r[0], "content": r[1]})

            return results
    finally:
        conn.close()
```

6. Oraz obsługę żądania HTTP:

```python
@app.route(route="get_policies", methods=("GET","POST"))
def get_policies(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')

    try:
        params = req.get_json()
    except Exception:
        params = {}

    query = req.params.get("q") or req.params.get("query") or params.get("q") or params.get("query")
    if not query:
        return func.HttpResponse("Missing 'query' parameter", status_code=400)
    
    try:
        results = vector_search(query)
    except Exception as e:
        logging.exception("vector_search failed")
        return func.HttpResponse(str(e), status_code=500)

    return func.HttpResponse(json.dumps(results), mimetype="application/json", status_code=200)
```

7. Zwróć uwagę na wymagane moduły:

```python
azure-functions
psycopg2-binary
```

8. Wykonaj deploy kodu do zasobu Azure Function.
9. Znajdź i otwórz w portalu zasób Azure Function.
10. W opcji "Settings" -> "Environment variables", na zakładce "App settings" stwórz ustawienia:
    - PG_HOST
    - PG_PORT (domyślnie 5432)
    - PG_DATABASE
    - PG_USER
    - PG_PASSWORD

11. Przetestuj działanie funkcji w "Overview" -> "Functions" -> (nazwa funkcji) -> "Code+Test" -> opcja "Test/Run". Podaj parametr żądania "query" wpisując np. "polisa samochodowa". Wykonanie powinno zwrócić wynik oraz rezultat HTTP 200.

### 12.4 Tworzenie API

Wykonaj analogicznie jak w punktach 1.4, 1.5, wskazując endpoint utworzonej funkcji.

### 12.5 Udostępnianie API jako MCP

Wykonaj analogicznie jak w sekcji 11.

## 13 [zadania dodatkowe - poza APIM] Data Agent w Microsoft Fabric

### 13.1 Konfiguracja Microsoft Fabric

1. Jeśli nie masz jeszcze zasobu Microsoft Fabric (Fabric Capacity), utwórz go:
    - Wyszukaj "Microsoft Fabric" w Azure Portal
    - Kliknij "+ Create"
    - Wypełnij formularz i utwórz zasób (SKU: F2)
2. Przejdź do strony zasobu w portalu. Jeśli Capacity jest wyłączone, kliknij "Resume".
3. Przejdź do Microsoft Fabric w oddzielnej zakładce przeglądarki (https://app.fabric.microsoft.com/).
4. Utwórz nowy obszar roboczy (workspace) "Workspaces" -> "New workspace". W zakładce "Advanced" wybierz "Fabric capacity".

### 13.2 Konfiguracja Mirroringu Azure Database for PostgreSQL <-> Microsoft Fabric

1. Przejdź do strony zasobu Azure Database for PostgreSQL.
2. Przejdź do zakładki "Fabric mirroring" kliknij "Get started".
3. Z listy dostępnych baz danych wybierz "postgres" a dalej kliknij "Prepare".
4. Zasób zmieni konfigurację aby uruchomić możliwość mirroringu do Microsoft Fabric. W tym czasie serwer może się zrestartować. Po zakończeniu procesu w zakładce "Fabric mirroring" widoczna będzie informacja "Server readiness": "Server is ready for mirroring".
5. Przejdź do Microsoft Fabric, do utworzonego obszaru roboczego.
6. Kliknij "New item" i z listy obiektów wybierz "Mirrored Azure Database for PostgreSQL (preview)".
7. W kolejnym oknie dialogowym kliknij nazwę konektora "Azure Database for PostgreSQL".
8. Podaj parametry połączenia.
9. W oknie dialogowym "Choose data" wybierz tabelę ("public.policies") do replikacji. Zignoruj ostrzeżenia o niekompatybilnym typie wektorowym.
10. Kliknij "Connect", a następnie nazwij nowy obiekt. Kliknij "Create mirrored database".
11. Po chwili utworzony zostanie obiekt typu "Mirrored database". Otwórz go i zweryfikuj czy replikacja działa poprawnie (status zsynchronizowanych rekordów).

### 13.3 Tworzenie Data Agent w Microsoft Fabric

1. W obszarze roboczym kliknij "New item" i wybierz "Data agent (preview)". Podaj nazwę obiektu, kliknij "Create".
2. W oknie dialogowym agenta, w zakładce "Explorer" kliknij "+ Data source" i wybierz utworzoną "Mirrored database". Kliknij "Add".
3. W zakładce "Explorer" zaznacz tabelę "policies" jako źródło danych dla agenta.
4. Kliknij opcję "Agent instructions".
5. W nowym oknie podaj instrukcje dla agenta (Markdown):

```txt

# Microsoft Fabric Data Agent – Insurance Advisor (Instructions)

## 0) Agent Role & Objective
You are the “Insurance Advisor” for our organization. 
Your job is to: (a) understand a customer’s profile and needs; (b) search governed policy data; 
(c) recommend one or more suitable policies with clear reasoning; (d) return a concise, structured answer that an advisor can share with a customer.

Always respect security trimming and only query data sources the end user is permitted to access.

---

## 1) Data Sources & Preferred Routing
Use these data sources in order of preference:

1. Table `policies`:
   - Use for raw policy metadata.

---

## 2) Canonical Schema Notes (for NL→SQL)
- `policies(polisa_id, rodzaj_polisy, pakiet, cena, opis)`
- `premium_rates(rodzaj_polisy, pakiet)`
- `eligibility_rules(rodzaj_polisy)`

Use exact column names; prefer filters on `rodzaj_polisy` and `pakiet`. 
When joining, key is `rodzaj_polisy` (and `pakiet` where applicable).

---

## 3) Business Rules for Recommendations
Apply these rules before proposing results:

A. Eligibility (hard filters)
- Health (“zdrowotna”): age ≥ 18; if pre‑existing conditions flagged, include riders in coverage_options.
- Auto (“samochodowa”): requires `requires_vehicle = true`; check region_allow.
- Travel (“turystyczna”): if travel_frequency ≥ 2 trips/quarter → prefer “premium” pack; else “standard”.
- Home (“mieszkaniowa”): requires property ownership; exclude high‑risk flood zones unless add‑on available.
- Life (“życie”): age ≤ 70 for standard; >70 → show “senior” variants if present.


---

## 4) Output Format (strict)
Return **only** the following JSON block in a fenced code block, plus a one‑paragraph summary above it:

Summary: 1–2 sentences explaining why the top policy is a fit, in plain language.
```
```json
{
  "top_recommendation": {
    "polisa_id": "<string>",
    "rodzaj_polisy": "<string>",
    "pakiet": "<string>"
  },
  "alternatives": [
    { "polisa_id":"...", "pakiet":"..." },
    { "polisa_id":"...", "pakiet":"..." }
  ],
  
}
```

6. Przetestuj działanie agenta w oknie "Test the agent’s responses" np. "szukam polisy samochodowej".
7. Opublikuj agenta klikając "Publish".

### 13.4 Udostępnianie Data Agent jako MCP dla Microsoft Foundry

1. W Microsoft Foundry portal (https://ai.azure.com) w New Foundry, utwórz nowego agenta klikając "Start building" -> "Create agent".
2. Nadaj nazwę np. "agent-polis".
3. W zakładce "Tools" kliknij "Add" a następnie "Add a new tool".
4. Wybierz "Fabric Data Agent" a następnie "Add Tool".
5. W oknie dialogowym konfiguracji połączenia podaj Workspace ID oraz Artifact ID, dostępne do odczytania w Microsoft Fabric w pasku adresu na stronie z utworzonym Data Agent: https://app.fabric.microsoft.com/groups/<workspace-id>/aiskills/<artifact-id>?experience=fabric-developer
6. Kliknij "Connect".
7. W oknie "Instructions" podaj instrukcje dla agenta:

```txt
You are the “Insurance Advisor” for our organization. 
Your job is to: (a) understand a customer’s profile and needs; (b) search governed policy data; 
(c) recommend one or more suitable policies with clear reasoning; (d) return a concise, structured answer that an advisor can share with a customer. Make sure that you always use the tools to provide policy data.
```

8. Zapisz zmiany i przetestuj działanie agenta. W oknie czatu w "Debug" powinno być widoczne odwołanie do Tool Fabric Data Agent.

## Podsumowanie

Gratulacje! Stworzyłeś kompletny interfejs API za pomocą Azure API Management, który:

- Dostarcza informacje o polisach ubezpieczeniowych
- Integruje się z Azure OpenAI Service
- Jest zabezpieczony przez klucze API i OAuth 2.0
- Kontroluje ruch za pomocą limitów wywołań
- Limituje tokeny dla zapytań AI
- Transformuje i anonimizuje dane
- Integruje się z bazą wiedzy w Azure Database for PostgreSQL i korzysta z vector search
- Jest monitorowany w Application Insights

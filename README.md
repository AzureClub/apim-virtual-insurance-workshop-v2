<div align="center">
  <img src="Logo-Azure-Club.png" alt="Azure Club Logo" width="200"/>
  
  # 🚀 Warsztat: Wirtualny Doradca Ubezpieczeniowy
  
  ### Budowa inteligentnego asystenta dla branży ubezpieczeniowej z wykorzystaniem Azure API Management i Azure AI
  
  ![Azure](https://img.shields.io/badge/Azure-0078D4?style=for-the-badge&logo=microsoft-azure&logoColor=white)
  ![API Management](https://img.shields.io/badge/API_Management-0078D4?style=for-the-badge&logo=microsoft-azure&logoColor=white)
  ![Azure AI](https://img.shields.io/badge/Azure_AI-0078D4?style=for-the-badge&logo=microsoft-azure&logoColor=white)
  ![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)
  
</div>

---

## 📋 O warsztacie

Ten warsztat prowadzi uczestników przez proces tworzenia zaawansowanego interfejsu API dla **wirtualnego doradcy ubezpieczeniowego** z obsługą wielokanałową. Projekt wykorzystuje najnowsze technologie Microsoft Azure do budowy inteligentnego systemu, który może odpowiadać na pytania klientów dotyczące polis ubezpieczeniowych w czasie rzeczywistym.

### 🎯 Cele warsztatu

- ✅ Stworzenie i zarządzanie API za pomocą **Azure API Management**
- ✅ Integracja z **Azure AI Foundry** (GPT-4o-mini) dla generatywnych odpowiedzi
- ✅ Implementacja **vector search** w PostgreSQL dla semantycznego wyszukiwania
- ✅ Konfiguracja **OAuth 2.0** i zabezpieczenia API
- ✅ Budowa **Smart Load Balancing** między wieloma regionami Azure AI
- ✅ Monitorowanie i diagnostyka z **Application Insights** i **Log Analytics**
- ✅ Integracja z **Logic Apps** dla orkiestracji przepływów pracy

---

## 🛠️ Technologie

| Technologia | Przeznaczenie |
|------------|---------------|
| **Azure API Management** | Zarządzanie, zabezpieczanie i monitorowanie API |
| **Azure AI Foundry** | Modele GPT dla generatywnych odpowiedzi |
| **Azure Database for PostgreSQL** | Baza danych z vector search (pgvector) |
| **Azure Functions** | Serverless compute dla wyszukiwania semantycznego |
| **Azure Logic Apps** | Orkiestracja przepływów pracy i integracje |
| **Application Insights** | Monitorowanie i telemetria aplikacji |
| **Log Analytics** | Centralizacja i analiza logów |
| **Microsoft Entra ID** | Uwierzytelnianie i autoryzacja (OAuth 2.0) |
| **Microsoft Fabric** | Analityka i raportowanie danych |

---

## 📚 Struktura repozytorium

```
apim-virtual-insurance-workshop-v2/
│
├── 📄 apim-virtual-insurance-workshop-pl.md   # Główny materiał warsztatowy (instrukcje krok po kroku)
├── 📄 naming-conventions.md                    # Konwencje nazewnictwa zasobów Azure
├── 📄 README.md                                # Ten plik
├── 🖼️ Logo-Azure-Club.png                      # Logo Azure Club
│
└── 📁 function/                                # Azure Function - Vector Search
    ├── function_app.py                         # Główna logika funkcji
    ├── host.json                               # Konfiguracja Azure Functions
    └── requirements.txt                        # Zależności Python
```

---

## 🚀 Szybki start

### Wymagania wstępne

Przed rozpoczęciem warsztatu upewnij się, że posiadasz:

- ✅ **Aktywną subskrypcję Azure** (lub darmowe środki)
- ✅ **Azure AI Foundry** z modelem GPT-4o-mini
- ✅ **Azure Log Analytics** (wdrożona usługa)
- ✅ **Application Insights** (wdrożona usługa)
- ✅ Zainstalowane narzędzia:
  - [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) (wersja 2.40.0+)
  - [Visual Studio Code](https://code.visualstudio.com/)
  - [Postman](https://www.postman.com/) lub inny klient REST (opcjonalnie)
- ✅ Podstawową znajomość REST API, HTTP i JSON

### 📖 Materiały warsztatowe

👉 **[Przejdź do pełnych materiałów warsztatowych](apim-virtual-insurance-workshop-pl.md)**

Materiał obejmuje 12 głównych sekcji:

1. **Tworzenie pierwszego API** - Baza wiedzy o polisach
2. **Integracja z Azure AI Foundry** - Dodanie chatbota GPT
3. **Implementacja OAuth 2.0** - Zabezpieczenie dostępu
4. **Orkiestracja z Logic Apps** - Przepływy pracy
5. **Vector Search w PostgreSQL** - Semantyczne wyszukiwanie
6. **Konfiguracja Microsoft Fabric** - Analityka danych
7. **Smart Load Balancing** - Multi-region failover
8. **Monitorowanie i diagnostyka** - Application Insights
9. **Testowanie i walidacja** - PowerShell scripts
10. **Best practices** - Produkcyjna gotowość

---

## 🎓 Dla kogo jest ten warsztat?

- 👨‍💻 **Deweloperzy** zainteresowani integracją AI z aplikacjami biznesowymi
- 🏗️ **Solution Architects** projektujący systemy oparte na Azure
- 🔧 **DevOps Engineers** zarządzający infrastrukturą chmurową
- 📊 **Data Engineers** pracujący z vector databases i AI
- 💼 **IT Professionals** z sektora ubezpieczeniowego i FinTech

---

## 🗂️ Konwencje nazewnictwa

Repozytorium zawiera szczegółowe konwencje nazewnictwa dla wszystkich zasobów Azure:

👉 **[Sprawdź konwencje nazewnictwa](naming-conventions.md)**

Przykładowa struktura dla użytkownika **05**:

```
rg-azureclubworkshopint-05                    # Resource Group
apim-azureclubworkshopint-05                  # API Management
aoai-azureclubworkshopint-05-01               # Azure AI (Primary)
aoai-azureclubworkshopint-05-02               # Azure AI (Secondary)
psql-azureclubworkshopint-05                  # PostgreSQL
func-azureclubworkshopint-05                  # Function App
la-azureclubworkshopint-05                    # Logic App
```

---

## 🧩 Architektura rozwiązania

```
┌─────────────┐
│   Klient    │
│  (Postman)  │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────────────┐
│     Azure API Management (APIM)             │
│  ┌─────────────────────────────────────┐   │
│  │  PolisyAPI (GET /polisy)            │   │
│  │  ChatAPI (POST /chat)               │   │
│  │  OAuth 2.0 Security                 │   │
│  │  Smart Load Balancing               │   │
│  └─────────────────────────────────────┘   │
└──┬──────────────────┬──────────────────┬───┘
   │                  │                  │
   ▼                  ▼                  ▼
┌─────────┐    ┌─────────────┐   ┌──────────────┐
│ Logic   │    │  Azure AI   │   │  PostgreSQL  │
│  Apps   │    │  Foundry    │   │ + pgvector   │
└─────────┘    │  (GPT-4o)   │   └──────┬───────┘
               └─────────────┘          │
                                        ▼
                                  ┌─────────────┐
                                  │   Azure     │
                                  │  Functions  │
                                  └─────────────┘
```

---

## 🔐 Bezpieczeństwo

Warsztat implementuje następujące mechanizmy bezpieczeństwa:

- 🔑 **OAuth 2.0** - Client Credentials Flow
- 🛡️ **Managed Identity** - Bezpieczny dostęp do zasobów Azure
- 🔐 **API Keys & Secrets** - Azure Key Vault integration
- 🌐 **Virtual Network** - Izolacja sieciowa APIM
- 📊 **Rate Limiting** - Ochrona przed nadużyciami

---

## 📊 Funkcjonalności

### ✨ Główne features

- **Semantic Search** - Vector search w PostgreSQL (pgvector) dla inteligentnego wyszukiwania polis
- **RAG Pattern** - Retrieval-Augmented Generation dla precyzyjnych odpowiedzi
- **Multi-Region AI** - Smart load balancing między France Central i Sweden Central
- **Real-time Chat** - Interaktywny chatbot z pamięcią kontekstu
- **Policy Management** - CRUD operations dla polis ubezpieczeniowych
- **Advanced Analytics** - Integration z Microsoft Fabric
- **Comprehensive Monitoring** - Application Insights + Log Analytics

---

## 🤝 Wsparcie i community

- 📧 Pytania? Otwórz [Issue](https://github.com/AzureClub/apim-virtual-insurance-workshop-v2/issues)
---

## 📄 Licencja

Ten projekt jest udostępniany na licencji MIT. Zobacz plik `LICENSE` dla szczegółów.

---

## 🙏 Podziękowania

Materiały warsztatowe przygotowane przez **Azure Club** dla społeczności polskich deweloperów i architektów chmurowych.

---

<div align="center">
  
### ⭐ Jeśli ten warsztat był pomocny, zostaw gwiazdkę!

**Zbudowano z ❤️ przez [Azure Club]**

</div>
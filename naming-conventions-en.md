# 📋 Report: Azure Resource Naming Conventions for the Workshop

**🌍 Language / Język:** [English](naming-conventions-en.md) EN | [Polski](naming-conventions.md) PL

---

## Base Parameters

| Parameter | Default Value | Description |
|----------|------------------|------|
| `$Prefix` | `azureclubworkshopint` | Main prefix for all resources |
| `$Location` | `swedencentral` | Primary location (for AI Foundry Secondary) |
| `$SecondaryLocation` | `francecentral` | Secondary location (for AI Foundry Primary) |
| `$UserNumber` | `01`, `02`, `03`, ... | User number (2-digit with leading zero) |

---

## Resource Naming Patterns

| Resource Type | Pattern | Example (user 05) |
|------------|---------|----------------------|
| **Resource Group** | `rg-{prefix}-{usernumber}` | `rg-azureclubworkshopint-05` |
| **API Management** | `apim-{prefix}-{usernumber}` | `apim-azureclubworkshopint-05` |
| **Azure AI Foundry (Primary)** | `aoai-{prefix}-{usernumber}-01` | `aoai-azureclubworkshopint-05-01` |
| **Azure AI Foundry (Secondary)** | `aoai-{prefix}-{usernumber}-02` | `aoai-azureclubworkshopint-05-02` |
| **Log Analytics** | `log-{prefix}-{usernumber}` | `log-azureclubworkshopint-05` |
| **Application Insights** | `appi-{prefix}-{usernumber}` | `appi-azureclubworkshopint-05` |
| **Virtual Network** | `vnet-{prefix}-{usernumber}` | `vnet-azureclubworkshopint-05` |
| **Logic App** | `la-{prefix}-{usernumber}` | `la-azureclubworkshopint-05` |
| **App Registration** | `PolisyAPI-OAuth-{usernumber}` | `PolisyAPI-OAuth-05` |
| **PostgreSQL** | `psql-{prefix}-{usernumber}` | `psql-azureclubworkshopint-05` |
| **Fabric Capacity** | `fc{prefix}{usernumber}` (no hyphens) | `fcazureclubworkshopint05` |
| **Function App** | `func-{prefix}-{usernumber}` | `func-azureclubworkshopint-05` |
| **Storage Account** | `st{prefix}{usernumber}` (no hyphens, max 24 chars) | `stazureclubworkshopint05` |

---

## Azure Prefixes by Resource Type

| Prefix | Resource Type |
|--------|------------|
| `rg-` | Resource Group |
| `apim-` | API Management |
| `aoai-` | Azure OpenAI / AI Foundry |
| `log-` | Log Analytics Workspace |
| `appi-` | Application Insights |
| `vnet-` | Virtual Network |
| `la-` | Logic App |
| `psql-` | PostgreSQL Flexible Server |
| `fc` | Fabric Capacity |
| `func-` | Azure Function App |
| `st` | Storage Account |

---

## Resource Locations

| Resource | Location |
|-------|-------------|
| Resource Group | `swedencentral` |
| APIM | `swedencentral` |
| AI Foundry Primary (`-01`) | `francecentral` |
| AI Foundry Secondary (`-02`) | `swedencentral` |
| Log Analytics | `swedencentral` |
| Application Insights | `swedencentral` |

---

## Complete Example for User 01

```
rg-azureclubworkshopint-01              (Resource Group)
├── apim-azureclubworkshopint-01        (API Management)
├── aoai-azureclubworkshopint-01-01     (Azure AI Foundry Primary - France Central)
├── aoai-azureclubworkshopint-01-02     (Azure AI Foundry Secondary - Sweden Central)
├── log-azureclubworkshopint-01         (Log Analytics)
├── appi-azureclubworkshopint-01        (Application Insights)
├── vnet-azureclubworkshopint-01        (Virtual Network)
├── psql-azureclubworkshopint-01        (PostgreSQL)
├── func-azureclubworkshopint-01        (Function App)
└── stazureclubworkshopint01            (Storage Account)
```

---

## Service URLs

| Service | URL Pattern |
|--------|-------------|
| **APIM Gateway** | `https://apim-{prefix}-{usernumber}.azure-api.net/` |
| **AI Foundry Primary** | `https://aoai-{prefix}-{usernumber}-01.cognitiveservices.azure.com/` |
| **AI Foundry Secondary** | `https://aoai-{prefix}-{usernumber}-02.cognitiveservices.azure.com/` |
| **PostgreSQL** | `psql-{prefix}-{usernumber}.postgres.database.azure.com` |

---

## Source

Report generated based on the script `scripts/provision-workshop.ps1`.

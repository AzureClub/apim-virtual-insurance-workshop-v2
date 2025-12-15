# ============================================================
# Skrypt do generowania informacji dla uczestników warsztatu
# ============================================================
#
# Użycie:
#   ./generate-team-info.ps1 -TeamCount 2
#
# Output:
#   - Plik CSV z danymi dostępowymi
#   - Plik MD z instrukcjami per zespół
#
# ============================================================

param(
    [Parameter(Mandatory=$false)]
    [int]$TeamCount = 2,
    
    [Parameter(Mandatory=$false)]
    [string]$Prefix = "azureclubworkshopint",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputDir = ".\output"
)

# ============================================================
# Konfiguracja
# ============================================================

$ErrorActionPreference = "Stop"

function Write-Info { param($Message) Write-Host "[INFO] $Message" -ForegroundColor Cyan }
function Write-Success { param($Message) Write-Host "[OK] $Message" -ForegroundColor Green }

function Get-TeamNumber {
    param([int]$Number)
    return $Number.ToString("D2")
}

function Get-ResourceNames {
    param([string]$TeamId)
    
    return @{
        ResourceGroup    = "rg-$Prefix-$TeamId"
        APIM            = "apim-$Prefix-$TeamId"
        OpenAIPrimary   = "aoai-$Prefix-$TeamId-01"
        OpenAISecondary = "aoai-$Prefix-$TeamId-02"
        LogAnalytics    = "log-$Prefix-$TeamId"
        AppInsights     = "appi-$Prefix-$TeamId"
        VNet            = "vnet-$Prefix-$TeamId"
        LogicApp        = "la-$Prefix-$TeamId"
    }
}

# ============================================================
# Sprawdzenie Azure CLI
# ============================================================

Write-Info "Sprawdzanie Azure CLI..."
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Error "Nie jesteś zalogowany do Azure. Uruchom 'az login'"
    exit 1
}
Write-Success "Zalogowano jako: $($account.user.name)"

# Utwórz folder output
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

# ============================================================
# Generowanie danych
# ============================================================

$teamData = @()

for ($i = 1; $i -le $TeamCount; $i++) {
    $teamId = Get-TeamNumber -Number $i
    $names = Get-ResourceNames -TeamId $teamId
    
    Write-Info "Pobieranie danych dla zespołu $teamId..."
    
    $team = @{
        TeamId = $teamId
        ResourceGroup = $names.ResourceGroup
        APIM = $names.APIM
        APIMEndpoint = ""
        OpenAIPrimaryEndpoint = ""
        OpenAISecondaryEndpoint = ""
        SubscriptionKey = ""
    }
    
    # Pobierz endpoint APIM
    try {
        $apimGateway = az apim show `
            --name $names.APIM `
            --resource-group $names.ResourceGroup `
            --query gatewayUrl -o tsv 2>$null
        $team.APIMEndpoint = $apimGateway
    }
    catch {
        $team.APIMEndpoint = "https://$($names.APIM).azure-api.net"
    }
    
    # Pobierz endpoint OpenAI Primary
    try {
        $openaiPrimaryEndpoint = az cognitiveservices account show `
            --name $names.OpenAIPrimary `
            --resource-group $names.ResourceGroup `
            --query properties.endpoint -o tsv 2>$null
        $team.OpenAIPrimaryEndpoint = $openaiPrimaryEndpoint
    }
    catch {
        $team.OpenAIPrimaryEndpoint = "https://$($names.OpenAIPrimary).openai.azure.com/"
    }
    
    # Pobierz endpoint OpenAI Secondary
    try {
        $openaiSecondaryEndpoint = az cognitiveservices account show `
            --name $names.OpenAISecondary `
            --resource-group $names.ResourceGroup `
            --query properties.endpoint -o tsv 2>$null
        $team.OpenAISecondaryEndpoint = $openaiSecondaryEndpoint
    }
    catch {
        $team.OpenAISecondaryEndpoint = "https://$($names.OpenAISecondary).openai.azure.com/"
    }
    
    $teamData += $team
}

# ============================================================
# Generowanie pliku CSV
# ============================================================

$csvPath = Join-Path $OutputDir "teams-info.csv"
Write-Info "Generowanie pliku CSV: $csvPath"

$csvContent = "TeamId,ResourceGroup,APIM,APIMEndpoint,OpenAIPrimaryEndpoint,OpenAISecondaryEndpoint`n"
foreach ($team in $teamData) {
    $csvContent += "$($team.TeamId),$($team.ResourceGroup),$($team.APIM),$($team.APIMEndpoint),$($team.OpenAIPrimaryEndpoint),$($team.OpenAISecondaryEndpoint)`n"
}
$csvContent | Out-File -FilePath $csvPath -Encoding UTF8

Write-Success "Plik CSV wygenerowany"

# ============================================================
# Generowanie pliku MD z instrukcjami per zespół
# ============================================================

$mdPath = Join-Path $OutputDir "teams-instructions.md"
Write-Info "Generowanie pliku MD: $mdPath"

$mdContent = @"
# Ściągawka - dane dostępowe dla zespołów warsztatowych

**APIM Virtual Insurance Workshop**

Data wygenerowania: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

> 📋 Ten dokument zawiera wszystkie nazwy zasobów i endpointy potrzebne podczas warsztatu.
> Znajdź sekcję dla Twojego numeru zespołu i używaj podanych wartości.

---

"@

foreach ($team in $teamData) {
    $mdContent += @"

## 🎯 Zespół $($team.TeamId)

### Twoje zasoby Azure

| Zasób | Nazwa | Endpoint/URL |
|-------|-------|--------------|
| **Resource Group** | ``$($team.ResourceGroup)`` | - |
| **API Management** | ``$($team.APIM)`` | ``$($team.APIMEndpoint)`` |
| **Azure AI Foundry Primary** | ``aoai-$Prefix-$($team.TeamId)-01`` | ``$($team.OpenAIPrimaryEndpoint)`` |
| **Azure AI Foundry Secondary** | ``aoai-$Prefix-$($team.TeamId)-02`` | ``$($team.OpenAISecondaryEndpoint)`` |
| **Log Analytics** | ``log-$Prefix-$($team.TeamId)`` | - |
| **Application Insights** | ``appi-$Prefix-$($team.TeamId)`` | - |

### Zasoby do utworzenia samodzielnie

| Zasób | Nazwa do użycia | Zadanie |
|-------|-----------------|---------|
| **Logic App** | ``la-$Prefix-$($team.TeamId)`` | Zadanie 5 |
| **App Registration** | ``PolisyAPI-OAuth-$($team.TeamId)`` | Zadanie 5 |

### 📋 Kopiuj-wklej dla zadań

**Zadanie 2 & 6 - Azure AI Foundry endpoint (Primary):**
``````
$($team.OpenAIPrimaryEndpoint)
``````

**Zadanie 11 - Smart Load Balancing (URL-e dla polityki XML):**

Zastąp w polityce APIM:
``````csharp
// Primary backend - Priority 1
{ "url", "$($team.OpenAIPrimaryEndpoint)" },

// Secondary backend - Priority 2 (fallback)
{ "url", "$($team.OpenAISecondaryEndpoint)" },
``````

**Model deployment name:**
``````
gpt-4o-mini
``````

**API version:**
``````
2024-05-01-preview
``````

---

"@
}

$mdContent += @"

## Informacje wspólne dla wszystkich zespołów

### Regiony
- **Primary resources**: France Central
- **Secondary OpenAI**: Sweden Central

### Ważne linki
- Azure Portal: https://portal.azure.com
- Azure AI Foundry: https://ai.azure.com

### Wsparcie
W razie problemów zgłoś się do organizatorów warsztatu.

"@

$mdContent | Out-File -FilePath $mdPath -Encoding UTF8

Write-Success "Plik MD wygenerowany"

# ============================================================
# Podsumowanie
# ============================================================

Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "         GENEROWANIE ZAKOŃCZONE" -ForegroundColor Magenta
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Info "Wygenerowane pliki:"
Write-Host "  - $csvPath"
Write-Host "  - $mdPath"
Write-Host ""

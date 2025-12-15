# ============================================================
# Skrypt do pre-provisioningu zasobów Azure dla warsztatu APIM
# ============================================================
# 
# Użycie:
#   # Wywołanie 1: Team 01-18 (Sweden Central + East US)
#   ./provision-workshop.ps1 -StartTeam 1 -EndTeam 18 -Location "swedencentral" -SecondaryLocation "eastus"
#
#   # Wywołanie 2: Team 19-35 (France Central + East US 2)
#   ./provision-workshop.ps1 -StartTeam 19 -EndTeam 35 -Location "francecentral" -SecondaryLocation "eastus2"
#
# Wymagania:
#   - Azure CLI zainstalowane i zalogowane (az login)
#   - Uprawnienia do tworzenia zasobów w subskrypcji
#   - Uprawnienia do Entra ID (dla App Registration)
#
# ============================================================

param(
    [Parameter(Mandatory=$false)]
    [int]$StartTeam = 1,
    
    [Parameter(Mandatory=$false)]
    [int]$EndTeam = 2,
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "swedencentral",
    
    [Parameter(Mandatory=$false)]
    [string]$SecondaryLocation = "francecentral",
    
    [Parameter(Mandatory=$false)]
    [string]$Prefix = "azureclubworkshopint",
    
    [Parameter(Mandatory=$false)]
    [string]$OpenAIModel = "gpt-4o-mini",
    
    [Parameter(Mandatory=$false)]
    [string]$OpenAIModelVersion = "2024-07-18",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipAPIM = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipOpenAI = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipPostgreSQL = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipFabric = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipFunction = $false,
    
    [Parameter(Mandatory=$false)]
    [string]$PostgreSQLAdminUser = "workshopadmin",
    
    [Parameter(Mandatory=$false)]
    [string]$PostgreSQLAdminPassword = "W0rksh0p!2025#Secure",
    
    [Parameter(Mandatory=$false)]
    [switch]$WhatIf = $false
)

# ============================================================
# Konfiguracja
# ============================================================

$ErrorActionPreference = "Stop"

# Kolory dla output
function Write-Info { param($Message) Write-Host "[INFO] $Message" -ForegroundColor Cyan }
function Write-Success { param($Message) Write-Host "[OK] $Message" -ForegroundColor Green }
function Write-Warning { param($Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }

# ============================================================
# Funkcje pomocnicze
# ============================================================

function Get-TeamNumber {
    param([int]$Number)
    return $Number.ToString("D2")
}

function Get-ResourceNames {
    param([string]$TeamId)
    
    return @{
        ResourceGroup       = "rg-$Prefix-$TeamId"
        APIM               = "apim-$Prefix-$TeamId"
        OpenAIPrimary      = "aoai-$Prefix-$TeamId-01"
        OpenAISecondary    = "aoai-$Prefix-$TeamId-02"
        LogAnalytics       = "log-$Prefix-$TeamId"
        AppInsights        = "appi-$Prefix-$TeamId"
        VNet               = "vnet-$Prefix-$TeamId"
        LogicApp           = "la-$Prefix-$TeamId"
        AppRegistration    = "PolisyAPI-OAuth-$TeamId"
        PostgreSQL         = "psql-$Prefix-$TeamId"
        FabricCapacity     = "fc$($Prefix)$($TeamId)".Replace("-", "")
        FunctionApp        = "func-$Prefix-$TeamId"
        StorageAccount     = "st${Prefix}${TeamId}".Replace("-", "").Substring(0, [Math]::Min(24, "st${Prefix}${TeamId}".Replace("-", "").Length))
    }
}

function Test-ResourceExists {
    param(
        [string]$ResourceType,
        [string]$ResourceName,
        [string]$ResourceGroup = $null
    )
    
    try {
        switch ($ResourceType) {
            "group" {
                $result = az group exists --name $ResourceName 2>$null
                return $result -eq "true"
            }
            "apim" {
                $result = az apim show --name $ResourceName --resource-group $ResourceGroup 2>$null
                return $null -ne $result
            }
            "cognitiveservices" {
                $result = az cognitiveservices account show --name $ResourceName --resource-group $ResourceGroup 2>$null
                return $null -ne $result
            }
            "loganalytics" {
                $result = az monitor log-analytics workspace show --workspace-name $ResourceName --resource-group $ResourceGroup 2>$null
                return $null -ne $result
            }
            "appinsights" {
                $result = az monitor app-insights component show --app $ResourceName --resource-group $ResourceGroup 2>$null
                return $null -ne $result
            }
            "vnet" {
                $result = az network vnet show --name $ResourceName --resource-group $ResourceGroup 2>$null
                return $null -ne $result
            }
            default {
                return $false
            }
        }
    }
    catch {
        return $false
    }
}

# ============================================================
# Walidacja
# ============================================================

Write-Info "Sprawdzanie Azure CLI..."
$azVersion = az version 2>$null | ConvertFrom-Json
if (-not $azVersion) {
    Write-Error "Azure CLI nie jest zainstalowane lub nie jest w PATH"
    exit 1
}
Write-Success "Azure CLI version: $($azVersion.'azure-cli')"

Write-Info "Sprawdzanie logowania do Azure..."
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Error "Nie jesteś zalogowany do Azure. Uruchom 'az login'"
    exit 1
}
Write-Success "Zalogowano jako: $($account.user.name)"
Write-Info "Subskrypcja: $($account.name) ($($account.id))"

# ============================================================
# Podsumowanie
# ============================================================

Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "         WORKSHOP PROVISIONING - PODSUMOWANIE" -ForegroundColor Magenta
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Info "Zakres zespołów: $StartTeam - $EndTeam (łącznie: $($EndTeam - $StartTeam + 1))"
Write-Info "Lokalizacja Primary: $Location"
Write-Info "Lokalizacja Secondary: $SecondaryLocation"
Write-Info "Prefix: $Prefix"
Write-Info "Model AI Foundry: $OpenAIModel ($OpenAIModelVersion)"
Write-Info "Pomiń APIM: $SkipAPIM"
Write-Info "Pomiń AI Foundry: $SkipOpenAI"
Write-Info "Pomiń PostgreSQL: $SkipPostgreSQL"
Write-Info "Pomiń Fabric: $SkipFabric"
Write-Info "Pomiń Function: $SkipFunction"
Write-Host ""

if ($WhatIf) {
    Write-Warning "Tryb WhatIf - żadne zasoby nie zostaną utworzone"
    Write-Host ""
}

# Wyświetl zasoby które będą utworzone
Write-Host "Zasoby do utworzenia per zespół:" -ForegroundColor Yellow
for ($i = $StartTeam; $i -le $EndTeam; $i++) {
    $teamId = Get-TeamNumber -Number $i
    $names = Get-ResourceNames -TeamId $teamId
    
    Write-Host ""
    Write-Host "  Zespół ${teamId}:" -ForegroundColor Cyan
    Write-Host "    - Resource Group:      $($names.ResourceGroup)"
    Write-Host "    - Log Analytics:       $($names.LogAnalytics)"
    Write-Host "    - Application Insights: $($names.AppInsights)"
    Write-Host "    - Virtual Network:     $($names.VNet)"
    if (-not $SkipOpenAI) {
        Write-Host "    - Azure AI Foundry (1): $($names.OpenAIPrimary) [$Location]"
        Write-Host "    - Azure AI Foundry (2): $($names.OpenAISecondary) [$SecondaryLocation]"
    }
    if (-not $SkipAPIM) {
        Write-Host "    - API Management:      $($names.APIM)"
    }
    if (-not $SkipPostgreSQL) {
        Write-Host "    - PostgreSQL:          $($names.PostgreSQL) [B1ms]"
    }
    if (-not $SkipFabric) {
        Write-Host "    - Fabric Capacity:     $($names.FabricCapacity) [F2]"
    }
    if (-not $SkipFunction) {
        Write-Host "    - Azure Function:      $($names.FunctionApp) [Flex Consumption]"
    }
}

Write-Host ""
if (-not $WhatIf) {
    $confirm = Read-Host "Czy kontynuować? (y/N)"
    if ($confirm -ne "y" -and $confirm -ne "Y") {
        Write-Warning "Anulowano"
        exit 0
    }
}

# ============================================================
# Provisioning
# ============================================================

$startTime = Get-Date
$results = @()

for ($i = $StartTeam; $i -le $EndTeam; $i++) {
    $teamId = Get-TeamNumber -Number $i
    $names = Get-ResourceNames -TeamId $teamId
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  ZESPÓŁ $teamId" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    
    $teamResult = @{
        TeamId = $teamId
        Resources = @{}
        Errors = @()
    }
    
    # --- Resource Group ---
    Write-Info "Tworzenie Resource Group: $($names.ResourceGroup)..."
    if (-not $WhatIf) {
        if (Test-ResourceExists -ResourceType "group" -ResourceName $names.ResourceGroup) {
            Write-Warning "Resource Group już istnieje, pomijam"
        }
        else {
            try {
                az group create --name $names.ResourceGroup --location $Location --tags "SecurityControl=Ignore" --output none
                Write-Success "Resource Group utworzona"
            }
            catch {
                Write-Error "Błąd: $_"
                $teamResult.Errors += "ResourceGroup: $_"
            }
        }
    }
    $teamResult.Resources["ResourceGroup"] = $names.ResourceGroup
    
    # --- Log Analytics Workspace ---
    Write-Info "Tworzenie Log Analytics Workspace: $($names.LogAnalytics)..."
    if (-not $WhatIf) {
        if (Test-ResourceExists -ResourceType "loganalytics" -ResourceName $names.LogAnalytics -ResourceGroup $names.ResourceGroup) {
            Write-Warning "Log Analytics już istnieje, pomijam"
        }
        else {
            try {
                az monitor log-analytics workspace create `
                    --resource-group $names.ResourceGroup `
                    --workspace-name $names.LogAnalytics `
                    --location $Location `
                    --retention-time 30 `
                    --tags "SecurityControl=Ignore" `
                    --output none
                Write-Success "Log Analytics Workspace utworzony"
            }
            catch {
                Write-Error "Błąd: $_"
                $teamResult.Errors += "LogAnalytics: $_"
            }
        }
    }
    $teamResult.Resources["LogAnalytics"] = $names.LogAnalytics
    
    # --- Application Insights ---
    Write-Info "Tworzenie Application Insights: $($names.AppInsights)..."
    if (-not $WhatIf) {
        if (Test-ResourceExists -ResourceType "appinsights" -ResourceName $names.AppInsights -ResourceGroup $names.ResourceGroup) {
            Write-Warning "Application Insights już istnieje, pomijam"
        }
        else {
            try {
                $logAnalyticsId = az monitor log-analytics workspace show `
                    --resource-group $names.ResourceGroup `
                    --workspace-name $names.LogAnalytics `
                    --query id -o tsv
                
                az monitor app-insights component create `
                    --app $names.AppInsights `
                    --location $Location `
                    --resource-group $names.ResourceGroup `
                    --workspace $logAnalyticsId `
                    --tags "SecurityControl=Ignore" `
                    --output none
                Write-Success "Application Insights utworzony"
            }
            catch {
                Write-Error "Błąd: $_"
                $teamResult.Errors += "AppInsights: $_"
            }
        }
    }
    $teamResult.Resources["AppInsights"] = $names.AppInsights
    
    # --- Virtual Network ---
    Write-Info "Tworzenie Virtual Network: $($names.VNet)..."
    if (-not $WhatIf) {
        if (Test-ResourceExists -ResourceType "vnet" -ResourceName $names.VNet -ResourceGroup $names.ResourceGroup) {
            Write-Warning "Virtual Network już istnieje, pomijam"
        }
        else {
            try {
                $addressPrefix = "10.$i.0.0/16"
                $subnetPrefix = "10.$i.1.0/24"
                
                az network vnet create `
                    --resource-group $names.ResourceGroup `
                    --name $names.VNet `
                    --address-prefix $addressPrefix `
                    --subnet-name "snet-apim" `
                    --subnet-prefix $subnetPrefix `
                    --tags "SecurityControl=Ignore" `
                    --output none
                Write-Success "Virtual Network utworzony ($addressPrefix)"
            }
            catch {
                Write-Error "Błąd: $_"
                $teamResult.Errors += "VNet: $_"
            }
        }
    }
    $teamResult.Resources["VNet"] = $names.VNet
    
    # --- Azure AI Foundry (Primary) ---
    if (-not $SkipOpenAI) {
        Write-Info "Tworzenie Azure AI Foundry Resource (Primary): $($names.OpenAIPrimary)..."
        if (-not $WhatIf) {
            if (Test-ResourceExists -ResourceType "cognitiveservices" -ResourceName $names.OpenAIPrimary -ResourceGroup $names.ResourceGroup) {
                Write-Warning "Azure AI Foundry Primary już istnieje, pomijam"
            }
            else {
                try {
                    az cognitiveservices account create `
                        --name $names.OpenAIPrimary `
                        --resource-group $names.ResourceGroup `
                        --location $Location `
                        --kind AIServices `
                        --sku S0 `
                        --custom-domain $names.OpenAIPrimary `
                        --tags "SecurityControl=Ignore" `
                        --output none
                    Write-Success "Azure AI Foundry Resource Primary utworzony"
                    
                    # Deploy model
                    Write-Info "  Wdrażanie modelu $OpenAIModel..."
                    az cognitiveservices account deployment create `
                        --name $names.OpenAIPrimary `
                        --resource-group $names.ResourceGroup `
                        --deployment-name $OpenAIModel `
                        --model-name $OpenAIModel `
                        --model-version $OpenAIModelVersion `
                        --model-format OpenAI `
                        --sku-capacity 10 `
                        --sku-name GlobalStandard `
                        --output none
                    Write-Success "  Model $OpenAIModel wdrożony"
                }
                catch {
                    Write-Error "Błąd: $_"
                    $teamResult.Errors += "OpenAIPrimary: $_"
                }
            }
        }
        $teamResult.Resources["OpenAIPrimary"] = $names.OpenAIPrimary
        
        # --- Azure AI Foundry (Secondary) ---
        Write-Info "Tworzenie Azure AI Foundry Resource (Secondary): $($names.OpenAISecondary)..."
        if (-not $WhatIf) {
            if (Test-ResourceExists -ResourceType "cognitiveservices" -ResourceName $names.OpenAISecondary -ResourceGroup $names.ResourceGroup) {
                Write-Warning "Azure AI Foundry Secondary już istnieje, pomijam"
            }
            else {
                try {
                    az cognitiveservices account create `
                        --name $names.OpenAISecondary `
                        --resource-group $names.ResourceGroup `
                        --location $SecondaryLocation `
                        --kind AIServices `
                        --sku S0 `
                        --custom-domain $names.OpenAISecondary `
                        --tags "SecurityControl=Ignore" `
                        --output none
                    Write-Success "Azure AI Foundry Resource Secondary utworzony"
                    
                    # Deploy model
                    Write-Info "  Wdrażanie modelu $OpenAIModel..."
                    az cognitiveservices account deployment create `
                        --name $names.OpenAISecondary `
                        --resource-group $names.ResourceGroup `
                        --deployment-name $OpenAIModel `
                        --model-name $OpenAIModel `
                        --model-version $OpenAIModelVersion `
                        --model-format OpenAI `
                        --sku-capacity 10 `
                        --sku-name GlobalStandard `
                        --output none
                    Write-Success "  Model $OpenAIModel wdrożony"
                }
                catch {
                    Write-Error "Błąd: $_"
                    $teamResult.Errors += "OpenAISecondary: $_"
                }
            }
        }
        $teamResult.Resources["OpenAISecondary"] = $names.OpenAISecondary
    }
    
    # --- Azure Database for PostgreSQL Flexible Server ---
    if (-not $SkipPostgreSQL) {
        Write-Info "Tworzenie PostgreSQL Flexible Server: $($names.PostgreSQL)..."
        if (-not $WhatIf) {
            $pgExists = az postgres flexible-server show `
                --name $names.PostgreSQL `
                --resource-group $names.ResourceGroup 2>$null
            
            if ($pgExists) {
                Write-Warning "PostgreSQL już istnieje, pomijam"
            }
            else {
                try {
                    az postgres flexible-server create `
                        --name $names.PostgreSQL `
                        --resource-group $names.ResourceGroup `
                        --location $Location `
                        --admin-user $PostgreSQLAdminUser `
                        --admin-password $PostgreSQLAdminPassword `
                        --sku-name Standard_B1ms `
                        --tier Burstable `
                        --storage-size 32 `
                        --version 17 `
                        --public-access 0.0.0.0-255.255.255.255 `
                        --tags "SecurityControl=Ignore" `
                        --output none
                    Write-Success "PostgreSQL Flexible Server utworzony"
                    Write-Info "  Admin: $PostgreSQLAdminUser"
                    Write-Info "  Endpoint: $($names.PostgreSQL).postgres.database.azure.com"
                }
                catch {
                    Write-Error "Błąd: $_"
                    $teamResult.Errors += "PostgreSQL: $_"
                }
            }
        }
        $teamResult.Resources["PostgreSQL"] = $names.PostgreSQL
    }
    
    # --- Microsoft Fabric Capacity ---
    if (-not $SkipFabric) {
        Write-Info "Tworzenie Fabric Capacity: $($names.FabricCapacity)..."
        if (-not $WhatIf) {
            $fabricExists = az fabric capacity show `
                --capacity-name $names.FabricCapacity `
                --resource-group $names.ResourceGroup 2>$null
            
            if ($fabricExists) {
                Write-Warning "Fabric Capacity już istnieje, pomijam"
            }
            else {
                try {
                    # Pobierz email aktualnego użytkownika dla admina
                    $currentUserEmail = az ad signed-in-user show --query userPrincipalName -o tsv 2>$null
                    
                    az fabric capacity create `
                        --capacity-name $names.FabricCapacity `
                        --resource-group $names.ResourceGroup `
                        --location $Location `
                        --sku "{name:F2,tier:Fabric}" `
                        --administration "{members:[$currentUserEmail]}" `
                        --tags "SecurityControl=Ignore" `
                        --output none
                    
                    Write-Success "Fabric Capacity F2 utworzony"
                }
                catch {
                    Write-Error "Błąd: $_"
                    $teamResult.Errors += "FabricCapacity: $_"
                }
            }
        }
        $teamResult.Resources["FabricCapacity"] = $names.FabricCapacity
    }
    
    # --- Azure Function (Flex Consumption) ---
    if (-not $SkipFunction) {
        Write-Info "Tworzenie Azure Function (Flex Consumption): $($names.FunctionApp)..."
        if (-not $WhatIf) {
            $funcExists = az functionapp show `
                --name $names.FunctionApp `
                --resource-group $names.ResourceGroup 2>$null
            
            if ($funcExists) {
                Write-Warning "Azure Function już istnieje, pomijam"
            }
            else {
                try {
                    # Tworzenie Storage Account dla Function App
                    Write-Info "  Tworzenie Storage Account: $($names.StorageAccount)..."
                    az storage account create `
                        --name $names.StorageAccount `
                        --resource-group $names.ResourceGroup `
                        --location $Location `
                        --sku Standard_LRS `
                        --tags "SecurityControl=Ignore" `
                        --output none
                    Write-Success "  Storage Account utworzony"
                    
                    # Tworzenie Function App z Flex Consumption
                    Write-Info "  Tworzenie Function App..."
                    az functionapp create `
                        --name $names.FunctionApp `
                        --resource-group $names.ResourceGroup `
                        --storage-account $names.StorageAccount `
                        --flexconsumption-location $Location `
                        --runtime dotnet-isolated `
                        --runtime-version 8.0 `
                        --tags "SecurityControl=Ignore" `
                        --output none
                    Write-Success "Azure Function (Flex Consumption) utworzony"
                }
                catch {
                    Write-Error "Błąd: $_"
                    $teamResult.Errors += "FunctionApp: $_"
                }
            }
        }
        $teamResult.Resources["FunctionApp"] = $names.FunctionApp
    }
    
    # --- API Management ---
    if (-not $SkipAPIM) {
        Write-Info "Tworzenie API Management: $($names.APIM)..."
        Write-Warning "  UWAGA: Tworzenie APIM trwa 30-40 minut!"
        if (-not $WhatIf) {
            if (Test-ResourceExists -ResourceType "apim" -ResourceName $names.APIM -ResourceGroup $names.ResourceGroup) {
                Write-Warning "API Management już istnieje, pomijam"
            }
            else {
                try {
                    az apim create `
                        --name $names.APIM `
                        --resource-group $names.ResourceGroup `
                        --location $Location `
                        --publisher-email "blamis@microsoft.com" `
                        --publisher-name "Workshop" `
                        --sku-name Developer `
                        --enable-managed-identity $true `
                        --tags "SecurityControl=Ignore" `
                        --no-wait `
                        --output none
                    Write-Success "API Management utworzenie rozpoczęte (async)"
                }
                catch {
                    Write-Error "Błąd: $_"
                    $teamResult.Errors += "APIM: $_"
                }
            }
        }
        $teamResult.Resources["APIM"] = $names.APIM
    }
    
    $results += $teamResult
}

# ============================================================
# Podsumowanie
# ============================================================

$endTime = Get-Date
$duration = $endTime - $startTime

Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "         PROVISIONING ZAKOŃCZONY" -ForegroundColor Magenta
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Info "Czas wykonania: $($duration.ToString('hh\:mm\:ss'))"
Write-Host ""

# Wyświetl wyniki
$hasErrors = $false
foreach ($result in $results) {
    if ($result.Errors.Count -gt 0) {
        $hasErrors = $true
        Write-Host "Zespół $($result.TeamId): " -NoNewline
        Write-Host "BŁĘDY" -ForegroundColor Red
        foreach ($error in $result.Errors) {
            Write-Host "  - $error" -ForegroundColor Red
        }
    }
    else {
        Write-Host "Zespół $($result.TeamId): " -NoNewline
        Write-Host "OK" -ForegroundColor Green
    }
}

if (-not $SkipAPIM) {
    Write-Host ""
    Write-Warning "UWAGA: API Management jest tworzony asynchronicznie."
    Write-Warning "Sprawdź status w Azure Portal lub użyj:"
    Write-Host ""
    for ($i = $StartTeam; $i -le $EndTeam; $i++) {
        $teamId = Get-TeamNumber -Number $i
        $names = Get-ResourceNames -TeamId $teamId
        Write-Host "  az apim show --name $($names.APIM) --resource-group $($names.ResourceGroup) --query provisioningState -o tsv"
    }
}

Write-Host ""
Write-Info "Następne kroki:"
Write-Host "  1. Poczekaj na zakończenie tworzenia APIM (~30-40 min)"
Write-Host "  2. Uruchom skrypt assign-rbac.ps1 aby nadać uprawnienia"
Write-Host "  3. Wygeneruj dane dostępowe dla uczestników"
Write-Host ""

if ($hasErrors) {
    exit 1
}
exit 0

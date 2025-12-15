# ============================================================
# Skrypt do nadawania uprawnień RBAC dla zespołów warsztatowych
# ============================================================
#
# Użycie:
#   # Wywołanie 1: Team 01-18
#   ./assign-rbac.ps1 -StartTeam 1 -EndTeam 18 -UserDomain "MngEnvMCAP263417.onmicrosoft.com"
#
#   # Wywołanie 2: Team 19-35
#   ./assign-rbac.ps1 -StartTeam 19 -EndTeam 35 -UserDomain "MngEnvMCAP263417.onmicrosoft.com"
#
# Wymagania:
#   - Azure CLI zainstalowane i zalogowane (az login)
#   - Uprawnienia Owner na subskrypcji lub Resource Group
#
# ============================================================

param(
    [Parameter(Mandatory=$false)]
    [int]$StartTeam = 1,
    
    [Parameter(Mandatory=$false)]
    [int]$EndTeam = 2,
    
    [Parameter(Mandatory=$false)]
    [string]$UserDomain = "MngEnvMCAP263417.onmicrosoft.com",
    
    [Parameter(Mandatory=$false)]
    [string]$Prefix = "azureclubworkshopint",
    
    [Parameter(Mandatory=$false)]
    [switch]$WhatIf = $false
)

# ============================================================
# Konfiguracja
# ============================================================

$ErrorActionPreference = "Stop"

function Write-Info { param($Message) Write-Host "[INFO] $Message" -ForegroundColor Cyan }
function Write-Success { param($Message) Write-Host "[OK] $Message" -ForegroundColor Green }
function Write-Warning { param($Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }

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
    }
}

# ============================================================
# Walidacja
# ============================================================

Write-Info "Sprawdzanie Azure CLI..."
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Error "Nie jesteś zalogowany do Azure. Uruchom 'az login'"
    exit 1
}
Write-Success "Zalogowano jako: $($account.user.name)"

# Generuj użytkowników na podstawie wzorca int-user-{numer}@{domain}
$users = @{}
Write-Info "Generowanie użytkowników dla zakresu $StartTeam - $EndTeam..."
for ($i = $StartTeam; $i -le $EndTeam; $i++) {
    $teamId = Get-TeamNumber -Number $i
    $userPrincipal = "int-user-$teamId@$UserDomain"
    $users[$teamId] = $userPrincipal
}
Write-Success "Wygenerowano $($users.Count) użytkowników (int-user-XX@$UserDomain)"

# ============================================================
# Podsumowanie
# ============================================================

Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "         RBAC ASSIGNMENT - PODSUMOWANIE" -ForegroundColor Magenta
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""

if ($WhatIf) {
    Write-Warning "Tryb WhatIf - żadne uprawnienia nie zostaną nadane"
}

# ============================================================
# Nadawanie uprawnień
# ============================================================

for ($i = $StartTeam; $i -le $EndTeam; $i++) {
    $teamId = Get-TeamNumber -Number $i
    $names = Get-ResourceNames -TeamId $teamId
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  ZESPÓŁ $teamId" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    
    # Sprawdź czy Resource Group istnieje
    $rgExists = az group exists --name $names.ResourceGroup 2>$null
    if ($rgExists -ne "true") {
        Write-Warning "Resource Group $($names.ResourceGroup) nie istnieje, pomijam"
        continue
    }
    
    # --- Uprawnienia dla użytkownika ---
    if ($users.ContainsKey($teamId)) {
        $userPrincipal = $users[$teamId]
        Write-Info "Nadawanie uprawnień dla użytkownika: $userPrincipal"
        
        # Owner na Resource Group (pozwala nadawać RBAC - potrzebne do zadania 11.4)
        Write-Info "  Owner na Resource Group..."
        if (-not $WhatIf) {
            try {
                az role assignment create `
                    --assignee $userPrincipal `
                    --role "Owner" `
                    --scope "/subscriptions/$($account.id)/resourceGroups/$($names.ResourceGroup)" `
                    --output none 2>$null
                Write-Success "  Owner nadany"
            }
            catch {
                Write-Warning "  Contributor już istnieje lub błąd: $_"
            }
        }
        
        # Cognitive Services OpenAI Contributor na AI Foundry Primary
        Write-Info "  Cognitive Services OpenAI Contributor na AI Foundry Primary..."
        if (-not $WhatIf) {
            try {
                $openaiPrimaryId = az cognitiveservices account show `
                    --name $names.OpenAIPrimary `
                    --resource-group $names.ResourceGroup `
                    --query id -o tsv 2>$null
                
                if ($openaiPrimaryId) {
                    az role assignment create `
                        --assignee $userPrincipal `
                        --role "Cognitive Services OpenAI Contributor" `
                        --scope $openaiPrimaryId `
                        --output none 2>$null
                    Write-Success "  AI Foundry Contributor (Primary) nadany"
                }
                else {
                    Write-Warning "  AI Foundry Primary nie istnieje"
                }
            }
            catch {
                Write-Warning "  Błąd lub już istnieje: $_"
            }
        }
        
        # Cognitive Services OpenAI Contributor na AI Foundry Secondary
        Write-Info "  Cognitive Services OpenAI Contributor na AI Foundry Secondary..."
        if (-not $WhatIf) {
            try {
                $openaiSecondaryId = az cognitiveservices account show `
                    --name $names.OpenAISecondary `
                    --resource-group $names.ResourceGroup `
                    --query id -o tsv 2>$null
                
                if ($openaiSecondaryId) {
                    az role assignment create `
                        --assignee $userPrincipal `
                        --role "Cognitive Services OpenAI Contributor" `
                        --scope $openaiSecondaryId `
                        --output none 2>$null
                    Write-Success "  AI Foundry Contributor (Secondary) nadany"
                }
                else {
                    Write-Warning "  AI Foundry Secondary nie istnieje"
                }
            }
            catch {
                Write-Warning "  Błąd lub już istnieje: $_"
            }
        }
    }
    
    # --- Uprawnienia dla Managed Identity APIM ---
    Write-Info "Nadawanie uprawnień dla Managed Identity APIM..."
    if (-not $WhatIf) {
        try {
            # Pobierz Principal ID Managed Identity APIM
            $apimPrincipalId = az apim show `
                --name $names.APIM `
                --resource-group $names.ResourceGroup `
                --query identity.principalId -o tsv 2>$null
            
            if (-not $apimPrincipalId) {
                Write-Warning "  APIM nie istnieje lub nie ma Managed Identity"
                continue
            }
            
            Write-Info "  APIM Principal ID: $apimPrincipalId"
            
            # Cognitive Services OpenAI User na AI Foundry Primary
            Write-Info "  Cognitive Services OpenAI User (APIM -> AI Foundry Primary)..."
            $openaiPrimaryId = az cognitiveservices account show `
                --name $names.OpenAIPrimary `
                --resource-group $names.ResourceGroup `
                --query id -o tsv 2>$null
            
            if ($openaiPrimaryId) {
                az role assignment create `
                    --assignee-object-id $apimPrincipalId `
                    --assignee-principal-type ServicePrincipal `
                    --role "Cognitive Services OpenAI User" `
                    --scope $openaiPrimaryId `
                    --output none 2>$null
                Write-Success "  APIM -> AI Foundry Primary: OK"
            }
            
            # Cognitive Services OpenAI User na AI Foundry Secondary
            Write-Info "  Cognitive Services OpenAI User (APIM -> AI Foundry Secondary)..."
            $openaiSecondaryId = az cognitiveservices account show `
                --name $names.OpenAISecondary `
                --resource-group $names.ResourceGroup `
                --query id -o tsv 2>$null
            
            if ($openaiSecondaryId) {
                az role assignment create `
                    --assignee-object-id $apimPrincipalId `
                    --assignee-principal-type ServicePrincipal `
                    --role "Cognitive Services OpenAI User" `
                    --scope $openaiSecondaryId `
                    --output none 2>$null
                Write-Success "  APIM -> AI Foundry Secondary: OK"
            }
        }
        catch {
            Write-Error "  Błąd nadawania uprawnień APIM: $_"
        }
    }
    
    # --- Konfiguracja diagnostyki APIM do Log Analytics ---
    Write-Info "Konfiguracja diagnostyki APIM (Gateway Logs)..."
    if (-not $WhatIf) {
        try {
            $apimId = az apim show `
                --name $names.APIM `
                --resource-group $names.ResourceGroup `
                --query id -o tsv 2>$null
            
            $logAnalyticsId = az monitor log-analytics workspace show `
                --workspace-name "log-$Prefix-$teamId" `
                --resource-group $names.ResourceGroup `
                --query id -o tsv 2>$null
            
            if ($apimId -and $logAnalyticsId) {
                # Sprawdź czy diagnostic setting już istnieje
                $existingDiag = az monitor diagnostic-settings list `
                    --resource $apimId `
                    --query "[?name=='apim-gateway-logs'].name" -o tsv 2>$null
                
                if ($existingDiag) {
                    Write-Warning "  Diagnostic setting już istnieje, pomijam"
                }
                else {
                    # Utwórz diagnostic setting z Gateway Logs (Resource-specific mode)
                    # Resource-specific tworzy dedykowaną tabelę ApiManagementGatewayLogs
                    az monitor diagnostic-settings create `
                        --name "apim-gateway-logs" `
                        --resource $apimId `
                        --workspace $logAnalyticsId `
                        --logs '[{"category":"GatewayLogs","enabled":true,"retentionPolicy":{"enabled":false,"days":0}}]' `
                        --export-to-resource-specific true `
                        --output none
                    Write-Success "  APIM Gateway Logs -> Log Analytics (Resource-specific): OK"
                }
            }
            else {
                Write-Warning "  APIM lub Log Analytics nie istnieje"
            }
        }
        catch {
            Write-Warning "  Błąd konfiguracji diagnostyki: $_"
        }
    }
}

# ============================================================
# Nadawanie Cognitive Services Usages Reader na subskrypcji
# (wymagane do podglądu quota w AI Foundry portal)
# ============================================================

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  COGNITIVE SERVICES USAGES READER (poziom subskrypcji)" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

if ($users.Count -gt 0) {
    foreach ($entry in $users.GetEnumerator()) {
        $userPrincipal = $entry.Value
        Write-Info "Nadawanie Cognitive Services Usages Reader dla: $userPrincipal"
        
        if (-not $WhatIf) {
            try {
                az role assignment create `
                    --assignee $userPrincipal `
                    --role "Cognitive Services Usages Reader" `
                    --scope "/subscriptions/$($account.id)" `
                    --output none 2>$null
                Write-Success "  Cognitive Services Usages Reader nadany"
            }
            catch {
                Write-Warning "  Rola już istnieje lub błąd: $_"
            }
        }
    }
}
else {
    Write-Warning "Brak użytkowników - pomiń nadawanie Cognitive Services Usages Reader"
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "         RBAC ASSIGNMENT ZAKOŃCZONY" -ForegroundColor Magenta
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""

<#
.SYNOPSIS
    Skrypt do testowania Smart Load Balancing w Azure API Management.

.DESCRIPTION
    Ten skrypt wysyła wiele równoległych requestów do API w APIM, 
    aby przetestować automatyczny failover między backendami Azure AI Foundry.
    
    Skrypt używa tokenu Azure AD (z Azure CLI) do autoryzacji - nie wymaga 
    klucza subskrypcji APIM.
    
    Wymagania:
    - Azure CLI zainstalowane i zalogowane (az login)
    - Dostęp do subskrypcji z zasobami warsztatu
    - Zmniejszony limit TPM na Primary OpenAI (1K) - instrukcja w zadaniu 10
    - Wyłączona opcja "Subscription required" w APIM dla API polisy-ai

.PARAMETER TeamNumber
    Numer Twojego zespołu (np. "01", "05", "12").

.PARAMETER RequestCount
    Liczba requestów do wysłania (domyślnie 20).

.PARAMETER Parallel
    Czy wysyłać requesty równolegle (domyślnie $true).
    Równoległe requesty szybciej wyczerpują limit TPM.

.EXAMPLE
    .\Test-SmartLoadBalancing.ps1 -TeamNumber "05"
    
.EXAMPLE
    .\Test-SmartLoadBalancing.ps1 -TeamNumber "05" -RequestCount 30 -Parallel $true

.NOTES
    Autor: Azure Club Workshop
    Wersja: 2.0 - bez subscription key, z tokenem Azure AD
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$TeamNumber,
    
    [Parameter(Mandatory=$false)]
    [int]$RequestCount = 20,
    
    [Parameter(Mandatory=$false)]
    [bool]$Parallel = $true
)

# ============================================
# KONFIGURACJA
# ============================================

$resourceGroup = "rg-azureclubworkshopint-$TeamNumber"
$apimName = "apim-azureclubworkshopint-$TeamNumber"
$apiId = "polisy-ai"

$apimGatewayUrl = "https://$apimName.azure-api.net"
$apiPath = "/polisy-ai/openai/deployments/gpt-4o-mini/chat/completions"
$apiVersion = "2024-05-01-preview"

$fullUrl = "$apimGatewayUrl$apiPath`?api-version=$apiVersion"

# Request body - dłuższy prompt zużywa więcej tokenów
$requestBody = @{
    messages = @(
        @{
            role = "user"
            content = "Write a detailed essay about the history of artificial intelligence, including key milestones, important researchers, and future predictions. Make it comprehensive."
        }
    )
    max_tokens = 500
} | ConvertTo-Json -Depth 10

# ============================================
# FUNKCJE POMOCNICZE
# ============================================

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Get-AzureADToken {
    Write-ColorOutput "`n[INFO] Pobieranie tokenu Azure AD z Azure CLI..." "Cyan"
    
    try {
        # Pobierz token dla Azure Cognitive Services (używany przez OpenAI)
        $token = az account get-access-token --resource https://cognitiveservices.azure.com --query accessToken -o tsv 2>$null
        
        if ($token) {
            Write-ColorOutput "[OK] Token Azure AD pobrany" "Green"
            return $token
        }
    } catch {}
    
    Write-ColorOutput "[ERROR] Nie udalo sie pobrac tokenu Azure AD" "Red"
    Write-ColorOutput "        Upewnij sie, ze jestes zalogowany: az login" "Yellow"
    return $null
}

function Send-TestRequest {
    param(
        [int]$RequestNumber,
        [string]$Url,
        [string]$Body,
        [string]$Token
    )
    
    try {
        # Używamy tokenu Bearer Azure AD - nie wymaga subscription key
        $response = Invoke-WebRequest -Uri $Url -Method POST -Headers @{
            "Content-Type" = "application/json"
            "Authorization" = "Bearer $Token"
        } -Body $Body -TimeoutSec 120
        
        $backend = $response.Headers['x-served-by']
        $retryCount = $response.Headers['x-retry-count']
        
        # Określ czy to Primary czy Secondary
        if ($backend -like "*-01.*") {
            $backendName = "PRIMARY"
            return @{
                Number = $RequestNumber
                Backend = $backendName
                RetryCount = $retryCount
                Status = "OK"
                FullUrl = $backend
            }
        } else {
            $backendName = "SECONDARY"
            return @{
                Number = $RequestNumber
                Backend = $backendName
                RetryCount = $retryCount
                Status = "OK"
                FullUrl = $backend
            }
        }
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        return @{
            Number = $RequestNumber
            Backend = "ERROR"
            RetryCount = $null
            Status = "ERROR $statusCode"
            FullUrl = $null
        }
    }
}

# ============================================
# GŁÓWNA LOGIKA
# ============================================

Clear-Host
Write-ColorOutput "╔════════════════════════════════════════════════════════════════╗" "Cyan"
Write-ColorOutput "║       SMART LOAD BALANCING TEST - Azure API Management         ║" "Cyan"
Write-ColorOutput "╚════════════════════════════════════════════════════════════════╝" "Cyan"

Write-ColorOutput "`n[CONFIG] Konfiguracja testu:" "Yellow"
Write-ColorOutput "  • Zespol:           $TeamNumber" "White"
Write-ColorOutput "  • APIM:             $apimName" "White"
Write-ColorOutput "  • Liczba requestow: $RequestCount" "White"
Write-ColorOutput "  • Tryb rownlegly:   $Parallel" "White"
Write-ColorOutput "  • URL:              $fullUrl" "Gray"

# Pobierz token Azure AD
$azureToken = Get-AzureADToken

if (-not $azureToken) {
    Write-ColorOutput "`n[ERROR] Nie mozna kontynuowac bez tokenu Azure AD!" "Red"
    Write-ColorOutput "Sprawdz czy:" "Yellow"
    Write-ColorOutput "  1. Jestes zalogowany do Azure CLI (az login)" "White"
    Write-ColorOutput "  2. Twoje konto ma uprawnienia do Cognitive Services" "White"
    exit 1
}

Write-ColorOutput "`n[INFO] Rozpoczynam test..." "Yellow"
Write-ColorOutput "       (to moze potrwac kilka minut)`n" "Gray"

$startTime = Get-Date

# Wysyłanie requestów
if ($Parallel) {
    Write-ColorOutput "[MODE] Wysylanie $RequestCount requestow ROWNOLEGLE..." "Magenta"
    
    $results = 1..$RequestCount | ForEach-Object -Parallel {
        $reqNum = $_
        
        try {
            # Używamy tokenu Bearer Azure AD - nie wymaga subscription key
            $response = Invoke-WebRequest -Uri $using:fullUrl -Method POST -Headers @{
                "Content-Type" = "application/json"
                "Authorization" = "Bearer $using:azureToken"
            } -Body $using:requestBody -TimeoutSec 120
            
            $backend = $response.Headers['x-served-by']
            $retryCount = $response.Headers['x-retry-count']
            
            if ($backend -like "*-01.*") {
                @{ Number = $reqNum; Backend = "PRIMARY"; RetryCount = $retryCount; Status = "OK"; FullUrl = $backend }
            } else {
                @{ Number = $reqNum; Backend = "SECONDARY"; RetryCount = $retryCount; Status = "OK"; FullUrl = $backend }
            }
        } catch {
            $statusCode = $_.Exception.Response.StatusCode.value__
            @{ Number = $reqNum; Backend = "ERROR"; RetryCount = $null; Status = "ERROR $statusCode"; FullUrl = $null }
        }
    } -ThrottleLimit $RequestCount
} else {
    Write-ColorOutput "[MODE] Wysylanie $RequestCount requestow SEKWENCYJNIE..." "Magenta"
    
    $results = @()
    for ($i = 1; $i -le $RequestCount; $i++) {
        $result = Send-TestRequest -RequestNumber $i -Url $fullUrl -Body $requestBody -Token $azureToken
        $results += $result
        
        # Progress indicator
        $pct = [math]::Round(($i / $RequestCount) * 100)
        Write-Progress -Activity "Wysylanie requestow" -Status "$i / $RequestCount ($pct%)" -PercentComplete $pct
    }
    Write-Progress -Activity "Wysylanie requestow" -Completed
}

$endTime = Get-Date
$duration = ($endTime - $startTime).TotalSeconds

# ============================================
# WYŚWIETLANIE WYNIKÓW
# ============================================

Write-ColorOutput "`n╔════════════════════════════════════════════════════════════════╗" "Cyan"
Write-ColorOutput "║                        WYNIKI TESTU                            ║" "Cyan"
Write-ColorOutput "╚════════════════════════════════════════════════════════════════╝" "Cyan"

Write-ColorOutput "`n[SZCZEGOLY] Wyniki per-request:" "Yellow"
Write-ColorOutput "─────────────────────────────────────────────────────────────────" "Gray"

$results | Sort-Object { $_.Number } | ForEach-Object {
    $num = $_.Number.ToString().PadLeft(2, ' ')
    $backend = $_.Backend.PadRight(10, ' ')
    $retry = if ($_.RetryCount) { "(retry: $($_.RetryCount))" } else { "" }
    
    switch ($_.Backend) {
        "PRIMARY"   { Write-ColorOutput "  Request $num`: $backend $retry" "Cyan" }
        "SECONDARY" { Write-ColorOutput "  Request $num`: $backend $retry  ← FAILOVER!" "Green" }
        "ERROR"     { Write-ColorOutput "  Request $num`: $backend $($_.Status)" "Red" }
    }
}

# Statystyki
$primaryCount = ($results | Where-Object { $_.Backend -eq "PRIMARY" }).Count
$secondaryCount = ($results | Where-Object { $_.Backend -eq "SECONDARY" }).Count
$errorCount = ($results | Where-Object { $_.Backend -eq "ERROR" }).Count
$retryCount = ($results | Where-Object { $_.RetryCount }).Count

Write-ColorOutput "`n─────────────────────────────────────────────────────────────────" "Gray"
Write-ColorOutput "[STATYSTYKI]" "Yellow"
Write-ColorOutput "─────────────────────────────────────────────────────────────────" "Gray"

Write-ColorOutput "  Czas trwania testu:     $([math]::Round($duration, 1)) sekund" "White"
Write-ColorOutput "  Laczna liczba requestow: $RequestCount" "White"
Write-ColorOutput "" "White"
Write-ColorOutput "  PRIMARY (Priority 1):   $primaryCount requestow" "Cyan"
Write-ColorOutput "  SECONDARY (Priority 2): $secondaryCount requestow" "Green"
Write-ColorOutput "  ERRORS:                 $errorCount requestow" "Red"
Write-ColorOutput "  Z automatycznym RETRY:  $retryCount requestow" "Magenta"

# Podsumowanie
Write-ColorOutput "`n─────────────────────────────────────────────────────────────────" "Gray"
Write-ColorOutput "[PODSUMOWANIE]" "Yellow"
Write-ColorOutput "─────────────────────────────────────────────────────────────────" "Gray"

if ($secondaryCount -gt 0 -and $retryCount -gt 0) {
    Write-ColorOutput "`n  ✅ SUKCES! Smart Load Balancing DZIALA POPRAWNIE!" "Green"
    Write-ColorOutput "" "White"
    Write-ColorOutput "  Co sie stalo:" "White"
    Write-ColorOutput "  • Primary backend osiagnal limit TPM (429)" "White"
    Write-ColorOutput "  • Polityka automatycznie wykonala RETRY do Secondary" "White"
    Write-ColorOutput "  • Klient otrzymal odpowiedz 200 OK (nie widzial bledu 429)" "White"
    Write-ColorOutput "" "White"
    Write-ColorOutput "  Header 'x-retry-count' pokazuje ile retry bylo potrzebnych." "Gray"
} elseif ($secondaryCount -gt 0) {
    Write-ColorOutput "`n  ⚠️  CZESCIOWY SUKCES - Failover wystapil, ale bez retry w tym samym uzyciu" "Yellow"
    Write-ColorOutput "  Circuit breaker przelaczy ruch w nastepnych requestach." "White"
} elseif ($errorCount -gt 0) {
    Write-ColorOutput "`n  ❌ BLEDY - Niektore requesty zakonczyly sie bledem" "Red"
    Write-ColorOutput "  Sprawdz:" "White"
    Write-ColorOutput "  • Czy APIM ma poprawna polityke Smart LB?" "White"
    Write-ColorOutput "  • Czy Managed Identity ma uprawnienia do obu OpenAI?" "White"
    Write-ColorOutput "  • Czy Secondary OpenAI ma wystarczajacy limit TPM?" "White"
} else {
    Write-ColorOutput "`n  ℹ️  WSZYSTKO NA PRIMARY - Limit TPM nie zostal osiagniety" "Cyan"
    Write-ColorOutput "" "White"
    Write-ColorOutput "  Aby wywolac failover:" "White"
    Write-ColorOutput "  • Zmniejsz limit TPM na Primary do 1K (1000)" "White"
    Write-ColorOutput "  • Uruchom test ponownie z wieksza liczba requestow" "White"
    Write-ColorOutput "  • Uzyj -RequestCount 30 lub wiecej" "White"
}

Write-ColorOutput "`n═════════════════════════════════════════════════════════════════" "Cyan"
Write-ColorOutput "                         KONIEC TESTU" "Cyan"
Write-ColorOutput "═════════════════════════════════════════════════════════════════`n" "Cyan"

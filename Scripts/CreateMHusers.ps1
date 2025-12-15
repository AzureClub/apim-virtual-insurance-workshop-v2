#requires -Version 7

param(
    [Parameter(Mandatory = $true)]
    [string]$UserNamePrefix,
    
    [Parameter(Mandatory = $true)]
    [int]$UserCount,
    
    [Parameter(Mandatory = $true)]
    [string]$GroupName,
    
    [Parameter(Mandatory = $true)]
    [SecureString]$Password
)

$RequiredModules = @(
    'Microsoft.Graph.Users',
    'Microsoft.Graph.Groups',
    'Microsoft.Graph.Identity.SignIns',
    'Microsoft.Graph.Identity.Governance',
    'ImportExcel'
)

foreach ($module in $RequiredModules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Install-PSResource -Name $module -TrustRepository
    }
    Import-Module $module -Force
}

# Remember to elevate via Privilege Identity Management (PIM) if needed before connecting, at least User Administrator and Group Administrator roles is required
$context = Get-MgContext
if (-not $context) {
    Connect-MgGraph -Scopes "User.ReadWrite.All","Group.ReadWrite.All","UserAuthenticationMethod.ReadWrite.All","RoleManagement.ReadWrite.Directory" -NoWelcome
}

Get-MgContext

# Lab users and group creation

# These variables should be changed as needed
$eventStartDate = (Get-Date).AddMinutes(15) # TAP start date - 15 minutes from now
# $eventEndDate not set - using default TAP policy (48h)

# Variables below does not need to be changed
$StartIndex = 0 # Starting index for user numbering
$ApplicationDeveloperRoleId = "cf1c38e5-3621-4004-a7cb-879624dced7c" # Application Developer role template ID
$PlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))
$UPNSuffix = '@' + ((Get-MgContext).Account -split "@")[1] # Get UPN suffix from the signed-in account (@xxx.onmicrosoft.com)
$GroupId = Get-MgGroup -Filter "DisplayName eq '$GroupName'" | Select-Object -ExpandProperty Id
if (-not $GroupId) {
    $GroupParams = @{
        DisplayName     = $GroupName
        MailEnabled     = $false
        MailNickname    = $GroupName
        SecurityEnabled = $true
    }

    $Group = New-MgGroup @GroupParams
    $GroupId = $Group.Id
}

foreach ($i in 1..$UserCount) {

    $UserNumber = $StartIndex+$i
    $UserName = "$UserNamePrefix{0:D2}" -f $UserNumber
    $UserPrincipalName = $UserName + $UPNSuffix
    
    # Check if user already exists
    $existingUser = Get-MgUser -Filter "UserPrincipalName eq '$UserPrincipalName'" -ErrorAction SilentlyContinue
    if ($existingUser) {
        Write-Host "User $UserPrincipalName already exists, skipping..." -ForegroundColor Yellow
        continue
    }
    
    $PasswordProfile = @{
        ForceChangePasswordNextSignIn = $false
        Password = $PlainPassword
    }

    $UserParams = @{
        AccountEnabled = $true
        DisplayName = $UserName
        MailNickname = $UserName
        UserPrincipalName = $UserPrincipalName
        PasswordProfile = $PasswordProfile
    }

    Write-Host "Creating user : $UserPrincipalName"

    try {
        $CreatedUser = New-MgUser @UserParams
    }
    catch {
        Write-Host "Error creating user $UserPrincipalName : $_" -ForegroundColor Red
        continue
    }

    # Add user to group
    $UserId = $CreatedUser.Id
    if (-not $UserId) {
        Write-Host "Error: User $UserPrincipalName was not created properly, skipping..." -ForegroundColor Red
        continue
    }
    
    try {
        New-MgGroupMember -GroupId $GroupId -DirectoryObjectId $UserId
    }
    catch {
        Write-Host "Error adding user $UserPrincipalName to group $GroupName : $_"
    }

    # Assign Application Developer role to user
    try {
        $RoleAssignmentParams = @{
            PrincipalId = $UserId
            RoleDefinitionId = $ApplicationDeveloperRoleId
            DirectoryScopeId = "/"
        }
        New-MgRoleManagementDirectoryRoleAssignment -BodyParameter $RoleAssignmentParams
        Write-Host "Assigned Application Developer role to user: $UserPrincipalName" -ForegroundColor Cyan
    }
    catch {
        Write-Host "Error assigning Application Developer role to user $UserPrincipalName : $_"
    }

}

# Configure Temporary Access Pass (TAP) for users
# Note: TAP requires Entra ID Premium P2 license
# https://learn.microsoft.com/en-us/entra/identity/authentication/howto-authentication-temporary-access-pass
$Users = Get-MgUser -Filter "startsWith(DisplayName,'$UserNamePrefix')" | Sort-Object DisplayName | Where-Object UserPrincipalName -like "*$UPNSuffix"

$TAPs = @()

foreach ($user in $Users) {
    $properties = @{}
    $properties.isUsableOnce = $false
    $properties.startDateTime = $eventStartDate
    # Using default TAP policy - no endDateTime specified
    $propertiesJSON = $properties | ConvertTo-Json

    Write-Host "Creating Temporary Access Pass for user: $($user.UserPrincipalName)" -ForegroundColor Green

    try {
        New-MgUserAuthenticationTemporaryAccessPassMethod -UserId $user.Id -BodyParameter $propertiesJSON -OutVariable "CreatedTAP"
        
        $TAPs += [pscustomobject]@{
            DisplayName = $user.DisplayName
            UserPrincipalName = $user.UserPrincipalName
            Password = $PlainPassword
            TemporaryAccessPass = $CreatedTAP.TemporaryAccessPass
            TAPValidFrom = $CreatedTAP.StartDateTime
            TAPValidTo = $CreatedTAP.StartDateTime.AddMinutes($CreatedTAP.LifetimeInMinutes)
            IsUsableOnce = $CreatedTAP.IsUsableOnce
            PortalURL = "https://portal.azure.com"
            MyAppsURL = "https://myapps.microsoft.com"
        }
    }
    catch {
        Write-Host "Error creating TAP for user $($user.UserPrincipalName) : $_" -ForegroundColor Red
    }

}

# Export to CSV
$SafePrefix = $UserNamePrefix -replace '[^a-zA-Z0-9]', '_'
$CsvPath = ".\UserCredentials_$SafePrefix$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
$TAPs | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8

# Export to Excel
Export-Excel -InputObject $TAPs -Path ".\TemporaryAccessPasses.xlsx" -AutoSize -Title "Temporary Access Passes" -WorksheetName "TAPs" -TableName "TAPs" -TableStyle Light1 -Show

Write-Host "`nExport completed:" -ForegroundColor Green
Write-Host "  CSV: $CsvPath" -ForegroundColor Cyan
Write-Host "  Excel: TemporaryAccessPasses.xlsx" -ForegroundColor Cyan
Write-Host "`nTip: Use the Mail merge feature in Word to create personalized instruction pages for users." -ForegroundColor Yellow
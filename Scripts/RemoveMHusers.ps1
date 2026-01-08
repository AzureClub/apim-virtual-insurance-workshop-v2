#requires -Version 7

param(
    [Parameter(Mandatory = $true)]
    [string]$UserNamePrefix,
    
    [Parameter(Mandatory = $false)]
    [string]$GroupName,
    
    [Parameter(Mandatory = $false)]
    [switch]$WhatIf,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

$RequiredModules = @(
    'Microsoft.Graph.Users',
    'Microsoft.Graph.Groups'
)

foreach ($module in $RequiredModules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Install-PSResource -Name $module -TrustRepository
    }
    Import-Module $module -Force
}

# Remember to elevate via Privilege Identity Management (PIM) if needed before connecting
# At least User Administrator and Group Administrator roles are required
$context = Get-MgContext
if (-not $context) {
    Connect-MgGraph -Scopes "User.ReadWrite.All","Group.ReadWrite.All" -NoWelcome
}

Get-MgContext

$UPNSuffix = '@' + ((Get-MgContext).Account -split "@")[1]

# Find users with the specified prefix
Write-Host "`nSearching for users with prefix: $UserNamePrefix" -ForegroundColor Cyan
$Users = Get-MgUser -Filter "startsWith(DisplayName,'$UserNamePrefix')" -All | 
    Where-Object UserPrincipalName -like "*$UPNSuffix" | 
    Sort-Object DisplayName

if ($Users.Count -eq 0) {
    Write-Host "No users found with prefix '$UserNamePrefix'" -ForegroundColor Yellow
    exit
}

# Display users to be deleted
Write-Host "`nFound $($Users.Count) user(s) to delete:" -ForegroundColor Yellow
$Users | ForEach-Object {
    Write-Host "  - $($_.DisplayName) ($($_.UserPrincipalName))" -ForegroundColor White
}

# Confirm deletion unless -Force is specified
if (-not $Force -and -not $WhatIf) {
    Write-Host "`nWARNING: This will permanently delete these users!" -ForegroundColor Red
    $confirmation = Read-Host "Type 'DELETE' to confirm"
    if ($confirmation -ne 'DELETE') {
        Write-Host "Operation cancelled." -ForegroundColor Yellow
        exit
    }
}

if ($WhatIf) {
    Write-Host "`n[WHATIF] Would delete the following users:" -ForegroundColor Magenta
    foreach ($user in $Users) {
        Write-Host "  [WHATIF] Would delete: $($user.UserPrincipalName)" -ForegroundColor Magenta
    }
    exit
}

# Delete users
$SuccessCount = 0
$FailureCount = 0

foreach ($user in $Users) {
    Write-Host "`nDeleting user: $($user.UserPrincipalName)" -ForegroundColor Yellow
    
    try {
        Remove-MgUser -UserId $user.Id -Confirm:$false
        Write-Host "  Successfully deleted: $($user.UserPrincipalName)" -ForegroundColor Green
        $SuccessCount++
    }
    catch {
        Write-Host "  Error deleting user $($user.UserPrincipalName): $_" -ForegroundColor Red
        $FailureCount++
    }
}

# Summary
Write-Host "`n" + ("=" * 50) -ForegroundColor Cyan
Write-Host "Deletion Summary:" -ForegroundColor Cyan
Write-Host "  Total users found: $($Users.Count)" -ForegroundColor White
Write-Host "  Successfully deleted: $SuccessCount" -ForegroundColor Green
Write-Host "  Failed: $FailureCount" -ForegroundColor $(if ($FailureCount -gt 0) { "Red" } else { "White" })
Write-Host ("=" * 50) -ForegroundColor Cyan

# Optional: Delete the group if specified and now empty
if ($GroupName) {
    Write-Host "`nChecking group: $GroupName" -ForegroundColor Cyan
    $Group = Get-MgGroup -Filter "DisplayName eq '$GroupName'" -ErrorAction SilentlyContinue
    
    if ($Group) {
        $GroupMembers = Get-MgGroupMember -GroupId $Group.Id -ErrorAction SilentlyContinue
        
        if ($GroupMembers.Count -eq 0) {
            Write-Host "Group '$GroupName' is empty." -ForegroundColor Yellow
            $deleteGroup = Read-Host "Do you want to delete the group as well? (y/N)"
            
            if ($deleteGroup -eq 'y' -or $deleteGroup -eq 'Y') {
                try {
                    Remove-MgGroup -GroupId $Group.Id -Confirm:$false
                    Write-Host "Successfully deleted group: $GroupName" -ForegroundColor Green
                }
                catch {
                    Write-Host "Error deleting group: $_" -ForegroundColor Red
                }
            }
        }
        else {
            Write-Host "Group '$GroupName' still has $($GroupMembers.Count) member(s), not deleting." -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "Group '$GroupName' not found." -ForegroundColor Yellow
    }
}

Write-Host "`nNote: Deleted users are moved to the Recycle Bin and can be restored within 30 days." -ForegroundColor Cyan
Write-Host "To permanently delete or restore users, visit: https://portal.azure.com/#blade/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/DeletedUsers" -ForegroundColor Cyan

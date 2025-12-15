#requires -Version 7

param(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionName,
    
    [Parameter(Mandatory = $true)]
    [string]$Region,
    
    [Parameter(Mandatory = $true)]
    [string]$RGPrefix,
    
    [Parameter(Mandatory = $true)]
    [string]$UserNamePrefix,
    
    [Parameter(Mandatory = $true)]
    [int]$UserCount,
    
    [Parameter(Mandatory = $false)]
    [int]$StartIndex = 1
)

# Get UPN suffix from the signed-in account
$UPNSuffix = '@' + ((Get-MgContext).Account -split "@")[1]

# Set subscription
Write-Host "Setting subscription to: $SubscriptionName" -ForegroundColor Yellow
az account set --subscription $SubscriptionName
$SubscriptionId = az account show --query id -o tsv
Write-Host "Subscription ID: $SubscriptionId" -ForegroundColor Green

# Create RGs and assign Owner role
for ($i = $StartIndex; $i -lt ($StartIndex + $UserCount); $i++) {
    $num = $i.ToString("00")
    $rgName = "$RGPrefix$num"
    $userName = "$UserNamePrefix$num"
    $userUPN = "$userName$UPNSuffix"
    
    Write-Host "`nProcessing: $rgName for $userUPN" -ForegroundColor Yellow
    
    # Create resource group
    az group create --name $rgName --location $Region --output none
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  Created RG: $rgName" -ForegroundColor Green
    } else {
        Write-Host "  Failed to create RG: $rgName" -ForegroundColor Red
        continue
    }
    
    # Get user ID
    $user = Get-MgUser -Filter "UserPrincipalName eq '$userUPN'" -ErrorAction SilentlyContinue
    if (-not $user) {
        Write-Host "  User not found: $userUPN" -ForegroundColor Red
        continue
    }
    
    # Assign Owner role (using UPN instead of Object ID for better compatibility)
    $scope = "/subscriptions/$SubscriptionId/resourceGroups/$rgName"
    az role assignment create --assignee $userUPN --role "Owner" --scope $scope --output none
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  Assigned Owner role to: $userName" -ForegroundColor Cyan
    } else {
        Write-Host "  Failed to assign Owner role to: $userName" -ForegroundColor Red
    }
}

Write-Host "`n✅ Completed! Processed $UserCount resource groups." -ForegroundColor Green

<#
.SYNOPSIS
    Creates resource groups and assigns Owner role to corresponding users.

.DESCRIPTION
    This script creates resource groups with a specified prefix and assigns 
    the Owner role to users with matching numbers.

.PARAMETER SubscriptionName
    The name of the Azure subscription where resource groups will be created.

.PARAMETER Region
    The Azure region for the resource groups (e.g., swedencentral, westeurope).

.PARAMETER RGPrefix
    The prefix for resource group names (e.g., "rg-azureclubworkshopchat-").

.PARAMETER UserNamePrefix
    The prefix for user names (e.g., "chat-user-").

.PARAMETER UserCount
    The number of resource groups/users to process.

.PARAMETER StartIndex
    The starting index for numbering (default: 1).

.EXAMPLE
    .\CreateResourceGroups.ps1 -SubscriptionName "ME-MngEnvMCAP263417-edbartko-2" -Region "swedencentral" -RGPrefix "rg-azureclubworkshopchat-" -UserNamePrefix "chat-user-" -UserCount 50

.EXAMPLE
    .\CreateResourceGroups.ps1 -SubscriptionName "MySubscription" -Region "westeurope" -RGPrefix "rg-workshop-" -UserNamePrefix "lab-user-" -UserCount 30 -StartIndex 1
#>

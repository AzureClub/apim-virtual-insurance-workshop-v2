# Workshop Setup Scripts

**🌍 Language / Język:** [English](README-en.md) 🇬🇧 | [Polski](README.md) 🇵🇱

---

Helper scripts for preparing the Azure workshop environment.

---

## 📋 Contents

### 1. CreateMHusers.ps1
Creates Entra ID (Azure AD) users for workshop participants.

**Features:**
- Creates users with prefix and numbering
- Adds users to a group
- Assigns "Application Developer" role
- Generates Temporary Access Pass (TAP) for each user
- Exports credentials to CSV and Excel

**Requirements:**
- PowerShell 7+
- Modules: Microsoft.Graph.Users, Microsoft.Graph.Groups, ImportExcel
- Permissions: User Administrator, Group Administrator (via PIM if needed)
- Entra ID Premium P2 (for TAP)

**Usage:**
```powershell
$securePassword = ConvertTo-SecureString "YourStrongPassword123!" -AsPlainText -Force

.\CreateMHusers.ps1 `
    -UserNamePrefix "workshop-user-" `
    -UserCount 35 `
    -GroupName "Workshop-Participants" `
    -Password $securePassword
```

---

### 2. CreateResourceGroups.ps1
Creates Resource Groups and assigns Owner permissions to users.

**Features:**
- Creates Resource Groups with prefix and numbering
- Assigns Owner role to respective users
- Supports subscription and region selection

**Requirements:**
- PowerShell 7+
- Azure CLI logged in (`az login`)
- Microsoft.Graph module (`Get-MgUser`)
- Owner permissions on subscription

**Usage:**
```powershell
.\CreateResourceGroups.ps1 `
    -SubscriptionName "YourSubscription" `
    -Region "swedencentral" `
    -RGPrefix "rg-azureclubworkshopint-" `
    -UserNamePrefix "workshop-user-" `
    -UserCount 35 `
    -StartIndex 1
```

---

## ⚠️ SECURITY WARNINGS

### 🔐 Never commit:
- ❌ CSV files with credentials
- ❌ Excel files with TAP
- ❌ Files with user passwords
- ❌ Logs containing sensitive data

### ✅ Best practices:
1. **Use SecureString** for passwords (already implemented)
2. **Check .gitignore** before committing
3. **Delete credential files** after workshop completion
4. **Use PIM** to elevate permissions only when needed
5. **Change passwords** after workshops

---

## 📖 Typical Pre-Workshop Workflow

### Step 1: Prepare Users (2-3 days before)
```powershell
# Elevate permissions via PIM (User Administrator + Group Administrator)
# Then:

$pwd = ConvertTo-SecureString "SuperStrongPassword123!" -AsPlainText -Force

.\CreateMHusers.ps1 `
    -UserNamePrefix "workshop-user-" `
    -UserCount 35 `
    -GroupName "AzureClubWorkshop-2025" `
    -Password $pwd
```

**Result:**
- 35 users: workshop-user-01 to workshop-user-35
- Group: AzureClubWorkshop-2025
- Files: `UserCredentials_*.csv` and `TemporaryAccessPasses.xlsx`

### Step 2: Prepare Resource Groups (1 day before)
```powershell
# Log in to Azure CLI
az login

# Create Resource Groups
.\CreateResourceGroups.ps1 `
    -SubscriptionName "YourSubscriptionName" `
    -Region "swedencentral" `
    -RGPrefix "rg-azureclubworkshopint-" `
    -UserNamePrefix "workshop-user-" `
    -UserCount 35
```

**Result:**
- 35 Resource Groups: rg-azureclubworkshopint-01 to rg-azureclubworkshopint-35
- Each user has Owner role in their RG

### Step 3: Distribute Credentials
1. Print/send credentials to participants
2. **Delete CSV/Excel files from local machine**
3. Prepare "cheat sheets" with Azure resource names for each user

---

## 🧪 Pre-Workshop Testing

```powershell
# Test login for user 01
# 1. Go to https://portal.azure.com
# 2. Log in as workshop-user-01@yourtenant.onmicrosoft.com
# 3. Use TAP from the generated file
# 4. Check access to RG: rg-azureclubworkshopint-01
# 5. Verify Owner permissions
```

---

## 🗑️ Post-Workshop Cleanup

```powershell
# Delete Resource Groups
for ($i=1; $i -le 35; $i++) {
    $num = $i.ToString("00")
    az group delete --name "rg-azureclubworkshopint-$num" --yes --no-wait
}

# Delete users (via Azure Portal or Graph API)
# Delete workshop group
```

---

## 📞 Support

In case of issues:
- Check permissions (PIM elevations)
- Verify Entra ID licenses (TAP requires P2)
- Check PowerShell logs

---

## 📝 Changelog

### Version 1.0 (2025-12-15)
- ✅ Removed hardcoded passwords
- ✅ Added SecureString parameter for password
- ✅ Added .gitignore for sensitive files
- ✅ Improved script security

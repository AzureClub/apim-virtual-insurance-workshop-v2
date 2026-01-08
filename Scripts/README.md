# Workshop Setup Scripts

**🌍 Language / Język:** [English](README-en.md) EN | [Polski](README.md) PL

---

Skrypty pomocnicze do przygotowania środowiska warsztatowego Azure.

---

## 📋 Zawartość

### 1. CreateMHusers.ps1
Tworzy użytkowników Entra ID (Azure AD) dla uczestników warsztatu.

**Funkcje:**
- Tworzy użytkowników z prefiksem i numeracją
- Dodaje użytkowników do grupy
- Nadaje rolę "Application Developer"
- Generuje Temporary Access Pass (TAP) dla każdego użytkownika
- Eksportuje credentials do CSV i Excel

**Wymagania:**
- PowerShell 7+
- Moduły: Microsoft.Graph.Users, Microsoft.Graph.Groups, ImportExcel
- Uprawnienia: User Administrator, Group Administrator (możliwe przez PIM)
- Entra ID Premium P2 (dla TAP)

**Użycie:**
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
Tworzy Resource Groups i nadaje uprawnienia Owner użytkownikom.

**Funkcje:**
- Tworzy Resource Groups z prefiksem i numeracją
- Nadaje rolę Owner odpowiednim użytkownikom
- Obsługuje wybór subskrypcji i regionu

**Wymagania:**
- PowerShell 7+
- Azure CLI zalogowane (`az login`)
- Microsoft.Graph module (`Get-MgUser`)
- Uprawnienia Owner na subskrypcji

**Użycie:**
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

## ⚠️ OSTRZEŻENIA BEZPIECZEŃSTWA

### 🔐 Nigdy nie commituj:
- ❌ Plików CSV z credentials
- ❌ Plików Excel z TAP
- ❌ Plików z hasłami użytkowników
- ❌ Logów zawierających wrażliwe dane

### ✅ Dobre praktyki:
1. **Używaj SecureString** dla haseł (już zaimplementowane)
2. **Sprawdź .gitignore** przed commitem
3. **Usuń pliki credentials** po zakończeniu warsztatu
4. **Używaj PIM** do podniesienia uprawnień tylko na czas potrzebny
5. **Zmień hasła** po warsztatach

---

## 📖 Typowy workflow przed warsztatem

### Krok 1: Przygotowanie użytkowników (2-3 dni przed)
```powershell
# Podnieś uprawnienia przez PIM (User Administrator + Group Administrator)
# Następnie:

$pwd = ConvertTo-SecureString "SuperStrongPassword123!" -AsPlainText -Force

.\CreateMHusers.ps1 `
    -UserNamePrefix "workshop-user-" `
    -UserCount 35 `
    -GroupName "AzureClubWorkshop-2025" `
    -Password $pwd
```

**Rezultat:**
- 35 użytkowników: workshop-user-01 do workshop-user-35
- Grupa: AzureClubWorkshop-2025
- Pliki: `UserCredentials_*.csv` i `TemporaryAccessPasses.xlsx`

### Krok 2: Przygotowanie Resource Groups (1 dzień przed)
```powershell
# Zaloguj się do Azure CLI
az login

# Utwórz Resource Groups
.\CreateResourceGroups.ps1 `
    -SubscriptionName "YourSubscriptionName" `
    -Region "swedencentral" `
    -RGPrefix "rg-azureclubworkshopint-" `
    -UserNamePrefix "workshop-user-" `
    -UserCount 35
```

**Rezultat:**
- 35 Resource Groups: rg-azureclubworkshopint-01 do rg-azureclubworkshopint-35
- Każdy użytkownik ma rolę Owner w swoim RG

### Krok 3: Dystrybuuj credentials
1. Wydrukuj/wyślij credentials uczestnikomnikom
2. **Usuń pliki CSV/Excel z lokalnej maszyny**
3. Przygotuj "ściągawki" z nazwami zasobów Azure dla każdego użytkownika

---

## 🧪 Testowanie przed warsztatem

```powershell
# Test logowania dla użytkownika 01
# 1. Przejdź do https://portal.azure.com
# 2. Zaloguj się jako workshop-user-01@yourtenant.onmicrosoft.com
# 3. Użyj TAP z wygenerowanego pliku
# 4. Sprawdź dostęp do RG: rg-azureclubworkshopint-01
# 5. Zweryfikuj uprawnienia Owner
```

---

## 🗑️ Czyszczenie po warsztacie

```powershell
# Usuń Resource Groups
for ($i=1; $i -le 35; $i++) {
    $num = $i.ToString("00")
    az group delete --name "rg-azureclubworkshopint-$num" --yes --no-wait
}

# Usuń użytkowników (przez Azure Portal lub Graph API)
# Usuń grupę warsztatu
```

---

## 📞 Wsparcie

W przypadku problemów:
- Sprawdź uprawnienia (PIM elevations)
- Zweryfikuj licencje Entra ID (TAP wymaga P2)
- Sprawdź logi PowerShell

---

## 📝 Changelog

### Version 1.0 (2025-12-15)
- ✅ Usunięto hardcoded passwords
- ✅ Dodano parametr SecureString dla hasła
- ✅ Dodano .gitignore dla wrażliwych plików
- ✅ Poprawiono bezpieczeństwo skryptów

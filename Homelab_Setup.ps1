# =============================================================================
# Active Directory Home Lab Setup Script
# =============================================================================

Import-Module ActiveDirectory

$domain     = "HomeLab.local"
$domainDN   = "DC=HomeLab,DC=local"
$password   = ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force

# Create Organizational Units

Write-Host "`n[+] Creating Organizational Units..." -ForegroundColor Cyan

$cities = @("Calgary", "Camrose", "Edmonton")
$subOUs = @("Computer", "Servers", "Users")

foreach ($city in $cities) {
    # Create city OU
    $cityExists = Get-ADOrganizationalUnit -Filter "Name -eq '$city'" -SearchBase $domainDN -ErrorAction SilentlyContinue
    if (-not $cityExists) {
        New-ADOrganizationalUnit -Name $city -Path $domainDN
        Write-Host "  Created OU: $city" -ForegroundColor Green
    }

    $cityDN = "OU=$city,$domainDN"

    # Create sub-OUs
    foreach ($sub in $subOUs) {
        $subExists = Get-ADOrganizationalUnit -Filter "Name -eq '$sub'" -SearchBase $cityDN -ErrorAction SilentlyContinue
        if (-not $subExists) {
            New-ADOrganizationalUnit -Name $sub -Path $cityDN
            Write-Host "  Created OU: $city/$sub" -ForegroundColor Green
        }
    }
}

# Calgary Service Account OU
$svcOUPath = "OU=Calgary,$domainDN"
$svcExists = Get-ADOrganizationalUnit -Filter "Name -eq 'Service Account'" -SearchBase $svcOUPath -ErrorAction SilentlyContinue
if (-not $svcExists) {
    New-ADOrganizationalUnit -Name "Service Account" -Path $svcOUPath
    Write-Host "  Created OU: Calgary/Service Account" -ForegroundColor Green
}

# Create Security Groups

Write-Host "`n[+] Creating Security Groups..." -ForegroundColor Cyan

$departments = @("Accounting", "HR", "IT", "Management", "Sales")

foreach ($city in $cities) {
    $usersOU = "OU=Users,OU=$city,$domainDN"
    foreach ($dept in $departments) {
        $groupName = "$city-$dept"
        $groupExists = Get-ADGroup -Filter "Name -eq '$groupName'" -ErrorAction SilentlyContinue
        if (-not $groupExists) {
            New-ADGroup -Name $groupName `
                        -GroupScope Global `
                        -GroupCategory Security `
                        -Path $usersOU `
                        -Description "Security group for $dept department in $city"
            Write-Host "  Created Group: $groupName" -ForegroundColor Green
        }
    }
}

# Distribution group for IT admins
$dlExists = Get-ADGroup -Filter "Name -eq 'DL-ITAdmins'" -ErrorAction SilentlyContinue
if (-not $dlExists) {
    New-ADGroup -Name "DL-ITAdmins" `
                -GroupScope Global `
                -GroupCategory Distribution `
                -Path "OU=Users,OU=Calgary,$domainDN" `
                -Description "Distribution group for IT Administrators"
    Write-Host "  Created Distribution Group: DL-ITAdmins" -ForegroundColor Green
}

# Create Users

Write-Host "`n[+] Creating User Accounts..." -ForegroundColor Cyan

$deptPrefixes = @{
    "Accounting" = "Accounting User"
    "HR"         = "HR User"
    "IT"         = "IT User"
    "Management" = "Management User"
    "Sales"      = "Sales User"
}

foreach ($city in $cities) {
    $usersOU = "OU=Users,OU=$city,$domainDN"

    foreach ($dept in $departments) {
        $prefix = $deptPrefixes[$dept]
        $groupName = "$city-$dept"

        for ($i = 1; $i -le 3; $i++) {
            $displayName = "$prefix$i"
            $samAccount  = ($displayName -replace " ", "") + "-" + $city.Substring(0,3).ToUpper()
            $upn         = "$samAccount@$domain"

            $userExists = Get-ADUser -Filter "SamAccountName -eq '$samAccount'" -ErrorAction SilentlyContinue
            if (-not $userExists) {
                New-ADUser -Name $displayName `
                           -SamAccountName $samAccount `
                           -UserPrincipalName $upn `
                           -DisplayName $displayName `
                           -Path $usersOU `
                           -AccountPassword $password `
                           -Enabled $true `
                           -PasswordNeverExpires $false `
                           -ChangePasswordAtLogon $false `
                           -Department $dept `
                           -City $city

                # Add user to their department security group
                Add-ADGroupMember -Identity $groupName -Members $samAccount
                Write-Host "  Created User: $displayName ($city)" -ForegroundColor Green
            }
        }
    }
}

# Create a named test user for GPO testing
$testExists = Get-ADUser -Filter "SamAccountName -eq 'johndoe'" -ErrorAction SilentlyContinue
if (-not $testExists) {
    New-ADUser -Name "John Doe" `
               -SamAccountName "johndoe" `
               -UserPrincipalName "johndoe@$domain" `
               -DisplayName "John Doe" `
               -Path "OU=Users,OU=Calgary,$domainDN" `
               -AccountPassword $password `
               -Enabled $true `
               -Department "IT" `
               -City "Calgary"
    Add-ADGroupMember -Identity "Calgary-IT" -Members "johndoe"
    Write-Host "  Created Test User: John Doe (johndoe)" -ForegroundColor Green
}

# Create Computer Objects

Write-Host "`n[+] Creating Computer Objects..." -ForegroundColor Cyan

$cityPrefix = @{
    "Calgary"  = "CAL"
    "Camrose"  = "CAM"
    "Edmonton" = "EDM"
}

$deptCode = @{
    "Accounting" = "AC"
    "HR"         = "HR"
    "IT"         = "IT"
    "Management" = "MA"
    "Sales"      = "SA"
}

foreach ($city in $cities) {
    $computerOU = "OU=Computer,OU=$city,$domainDN"
    $prefix = $cityPrefix[$city]

    foreach ($dept in $departments) {
        $code = $deptCode[$dept]
        $computerName = "$prefix-$code-PC01"

        $compExists = Get-ADComputer -Filter "Name -eq '$computerName'" -ErrorAction SilentlyContinue
        if (-not $compExists) {
            New-ADComputer -Name $computerName `
                           -Path $computerOU `
                           -Description "$dept workstation - $city"
            Write-Host "  Created Computer: $computerName" -ForegroundColor Green
        }
    }
}

# Create Service Account

Write-Host "`n[+] Creating Service Account..." -ForegroundColor Cyan

$svcExists = Get-ADUser -Filter "SamAccountName -eq 'svc-kiosk'" -ErrorAction SilentlyContinue
if (-not $svcExists) {
    New-ADUser -Name "Website Login" `
               -SamAccountName "$website-login" `
               -UserPrincipalName "$website-login@$domain" `
               -DisplayName "Website Login" `
               -Description "Autologin to Website" `
    Write-Host "  Created Service Account: svc-kiosk" -ForegroundColor Green
}



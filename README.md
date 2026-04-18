# Active Directory Home Lab

A hands-on home lab simulating an enterprise Active Directory environment built on Windows Server 2022. This project was built to develop real-world IT support and sysadmin skills 
including user lifecycle management, Group Policy, shared storage, security policies, and service account configuration.

---

## Environment

| Component | Details |
|---|---|
| Domain Controller | Windows Server 2022 Standard Evaluation |
| Client Workstation | Windows 11 Pro (domain joined) |
| Domain Name | HomeLab.local |
| Virtualization | VMware Workstation |
| Network | NAT — client DNS pointed to DC |

---

## Active Directory Structure

The domain is organized into three city-based OUs modelling a multi-site organization. Each city contains sub-OUs for Computers, Servers, and Users. Calgary also includes a Service Account OU.

```
HomeLab.local
├── Calgary
│   ├── Computer
│   ├── Servers
│   ├── Service Account
│   └── Users
├── Camrose
│   ├── Computer
│   ├── Servers
│   └── Users
└── Edmonton
    ├── Computer
    ├── Servers
    └── Users
```

### Users
45 user accounts created across 3 cities and 5 departments (Accounting, HR, IT, Management, Sales) using a PowerShell automation script. Each user is assigned to their corresponding city and department security group.

### Security Groups
15 security groups created — 5 per city — following the naming convention `City-Department` (e.g. Calgary-HR, Edmonton-IT). One distribution group `DL-ITAdmins` also created for the IT admin team.

### Computers
15 computer objects created following the naming convention `CITY-DEPT-PC01` (e.g. CAL-HR-PC01, EDM-IT-PC01). One physical workstation (COMP01) was domain joined for live GPO testing.

---

## Group Policy Objects

| GPO | Configuration | Linked To |
|---|---|---|
| Desktop Wallpaper | Enforces corporate wallpaper via UNC path | Calgary/Users OU |
| Disable USB Storage | Blocks removable storage via registry policy | Calgary/Users OU |
| Restrict Control Panel | Denies access to Control Panel and Settings | Calgary/Users OU |
| Drive Mapping | Maps S: drive to shared folder via GPO Preferences | Calgary/Users OU |
| Password Policy | Min length 10, complexity on, max age 90 days | Domain level |
| Account Lockout Policy | 5 attempts, 15 min lockout, admin unlock tested | Domain level |
| User Rights | Deny local login for service accounts, allow RDP for IT | Calgary OU |

All GPOs were verified using `gpresult /r` on the domain-joined workstation logged in as a standard domain user.

---

## Shared Folder & FSRM

A shared folder was created at `C:\Shared` and published as `\\WIN-BQ8SMHJIM4M\Shared`. Permissions were configured at both the share level and NTFS level separately.

- **Share permissions:** Domain Users — Read, Administrators — Full Control
- **NTFS permissions:** Domain Users — Read & Execute, Administrators — Full Control

### File Server Resource Manager (FSRM)
- **Quota:** 500MB soft quota on the shared folder with email notification at 80% threshold
- **File Screening:** Active screen blocking .exe, .bat, and .cmd files from being saved to the share
- Tested by attempting to upload an executable — blocked as expected

---

## Security Policies

### Password & Lockout Policy
- Minimum password length: 10 characters
- Complexity: Enabled (uppercase, lowercase, number, symbol)
- Maximum password age: 90 days
- Lockout threshold: 5 invalid attempts
- Lockout duration: 15 minutes
- Tested full lockout and manual unlock via ADUC

### Fine-Grained Password Policy
A separate policy was configured via Active Directory Administrative Center (ADAC) for the IT security group requiring a minimum of 14 characters and a 5-minute lockout to simulate privileged account hardening.

### User Rights Assignment
- Service accounts denied interactive login via GPO
- IT Users group granted RDP access
- Verified: IT user connected via RDP successfully, Sales user denied

---

## Service Account & Kiosk Setup

A service account `svc-kiosk` was created under Calgary/Service Account OU for a single-purpose kiosk workstation.

- Non-expiring password, cannot change password
- Auto-login configured via registry on the kiosk workstation
- Microsoft Edge launches automatically on boot and opens a designated URL
- Interactive login denied via User Rights Assignment GPO
- Result: Machine boots, auto-logs in, opens browser — no manual credentials required

---

## PowerShell Automation

The script `Setup-HomeLab-AD.ps1` automates the full environment setup:

- Creates all OUs including sub-OUs across 3 cities
- Creates 15 security groups + 1 distribution group
- Creates 45 users, assigns each to the correct group
- Creates 15 computer objects with standardized naming
- Creates test user `johndoe` and service account `svc-kiosk`

### Usage
```powershell
# Run on the Domain Controller as Administrator
.\Setup-HomeLab-AD.ps1
```

> **Note:** Default password for all created accounts is `P@ssw0rd123!` — change before using in any real environment.

---

## Testing & Validation

| Test | Method | Result |
|---|---|---|
| GPO application | `gpresult /r` on client as johndoe | All GPOs listed as applied |
| Desktop wallpaper | Login as domain user | Wallpaper changed automatically |
| USB block | Insert removable drive | Device not recognized |
| Control Panel | Access as standard user | Denied |
| Mapped drive S: | `gpupdate /force` + re-login | Drive appeared in File Explorer |
| Account lockout | 5 wrong password attempts | Account locked, unlocked via ADUC |
| RDP — IT user | Connect from client | Successful |
| RDP — Sales user | Connect from client | Denied |
| FSRM file screen | Copy .exe to shared folder | Blocked |

---

## Skills Demonstrated

- Active Directory DS — domain setup, OUs, users, groups, computers, service accounts
- PowerShell automation — bulk object creation with error handling and output logging
- Group Policy — creation, linking, testing, and troubleshooting with gpresult
- File services — shared folders, NTFS permissions, FSRM quotas and file screening
- Security hardening — password policies, lockout policies, fine-grained policies via ADAC
- Remote Desktop — RDP access control via GPO and user rights assignment
- Troubleshooting — gpresult, Event Viewer, ADUC for diagnosing policy and access issues
- Documentation — full environment documented with configs, test results, and procedures

---

## Repository Structure

```
homelab-ad/
├── README.md
├── Homelab_Setup.ps1
├── docs/
│   └── HomeLab_Documentation.docx
└── screenshots/
    ├── ad-ou-structure.png
    ├── gpo-management.png
    ├── gpresult-applied.png
    ├── mapped-drive.png
    ├── fsrm-quota.png
    └── rdp-test.png
```

---

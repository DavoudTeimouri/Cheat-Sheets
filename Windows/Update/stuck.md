# Windows Update Troubleshooting

## 1. Windows Update stuck

```powershell
net stop wuauserv
net stop cryptSvc
net stop bits
net stop msiserver
ren C:\Windows\SoftwareDistribution SoftwareDistribution.old
ren C:\Windows\System32\catroot2 catroot2.old
net start wuauserv
net start cryptSvc
net start bits
net start msiserver
```
Check Event Viewer > Windows Logs > System, source `WindowsUpdateClient`, error codes (0x80070005, 0x80072ee2 = network/proxy).

---
## Windows Update deep dive

```powershell
net stop wuauserv
net stop cryptSvc
net stop bits
net stop msiserver
ren C:\Windows\SoftwareDistribution SoftwareDistribution.old
ren C:\Windows\System32\catroot2 catroot2.old
net start wuauserv
net start cryptSvc
net start bits
net start msiserver
```
- Check Event Viewer > Windows Logs > System, source `WindowsUpdateClient`, error codes (0x80070005, 0x80072ee2 = network/proxy)

## Services deep dive

```powershell
Get-Service \| Where-Object {$_.Status -eq 'Stopped'}
Get-EventLog -LogName System -Source Service Control Manager -Newest 20
sc queryex <servicename>
sc failure <servicename> reset= 0 actions= restart/5000/restart/5000/restart/5000
```
- Error 1053 → service startup timeout; check dependencies (`sc config <svc> depend= <dep>`)
- Error 1068 → dependency service failed first; fix root dependency

## Verification

```powershell
$ErrorActionPreference='SilentlyContinue'
Write-Host "== Update =="; Get-WindowsUpdateLog -ErrorAction SilentlyContinue \| Select-Object -First 1 \| Write-Host || Write-Host "log n/a"
Write-Host OK
```

## Safety

- Renaming SoftwareDistribution/catroot2 is safe; Windows rebuilds them.

---

<ponytail: Scope ceiling — Windows Update client + cleanup only; add WSUS, Configuration Manager, and Update for Business when those management tools are used.</ponytail>
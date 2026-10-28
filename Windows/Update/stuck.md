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
<ponytail: Scope ceiling — Windows Update client + cleanup only; add WSUS, Configuration Manager, and Update for Business when those management tools are used.</ponytail>
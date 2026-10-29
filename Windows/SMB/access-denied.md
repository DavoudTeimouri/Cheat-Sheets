# Windows SMB Troubleshooting

## 1. SMB / file share access denied

```powershell
net use
net use * /delete
Get-SmbConnection
Get-SmbOpenFile
Test-NetConnection <host> -Port 445
```
- NTFS vs share permissions: most restrictive wins — check both Security and Sharing tabs
- `lsass`/credential prompts: `cmdkey /list`, `cmdkey /delete:<target>`
- SMB1 disabled by default: enable only temporarily (`Set-SmbServerConfiguration -EnableSMB1Protocol $true`) — security risk

## 2. Services won't start

```powershell
Get-Service | Where-Object {$_.Status -eq 'Stopped'}
Get-EventLog -LogName System -Source Service Control Manager -Newest 20
sc queryex <servicename>
sc failure <servicename> reset= 0 actions= restart/5000/restart/5000/restart/5000
```
- Error 1053 (service did not respond): service startup timeout, check dependencies (`sc config <svc> depend= <dep>`)
- Error 1068: dependency service failed first — fix root dependency

## 3. WinRM / PowerShell remoting

```powershell
Enable-PSRemoting -Force
Set-Item WSMan:\\localhost\\Client\\TrustedHosts -Value <host> -Concatenate
Test-WsMan <host>
Enter-PSSession <host>
```
- HTTPS/SSL failing: certificate thumbprint mismatch, `winrm quickconfig -transport:https`, client `TrustHostCode`
- Non-domain: add hosts to TrustedHosts on both sides, or use CredSSP (disable after patching CredSSP CVE fixes)

---
## SMB / file share deep dive

```powershell
net use
net use * /delete
Get-SmbConnection
Get-SmbOpenFile
Test-NetConnection <host> -Port 445
```
- NTFS vs share permissions → most restrictive wins; check both Security and Sharing tabs
- `lsass`/credential prompts → `cmdkey /list`, `cmdkey /delete:<target>`
- SMB1 disabled by default → enable only temporarily (`Set-SmbServerConfiguration -EnableSMB1Protocol $true`) — security risk

## WinRM / PowerShell remoting

```powershell
Enable-PSRemoting -Force
Set-Item WSMan:\localhost\Client\TrustedHosts -Value <host> -Concatenate
Test-WsMan <host>
Enter-PSSession <host>
```
- HTTPS/SSL failing → certificate thumbprint mismatch, `winrm quickconfig -transport:https`
- Non-domain → add hosts to TrustedHosts on both sides, or use CredSSP (disable after patching CredSSP CVE fixes)

## BSOD / Hyper-V

```powershell
Get-VM
Get-VMHost
Checkpoint-VM <name> -SnapshotName <name>
Remove-VMSnapshot -VMName <name> -Name <name>
```
- `C:\Windows\Minidump\*.dmp` → analyze with WinDbg (`!analyze -v`)
- STOP codes: `CRITICAL_PROCESS_DIED`, `PAGE_FAULT_IN_NONPAGED_AREA`, `SYSTEM_THREAD_EXCEPTION_NOT_HANDLED`
- VM paused-critical → host disk full where config/snapshots live; expand or move storage
- Checkpoint merge stuck → don't force-delete AVHDX manually; wait or export/import VM

## Log locations

- `C:\Windows\System32\winevt\Logs\*.evtx` — Event Viewer
- `C:\Windows\Minidump\` — kernel crash dumps
- `C:\Windows\Logs\CBS\` — component store (sfc/dism)
- `C:\Windows\WindowsUpdate.log` — `Get-WindowsUpdateLog`

## Verification

```powershell
$ErrorActionPreference='SilentlyContinue'
Write-Host "== SMB 445 ="; Test-NetConnection localhost -Port 445 \| Select-Object TcpTestSucceeded
Write-Host OK
```

## Safety

- Disabling SMB1 exposes to ransomware wormability; re-enable only temporarily.
- `Remove-VMSnapshot` merges data; don't interrupt or force-delete AVHDX manually.

---

<ponytail: Scope ceiling — SMB shares, services, WinRM only; add Storage Spaces, DFS, and BranchCache when those file services are used.</ponytail>
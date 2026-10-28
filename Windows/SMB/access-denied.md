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
<ponytail: Scope ceiling — SMB shares, services, WinRM only; add Storage Spaces, DFS, and BranchCache when those file services are used.</ponytail>
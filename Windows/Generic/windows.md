# Windows Troubleshooting

## 1. RDP cannot connect

- `mstsc` / Remote Desktop fails: service `TermService` stopped → `net start termsrvc` or `sc start TermService`
- Network Level Authentication (NLA) mismatch: disable NLA via registry (`HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\UserAuthentication = 0`) or use `/admin` switch
- Firewall: `netsh advfirewall firewall show rule name="Remote Desktop"`; enable inbound TCP 3389
- Too many sessions / max connections: `qwinsta`, `rwinsta <session-id>`
- Certificate error: client trusts self-signed cert; ignore or deploy CA-issued cert

## 2. Active Directory / domain issues

```powershell
nltest /dsgetdc:<domain>
dcdiag /v
repadmin /showreps
gpresult /r
gpupdate /force
```
- `RPC server unavailable`: DNS wrong, DC unreachable (`nslookup <dc>`, `ping`), firewall blocking RPC/AD ports (135, 389, 445, 636, 3268, 3269, dynamic RPC)
- Account locked: `dsquery user -samid <name> | dsmod user -disabled no` or unlock via ADUC; find lockout source with Event ID 4740
- Replication broken: `repadmin /replsummary`, fix DNS forwarders, remove stale metadata (`ntdsutil metadata cleanup`)

## 3. DNS resolution fails

```powershell
nslookup <host> <dns-server>
ipconfig /flushdns
ipconfig /registerdns
dnscmd <dns-server> /zoneinfo <zone>
```
- Stale A records: enable DNS scavenging, set record aging
- Forwarders unreachable: use root hints or valid forwarder, test `nslookup google.com 8.8.8.8`

## 4. Group Policy not applying

```powershell
gpresult /h gp.html /f
rsop.msc
gpupdate /force
eventvwr.msc   # Applications and Services Logs > Microsoft > Windows > GroupPolicy > Operational
```
- `Access denied`: computer account lacks Read on GPO (`Authenticated Users`), WMI filter blocking
- Loopback processing: check `Computer Configuration > Administrative Templates > System > Group Policy > User Group Policy loopback processing mode`
- Slow boot: remove unused GPOs, script timeouts

## 5. Windows Update stuck

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

## 6. SMB / file share access denied

```powershell
net use
net use * /delete
Get-SmbConnection
Get-SmbOpenFile
Test-NetConnection <host> -Port 445
```
- NTFS vs share permissions: most restrictive wins; check both Security and Sharing tabs
- `lsass`/credential prompts: `cmdkey /list`, `cmdkey /delete:<target>`
- SMB1 disabled by default: enable only temporarily (`Set-SmbServerConfiguration -EnableSMB1Protocol $true`) — security risk

## 7. Services won't start

```powershell
Get-Service | Where-Object {$_.Status -eq 'Stopped'}
Get-EventLog -LogName System -Source Service Control Manager -Newest 20
sc queryex <servicename>
sc failure <servicename> reset= 0 actions= restart/5000/restart/5000/restart/5000
```
- Error 1053 (service did not respond): service startup timeout, check dependencies (`sc config <svc> depend= <dep>`)
- Error 1068: dependency service failed first — fix root dependency

## 8. WinRM / PowerShell remoting

```powershell
Enable-PSRemoting -Force
Set-Item WSMan:\localhost\Client\TrustedHosts -Value <host> -Concatenate
Test-WsMan <host>
Enter-PSSession <host>
```
- HTTPS/SSL failing: certificate thumbprint mismatch, `winrm quickconfig -transport:https`, client `TrustHostCode`
- Non-domain: add hosts to TrustedHosts on both sides, or use CredSSP (disable for security after patching CredSSP CVE fixes)

## 9. Blue screen / crash dumps

- `C:\Windows\Minidump\*.dmp` — analyze with WinDbg (`!analyze -v`)
- Common STOP codes: `CRITICAL_PROCESS_DIED` (driver), `PAGE_FAULT_IN_NONPAGED_AREA` (RAM/driver), `SYSTEM_THREAD_EXCEPTION_NOT_HANDLED` (graphics driver)
- Disable automatic restart to read STOP code: `SystemPropertiesAdvanced` > Startup and Recovery > untick "Automatically restart"
- Memory test: `mdsched.exe` (Windows Memory Diagnostic)

## 10. Hyper-V VM issues

```powershell
Get-VM
Get-VMHost
Get-VHD -Path <path> | Get-VHD -DiskNumber ...
Checkpoint-VM <name> -SnapshotName <name>
Remove-VMSnapshot -VMName <name> -Name <name>   # merge before removing if possible
```
- VM paused-critical: host disk where config/snapshots live is full — expand or move storage
- Checkpoint merge stuck: don't force-delete AVHDX manually; wait, or export/import VM as last resort
- Integration Services outdated: update via Windows Update or `icsetup.exe` on guest

## Log locations

- `C:\Windows\System32\winevt\Logs\*.evtx` — Event Viewer
- `C:\Windows\Minidump\` — kernel crash dumps
- `C:\Windows\Logs\CBS\` — component store (sfc/dism)
- `C:\Windows\WindowsUpdate.log` — generated via `Get-WindowsUpdateLog`

## Quick self-check

```powershell
$ErrorActionPreference='SilentlyContinue'
Write-Host "== RDP =="; Get-Service TermService | Select-Object Name,Status
Write-Host "== DNS =="; Resolve-DnsName google.com -Type A | Select-Object -First 1 Name,IPAddress
Write-Host "== SMB 445 ="; Test-NetConnection localhost -Port 445 | Select-Object TcpTestSucceeded
Write-Host "== Update ="; Get-WindowsUpdateLog -ErrorAction SilentlyContinue | Select-Object -First 1 || Write-Host "log n/a"
Write-Host OK
```

---
<ponytail: Scope ceiling — on-prem AD/DNS/GPO/file/remote access only; add Azure AD/Entra, Intune, WSUS, and Windows Server core roles when in use.</ponytail>
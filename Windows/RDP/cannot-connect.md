# Windows RDP Troubleshooting

## 1. RDP cannot connect

- `mstsc` / Remote Desktop fails: service `TermService` stopped → `net start termsrvc` or `sc start TermService`
- Network Level Authentication (NLA) mismatch: disable NLA via registry (`HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\UserAuthentication = 0`) or use `/admin` switch
- Firewall: `netsh advfirewall firewall show rule name="Remote Desktop"`; enable inbound TCP 3389
- Too many sessions / max connections: `qwinsta`, `rwinsta <session-id>`
- Certificate error: client trusts self-signed cert — ignore or deploy CA-issued cert

## RDP deep dive

```powershell
Get-Service TermService
net start termsrvc
sc start TermService
netsh advfirewall firewall show rule name="Remote Desktop"
netsh advfirewall firewall add rule name="RDP" dir=in action=allow protocol=TCP localport=3389
qwinsta
rwinsta <session-id>
```
- `TermService` stopped → `net start termsrvc` or `sc start TermService`
- NLA mismatch → disable via registry (`HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\UserAuthentication = 0`) or `/admin` switch
- Too many sessions → `qwinsta`, `rwinsta <session-id>`
- Cert error → client trusts self-signed cert; ignore or deploy CA-issued cert

## AD / domain deep dive

```powershell
nltest /dsgetdc:<domain>
dcdiag /v
repadmin /showreps
gpresult /r
gpupdate /force
nslookup <dc>
ping <dc>
```
- `RPC server unavailable` → DNS wrong, DC unreachable, firewall blocking RPC/AD ports (135, 389, 445, 636, 3268, 3269, dynamic RPC)
- Account locked → `dsquery user -samid <name> \| dsmod user -disabled no`; find lockout source with Event ID 4740
- Replication broken → `repadmin /replsummary`, fix DNS forwarders, remove stale metadata (`ntdsutil metadata cleanup`)

## DNS deep dive

```powershell
nslookup <host> <dns-server>
ipconfig /flushdns
ipconfig /registerdns
dnscmd <dns-server> /zoneinfo <zone>
```
- Stale A records → enable DNS scavenging, set record aging
- Forwarders unreachable → root hints or valid forwarder; test `nslookup google.com 8.8.8.8`

## Verification

```powershell
$ErrorActionPreference='SilentlyContinue'
Write-Host "== RDP =="; Get-Service TermService \| Select-Object Name,Status
Write-Host "== DNS =="; Resolve-DnsName google.com -Type A \| Select-Object -First 1 Name,IPAddress
Write-Host "== SMB 445 ="; Test-NetConnection localhost -Port 445 \| Select-Object TcpTestSucceeded
Write-Host OK
```

## Safety

- Disabling NLA reduces security; re-enable after debugging.
- `rwinsta` disconnects the user's session; warn the user first.

---

<ponytail: Scope ceiling — RDP client/server connectivity only; add RD Gateway, RD Web, and multi-session tuning when those roles are used.</ponytail>
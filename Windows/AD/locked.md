# Windows Active Directory Troubleshooting

## 1. AD / domain issues

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

## 2. DNS resolution fails

```powershell
nslookup <host> <dns-server>
ipconfig /flushdns
ipconfig /registerdns
dnscmd <dns-server> /zoneinfo <zone>
```
- Stale A records: enable DNS scavenging, set record aging
- Forwarders unreachable: use root hints or valid forwarder, test `nslookup google.com 8.8.8.8`

---
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
Write-Host "== DC =="; nltest /dsgetdc:corp.example.com 2>$null \| Select-Object -First 1
Write-Host "== DNS =="; Resolve-DnsName google.com -Type A \| Select-Object -First 1 Name,IPAddress
Write-Host OK
```

## Safety

- `repadmin /replsummary` is read-only; safe. `ntdsutil metadata cleanup` is destructive; verify domain controller first.

---

<ponytail: Scope ceiling — AD domain services + DNS only; add AD FS, certificate services, and read-only DCs when those roles exist.</ponytail>
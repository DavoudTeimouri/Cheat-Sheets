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
<ponytail: Scope ceiling — AD domain services + DNS only; add AD FS, certificate services, and read-only DCs when those roles exist.</ponytail>
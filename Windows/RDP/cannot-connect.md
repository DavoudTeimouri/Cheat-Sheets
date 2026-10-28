# Windows RDP Troubleshooting

## 1. RDP cannot connect

- `mstsc` / Remote Desktop fails: service `TermService` stopped → `net start termsrvc` or `sc start TermService`
- Network Level Authentication (NLA) mismatch: disable NLA via registry (`HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\UserAuthentication = 0`) or use `/admin` switch
- Firewall: `netsh advfirewall firewall show rule name="Remote Desktop"`; enable inbound TCP 3389
- Too many sessions / max connections: `qwinsta`, `rwinsta <session-id>`
- Certificate error: client trusts self-signed cert — ignore or deploy CA-issued cert

---
<ponytail: Scope ceiling — RDP client/server connectivity only; add RD Gateway, RD Web, and multi-session tuning when those roles are used.</ponytail>
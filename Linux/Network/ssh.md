# Linux Network Troubleshooting

## 1. SSH connection refused / timeout

```bash
systemctl status sshd
systemctl restart sshd
ss -tlnp | grep 22
firewall-cmd --list-all        # firewalld (RHEL)
ufw status                     # Ubuntu
tail -f /var/log/secure        # RHEL
tail -f /var/log/auth.log      # Debian
```
- Port 22 not listening: sshd not running or `Port` directive in `/etc/ssh/sshd_config` points elsewhere
- Firewall blocking: open TCP 22 (`firewall-cmd --permanent --add-port=22/tcp --reload`)
- `Connection refused` vs `Connection timeout`: refused = service not listening; timeout = firewall/network drop

## 2. DNS resolution fails

```bash
resolvectl status              # systemd-resolved
cat /etc/resolv.conf
systemctl restart systemd-resolved
ping 1.1.1.1                   # isolate DNS vs routing
getent hosts example.com
dig @8.8.8.8 example.com
```
- `/etc/resolv.conf` points to 127.0.0.53 but systemd-resolved down → restart it
- No nameservers: add `nameserver 8.8.8.8` to `/etc/resolv.conf` (transient) or configure Netplan/NetworkManager

## 3. Network unreachable / no IP

```bash
ip addr
ip route
ip -br link
nmcli device                   # NetworkManager
systemctl restart NetworkManager
systemctl restart networking   # Debian/Ubuntu ifupdown
```
- No IP on interface: DHCP client not running, static config missing, cable/port down
- Wrong default gateway: `ip route show`, add `ip route add default via <gw>`

## 4. Firewall blocking traffic

```bash
firewall-cmd --list-all
iptables -L -n -v
ufw status verbose
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --reload
```
- Default zone blocks inbound: add service/port to zone or change interface zone
- nftables vs iptables mismatch: check which backend is active (`update-alternatives --config iptables`)

## 5. Slow network / high latency

```bash
ping -c 4 <host>
mtr --report <host>
ethtool <interface>           # speed, duplex, errors
ip -s link                    # dropped packets
```
- Duplex mismatch: force speed/duplex with ethtool, check switch port
- Dropped RX/TX: bad cable, NIC driver, or ring buffer too small (`ethtool -G <iface> rx 4096`)

## Diagnosis sequence

```bash
# 1. Link and address state
ip -br link                    # state UP/DOWN
ip -br addr                    # IPv4/IPv6 assigned?
ip route                       # default gateway present?

# 2. L2 / gateway reachability
ip neigh show dev eth0
ping -c 3 <gateway>
arping -I eth0 -c 3 <gateway>  # L2 when ICMP filtered

# 3. DNS (app behavior first)
getent hosts example.com       # NSS path, closest to applications
resolvectl query example.com   # systemd-resolved path
dig +short example.com @<dns-server>

# 4. Port / service reachability
ss -tlnp                       # local listeners
ss -tnp state established      # active connections
nc -zv <host> 443              # TCP port check

# 5. Path and MTU
traceroute -T -p 443 <host>
mtr --report --tcp --port 443 <host>
ping -M do -s 1472 <host>      # MTU 1500, no fragmentation
```

## SSH deep dive

```bash
# Server config validation
sshd -T \| grep -E 'port|listenaddress|permitrootlogin|passwordauthentication|pubkeyauthentication'

# Server logs
journalctl -u sshd -n 50 --no-pager
tail -f /var/log/secure        # RHEL
tail -f /var/log/auth.log      # Debian/Ubuntu

# Client debug
ssh -vvv user@host 2>&1 \| grep -E 'debug1|Offering|Authentications'
ssh-keygen -lf ~/.ssh/id_ed25519.pub   # fingerprint

# Push key correctly
ssh-copy-id -i ~/.ssh/id_ed25519.pub user@host
```

Permission order of checks (most frequent first):

1. **Home dir perms** — `chmod 755 /home/user`, `chmod 700 ~/.ssh`, `chmod 600 ~/.ssh/authorized_keys`
2. **SELinux context** — `restorecon -Rv ~/.ssh`; check `ausearch -m avc -ts recent`
3. **Wrong key** — `ssh -i <key> user@host`; add `IdentitiesOnly yes` to `~/.ssh/config`
4. **sshd restrictions** — `AllowUsers`, `DenyUsers`, `PubkeyAuthentication no`, `UsePAM yes`
5. **fail2ban / firewall** — `fail2ban-client status sshd`; `nft list ruleset`

## DNS deep dive

| Check | Command | Interpretation |
|-------|---------|----------------|
| Resolver config | `resolvectl status` | DNS servers per link, DNSSEC |
| Stub resolver | `cat /etc/resolv.conf` | `127.0.0.53` = systemd-resolved stub |
| Per-link query | `resolvectl query example.com` | Which link answered |
| Direct query | `dig @1.1.1.1 example.com` | Bypasses local resolver |
| NSS order | `grep hosts /etc/nsswitch.conf` | Expect `files dns` |
| Flush cache | `resolvectl flush-caches` | After DNS record change |

- `dig` works, `getent` fails → `nsswitch.conf` missing `dns` or `systemd` module.
- Only some names fail → split-horizon/search domain; check `resolvectl domain`.
- `Temporary failure in name resolution` → no nameserver reachable; test `dig @<server>` directly.

## Firewall deep dive

```bash
# firewalld
firewall-cmd --state
firewall-cmd --get-active-zones
firewall-cmd --zone=public --list-all
firewall-cmd --permanent --zone=public --add-service=https
firewall-cmd --reload
firewall-cmd --runtime-to-permanent   # persist runtime changes

# nftables / iptables
nft list ruleset
iptables -S
iptables -t nat -S

# ufw
ufw status verbose
ufw allow 443/tcp
```

- Rule exists but blocked → wrong zone, wrong interface binding, or nftables vs iptables backend mismatch (`update-alternatives --config iptables`).
- Docker/K8s traffic broken → Docker uses `DOCKER-USER` chain; K8s uses `KUBE-*` chains. Add to `DOCKER-USER`, not `INPUT`.
- `firewall-cmd --reload` can drop active sessions; prefer `--runtime-to-permanent`.

## Performance / packet loss

```bash
ethtool eth0 \| grep -E 'Speed|Duplex|Link detected'
ethtool -S eth0 \| grep -iE 'err|drop|miss|crc'
ip -s link show eth0
ss -s
sar -n DEV 1 5
tcpdump -i eth0 -nn host <peer> -c 100
```

- CRC errors increasing → cable / SFP / switch port; replace cable, check optics.
- RX drops increasing → ring buffer too small: `ethtool -G eth0 rx 4096`.
- Retransmits → `ss -ti` shows `retrans`; check loss and MTU.
- Duplex mismatch → one side forced 100/full, other auto; fix both to auto or both forced.

## Log locations

- `/var/log/secure` (RHEL), `/var/log/auth.log` (Debian) — SSH/auth
- `journalctl -u NetworkManager -u systemd-networkd -u systemd-resolved`
- `dmesg \| grep -iE 'eth|link|nic|firmware'` — driver/link events
- `tcpdump -i any -w /tmp/cap.pcap` — capture for escalation

## Verification

```bash
#!/bin/bash
set -u
echo "== link =="; ip -br link \| grep -v DOWN \| head
echo "== default route =="; ip route \| grep default || true
echo "== dns =="; getent hosts example.com || true
echo "== sshd =="; systemctl is-active sshd 2>/dev/null || true
echo "== listeners =="; ss -tlnp \| head -10
echo OK
```

## Safety

- `firewall-cmd --reload` can drop active sessions; prefer `--runtime-to-permanent`.
- `ip route del default` over SSH = lockout; use `ip route replace`, keep a second session open.
- Validate `sshd_config` with `sshd -t` before restarting, or risk lockout.

---

<ponytail: Scope ceiling — node-level IP/DNS/SSH/firewall only; add bonding, VLAN, bridge, WireGuard/IPsec, and eBPF/tc shaping when those layers are used.</ponytail>
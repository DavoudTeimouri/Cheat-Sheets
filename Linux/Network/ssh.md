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

---
<ponytail: Scope ceiling — common node networking only; add bonding, VLAN, bridge, and WireGuard when those interfaces exist.</ponytail>
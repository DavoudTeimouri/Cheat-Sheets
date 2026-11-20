# Linux Temporary IP & DNS Troubleshooting

**Category:** Operating System  
**Applies to:** RHEL/Rocky/Alma 8–9, Ubuntu 20.04–24.04, Debian 11–12, SUSE 15

## Temporary IP address (non-persistent)

Lost on reboot. Use for testing, rescue, or quick access.

```bash
# Show current interfaces/addresses
ip -br addr
ip -br link

# Add a secondary IP to an interface (CIDR)
ip addr add 192.168.1.50/24 dev eth0

# Add a secondary default gateway (higher metric = lower priority)
ip route add default via 192.168.1.1 metric 100

# Remove a temporary IP
ip addr del 192.168.1.50/24 dev eth0

# Remove a temporary route
ip route del default via 192.168.1.1 metric 100

# Bring interface up/down
ip link set eth0 down
ip link set eth0 up
```

## Temporary DNS (non-persistent)

Lost on reboot unless `/etc/resolv.conf` is managed by systemd-resolved/NetworkManager.

```bash
# View current resolver
resolvectl status
cat /etc/resolv.conf

# systemd-resolved (RHEL/Ubuntu/Debian modern)
resolvectl dns eth0 8.8.8.8 1.1.1.1
resolvectl domain eth0 example.com
resolvectl flush-caches

# Fallback: edit /etc/resolv.conf directly (overwritten by resolvectl/NetworkManager on reboot)
# nameserver 8.8.8.8
# nameserver 1.1.1.1
# search example.com

# Test
getent hosts example.com
dig +short example.com
ping -c 3 example.com
```

## NetworkManager (RHEL/Ubuntu Server) — temporary via nmcli

```bash
nmcli connection show
nmcli connection modify eth0 ipv4.addresses 192.168.1.50/24
nmcli connection modify eth0 ipv4.gateway 192.168.1.1
nmcli connection modify eth0 ipv4.dns "8.8.8.8 1.1.1.1"
nmcli connection modify eth0 ipv4.ignore-auto-dns yes
nmcli connection up eth0
```

To make persistent: `nmcli connection modify eth0 connection.autoconnect yes` (already default) — changes in `nmcli connection modify` are written to disk immediately; they survive reboot unless you only used `ip`/`resolvectl`.

## Netplan (Ubuntu Server default) — temporary via ip, persistent via netplan

```bash
# Temporary (lost on reboot)
ip addr add 192.168.1.50/24 dev eth0
ip route add default via 192.168.1.1

# Persistent: edit /etc/netplan/*.yaml, then
netplan apply
```

## SysVinit/network service (older systems)

```bash
ifconfig eth0 192.168.1.50 netmask 255.255.255.0 up
route add default gw 192.168.1.1
# /etc/resolv.conf for DNS (may be overwritten)
service network restart   # reloads persistent config
```

## Verification

```bash
#!/bin/bash
set -u
echo "== addr =="; ip -br addr
echo "== route =="; ip route | grep default || true
echo "== dns =="; resolvectl status 2>/dev/null | head -5 || cat /etc/resolv.conf
echo "== test =="; getent hosts example.com && ping -c 2 -W 2 example.com
echo OK
```

## Safety

- Changes via `ip`/`route`/`resolvectl` vanish on reboot — intended for temporary use.
- Adding a second default gateway can break routing; use `metric` and remove when done.
- Editing `/etc/resolv.conf` directly may be overwritten by NetworkManager/systemd-resolved/Netplan on reboot or service restart.

---
<ponytail: Scope ceiling — temporary IP/DNS on Linux hosts only; add persistent Netplan/NetworkManager/sysconfig, bonding, VLAN, and DHCP client tuning when those are used.</ponytail>
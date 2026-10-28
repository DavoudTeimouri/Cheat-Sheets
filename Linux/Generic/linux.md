# Linux Troubleshooting

## 1. System won't boot / hangs at boot

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| dracut/initramfs emergency shell | Missing/corrupt initramfs, wrong root UUID in grub | Boot rescue ISO, `chroot`, `dracut -f`, regenerate grub config `grub2-mkconfig -o /boot/grub2/grub.cfg` (RHEL) or `update-grub` (Debian) |
| Kernel panic | Bad module/driver, hardware mismatch | Boot previous kernel from grub menu, remove offending module, rebuild initramfs |
| Filesystem read-only | Disk errors, dirty journal | `fsck -y /dev/<device>`, check `dmesg | grep -i error`, replace disk if SMART fails |

Verify boot messages:
```bash
journalctl -xb
dmesg | grep -iE 'fail|error|panic|i/o error'
```

## 2. Network unreachable

Check interfaces and IP:
```bash
ip addr
ip route
ip -br link
```
No IP on interface:
```bash
nmcli device                      # NetworkManager
systemctl restart NetworkManager  # RHEL
systemctl restart networking      # Debian/Ubuntu (ifdown/ifup)
```
DNS fails:
```bash
resolvectl status                 # systemd-resolved
cat /etc/resolv.conf
systemctl restart systemd-resolved
ping 1.1.1.1                      # isolate DNS vs routing
```

## 3. Disk full / inodes exhausted

```bash
df -h
df -i
du -ahx / | sort -rh | head -20   # biggest dirs on /
journalctl --vacuum-size=100M     # shrink logs
find /var/log -type f -exec truncate -s 0 {} +
```

## 4. Out of memory / OOM killer

```bash
free -h
ps aux --sort=-%mem | head -10
dmesg | grep -i 'killed process'   # find OOM victim
journalctl -k | grep -i oom
```
Fix: add swap, kill the consumer, tune `vm.swappiness`, or add RAM.

## 5. SSH connection refused / timeout

```bash
systemctl status sshd
systemctl restart sshd
ss -tlnp | grep 22
firewall-cmd --list-all   # firewalld
ufw status                # Ubuntu
tail -f /var/log/secure   # RHEL
tail -f /var/log/auth.log # Debian
```

## 6. systemd service fails

```bash
systemctl status <service>
journalctl -u <service> -n 100 --no-pager
systemctl restart <service>
systemctl enable --now <service>
```

## 7. High CPU load

```bash
top -b -n 1 | head -20
ps aux --sort=-%cpu | head -10
mpstat -P ALL 1   # sysstat
```
Find runaway process, `renice` or `kill -9 <pid>`, then investigate memory leaks or runaway loops.

## 8. Zombie / defunct processes

Zombies can't be killed — they wait for parent to reap:
```bash
ps aux | grep Z
ps -o ppid= -p <zombie-pid>   # find parent
kill <parent-pid>             # parent exits, init reaps zombie
```

## 9. Permission denied

```bash
ls -l /path
namei -l /path/to/file        # trace each component
getfacl /path                 # ACLs
ls -Z /path                   # SELinux context
ausearch -m avc -ts recent    # SELinux denials
setenforce 0                  # SELinux permissive (temporary, debug only)
```

## 10. Package manager stuck / locked

```bash
lsof /var/lib/dpkg/lock-frontend   # Debian
ps aux | grep -E 'apt|dnf|yum|pacman'
rm -f /var/lib/apt/lists/lock      # only if no apt/dpkg process running
dpkg --configure -a
```

## 11. Time drift / NTP

```bash
timedatectl
chronyc sources          # chrony
systemctl restart chronyd
ntpq -p                  # ntpd
```

## 12. Firewall blocking traffic

```bash
firewall-cmd --list-all          # firewalld
iptables -L -n -v                # nftables/iptables
ufw status verbose               # Ubuntu
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --reload
```

## Quick self-check

```bash
#!/bin/bash
set -euo pipefail
echo "== disk =="; df -h /
echo "== mem =="; free -h
echo "== sshd =="; systemctl is-active sshd || true
echo "== dns =="; getent hosts example.com || true
echo "OK"
```

---
<ponytail: Scope ceiling — covers common node-level Linux issues only; add application-layer tuning (kernel sysctl, IO scheduler, cgroups/v2) when a workload hits those limits.</ponytail>
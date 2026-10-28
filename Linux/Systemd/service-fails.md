# Linux Systemd Troubleshooting

## 1. Service fails to start

```bash
systemctl status <service>
journalctl -u <service> -n 100 --no-pager
systemctl restart <service>
systemctl enable --now <service>
```
- `Active: failed (Result: exit-code)`: check `ExecStart` path, permissions, environment file
- `Active: failed (Result: timeout)`: service hangs on start → increase `TimeoutStartSec` or fix the hang
- Dependency failed: `systemctl list-dependencies <service>`, fix the failing dependency first

## 2. System won't boot / emergency shell

```bash
journalctl -xb
dmesg | grep -iE 'fail|error|panic|i/o error'
```
- dracut/initramfs emergency shell: wrong root UUID in grub, missing initramfs → boot rescue ISO, `chroot`, `dracut -f`, `grub2-mkconfig -o /boot/grub2/grub.cfg` (RHEL) or `update-grub` (Debian)
- Kernel panic: boot previous kernel from grub menu, remove offending module, rebuild initramfs

## 3. journald logs missing / huge

```bash
journalctl --disk-usage
journalctl --vacuum-size=100M
journalctl --vacuum-time=3d
systemctl status systemd-journald
```
- journald not starting: `/var/log/journal` permissions (`chmod 2755 /var/log/journal`, `chown root:systemd-journal`)
- Logs rotated/lost: check `Storage=` in `/etc/systemd/journald.conf` (`persistent` vs `volatile`)

## 4. Timedate / NTP drift

```bash
timedatectl
chronyc sources            # chrony
systemctl restart chronyd
ntpq -p                    # ntpd
```
- Clock out of sync: NTP service down, firewall blocking UDP 123, or VM host time sync fighting guest NTP

---
<ponytail: Scope ceiling — systemd services and boot only; add containerized systemd, networkd, and resolved advanced config when those are managed by systemd.</ponytail>
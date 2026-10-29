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

## Timedate / NTP drift

```bash
timedatectl
chronyc sources            # chrony
systemctl restart chronyd
ntpq -p                    # ntpd
```
- Clock out of sync: NTP service down, firewall blocking UDP 123, or VM host time sync fighting guest NTP

## Service deep dive

```bash
# Status and dependency tree
systemctl status <service>
systemctl list-dependencies <service>
systemctl is-active <service>
systemctl is-enabled <service>

# Logs
journalctl -u <service> -n 100 --no-pager
journalctl -u <service> --since "1 hour ago" --no-pager

# Restart / enable
systemctl restart <service>
systemctl enable --now <service>
systemctl mask <service>      # hard disable (cannot be started manually)

# Timers (cron replacement)
systemctl list-timers --all
systemctl status <timer>.timer
```
- `Active: failed (Result: exit-code)` → check `ExecStart` path, permissions, environment file (`EnvironmentFile=`)
- `Active: failed (Result: timeout)` → service hangs on start; increase `TimeoutStartSec` in unit override: `systemctl edit <service>`
- Dependency failed → `systemctl list-dependencies <service>`, fix the failing dependency first

## Unit override example

```bash
systemctl edit <service>
# adds:
# [Service]
# TimeoutStartSec=300
# Restart=always
# RestartSec=5
systemctl daemon-reload
systemctl restart <service>
```

## Boot / emergency shell

```bash
journalctl -xb
dmesg \| grep -iE 'fail|error|panic|i/o error'
```
- dracut/initramfs emergency shell → wrong root UUID in grub, missing initramfs; boot rescue ISO, `chroot`, `dracut -f`, `grub2-mkconfig -o /boot/grub2/grub.cfg` (RHEL) or `update-grub` (Debian)
- Kernel panic → boot previous kernel from grub menu, remove offending module, rebuild initramfs

## journald

```bash
journalctl --disk-usage
journalctl --vacuum-size=100M
journalctl --vacuum-time=3d
systemctl status systemd-journald
```
- journald not starting → `/var/log/journal` permissions (`chmod 2755 /var/log/journal`, `chown root:systemd-journal`)
- Logs rotated/lost → check `Storage=` in `/etc/systemd/journald.conf` (`persistent` vs `volatile`)

## Verification

```bash
#!/bin/bash
set -u
svc="${1:-sshd}"
echo "== active =="; systemctl is-active "$svc" 2>/dev/null || true
echo "== enabled =="; systemctl is-enabled "$svc" 2>/dev/null || true
echo "== failed units =="; systemctl --failed --no-legend \| head -5 || true
echo OK
```

## Safety

- `systemctl mask` makes a unit impossible to start (even manually); use only for permanent removal.
- `systemctl restart` over SSH can drop the connection if restarting sshd itself; schedule carefully.

---

<ponytail: Scope ceiling — systemd services and boot only; add containerized systemd, networkd, and resolved advanced config when those are managed by systemd.</ponytail>
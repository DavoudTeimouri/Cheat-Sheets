# Linux Package Manager Troubleshooting

## 1. apt/dpkg locked (Debian/Ubuntu)

```bash
lsof /var/lib/dpkg/lock-frontend
ps aux | grep -E 'apt|dpkg|unattended'
rm -f /var/lib/apt/lists/lock        # only if NO apt/dpkg process running
dpkg --configure -a
apt-get update && apt-get upgrade
```
- `dpkg was interrupted`: `dpkg --configure -a`
- Unattended-upgrades holding lock: wait or `systemctl stop unattended-upgrades`

## 2. dnf/yum locked (RHEL/Rocky/Alma)

```bash
ps aux | grep -E 'dnf|yum|rpm'
rm -f /var/lib/dnf/.lock /var/lib/rpm/.db.lock   # only if no rpm/dnf process running
rpm --rebuilddb
dnf clean all
dnf makecache
```

## 3. Repository / GPG errors

```bash
apt-get update
dnf repolist
rpm --import <GPG-key>
```
- `The following signatures couldn't be verified`: import missing GPG key or fix `sources.list` URL
- 404 on repo: repo removed or OS version EOL → update to vault/archive mirrors

## 4. Held / broken packages

```bash
dpkg --get-selections | grep hold
apt-mark showhold
apt-get install -f
dnf history undo <id>
```
- Broken dependencies: `apt-get install -f`, `dnf repoquery --unsatisfied`
- Held package blocking upgrade: `apt-mark unhold <pkg>` or `dnf versionlock delete <pkg>`

---
<ponytail: Scope ceiling — apt/dnf/yum only; add pacman, zypper, and snap/flatpak when those package managers are used.</ponytail>
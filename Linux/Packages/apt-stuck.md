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

## Held / broken packages

```bash
dpkg --get-selections \| grep hold
apt-mark showhold
apt-get install -f
dnf history undo <id>
```
- Broken dependencies → `apt-get install -f`, `dnf repoquery --unsatisfied`
- Held package blocking upgrade → `apt-mark unhold <pkg>` or `dnf versionlock delete <pkg>`

## Repository priority / pinning

- Debian/Ubuntu: `/etc/apt/preferences.d/` pin releases (`Package: *`, `Pin: release a=stable`, `Pin-Priority: 900`)
- RHEL: `/etc/yum.repos.d/*.repo` `enabled=0` / `priority=` (with `yum-plugin-priorities`)
- Disable EOL repo → `dnf config-manager --disablerepo <repo>` or remove `.repo` file

## Local package operations

```bash
dpkg -i <package.deb>
dpkg -L <package>          # files owned by package
dpkg -S /path/to/file      # which package owns file
rpm -qiv <package>
rpm -ql <package>
rpm -qf /path/to/file
```

## Verification

```bash
#!/bin/bash
set -u
echo "== apt locks =="; lsof /var/lib/dpkg/lock-frontend 2>/dev/null || echo "no apt lock"
echo "== dnf locks =="; ps aux \| grep -E '[d]nf|[y]um' \| head -3 || true
echo "== held =="; apt-mark showhold 2>/dev/null || dnf versionlist 2>/dev/null \| head -5 || true
echo "== repos =="; dnf repolist 2>/dev/null \| wc -l || apt-cache policy 2>/dev/null \| head -3
echo OK
```

## Safety

- Deleting `/var/lib/dpkg/lock-frontend` while apt/dpkg is running corrupts the package database; confirm no process holds it first.
- `rpm --rebuilddb` on a large DB takes time; don't interrupt.

---

<ponytail: Scope ceiling — apt/dnf/yum only; add pacman, zypper, and snap/flatpak when those package managers are used.</ponytail>
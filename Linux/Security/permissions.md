# Linux Security Troubleshooting

## 1. Permission denied

```bash
ls -l /path
namei -l /path/to/file
getfacl /path
ls -Z /path                    # SELinux context
ausearch -m avc -ts recent     # SELinux denials
setenforce 0                   # SELinux permissive (temporary, debug only)
```
- Wrong owner/mode: `chown <user>:<group> <path>`, `chmod 644 <path>` / `755 <dir>`
- ACL blocking: `setfacl -m u:<user>:rwx <path>`
- SELinux denial: `audit2why < /var/log/audit/audit.log`, `restorecon -Rv /path`, or update policy

## 2. SELinux blocking service

```bash
getenforce
sestatus
ausearch -m avc -ts recent
sealert -a /var/log/audit/audit.log
```
- Service can't bind port or read files: SELinux context mismatch → `chcon -t <type> <path>` or `semanage fcontext -a -t <type> '<path>(/.*)?'` then `restorecon -Rv`
- Temporarily disable for testing: `setenforce 0` (re-enable with `setenforce 1` after fix)

## 3. AppArmor blocking

```bash
aa-status
cat /var/log/syslog | grep apparmor
ln -s /etc/apparmor.d/<profile> /etc/apparmor.d/disable/
apparmor_parser -R <profile>
```
- Profile in complain vs enforce mode: switch to enforce after fixing denials (`aa-enforce <profile>`)

## 4. Sudo / authentication fails

```bash
visudo
tail -f /var/log/secure          # RHEL
tail -f /var/log/auth.log        # Debian
getent passwd <user>
```
- User not in sudoers: add `%wheel ALL=(ALL) ALL` or user-specific rule via visudo
- PAM locked account: `passwd -S <user>`, `faillog --user <user>`, `usermod -U <user>` to unlock

## Sudo / authentication fails

```bash
visudo
tail -f /var/log/secure          # RHEL
tail -f /var/log/auth.log        # Debian
getent passwd <user>
```
- User not in sudoers → add `%wheel ALL=(ALL) ALL` or user-specific rule via visudo
- PAM locked account → `passwd -S <user>`, `faillog --user <user>`, `usermod -U <user>` to unlock

## Permission deep dive

```bash
ls -l /path
namei -l /path/to/file          # trace each component
getfacl /path                   # ACLs
ls -Z /path                     # SELinux context
ausearch -m avc -ts recent      # SELinux denials
setenforce 0                    # SELinux permissive (temporary, debug only)
```
- Wrong owner/mode → `chown <user>:<group> <path>`, `chmod 644 <path>` / `755 <dir>`
- ACL blocking → `setfacl -m u:<user>:rwx <path>`
- SELinux denial → `audit2why < /var/log/audit/audit.log`, `restorecon -Rv /path`, or update policy

## SELinux blocking service

```bash
getenforce
sestatus
ausearch -m avc -ts recent
sealert -a /var/log/audit/audit.log
```
- Service can't bind port or read files → SELinux context mismatch → `chcon -t <type> <path>` or `semanage fcontext -a -t <type> '<path>(/.*)?'` then `restorecon -Rv`
- Temporarily disable for testing → `setenforce 0` (re-enable with `setenforce 1` after fix)
- Make context persistent → `semanage fcontext -a -t httpd_sys_content_t '/var/www(/.*)?'` then `restorecon -Rv /var/www`

## AppArmor blocking

```bash
aa-status
cat /var/log/syslog \| grep apparmor
ln -s /etc/apparmor.d/<profile> /etc/apparmor.d/disable/
apparmor_parser -R <profile>
```
- Profile in complain vs enforce mode → switch to enforce after fixing denials (`aa-enforce <profile>`)

## Verification

```bash
#!/bin/bash
set -u
echo "== selinux =="; getenforce 2>/dev/null || echo "no selinux"
echo "== apparmor =="; aa-status 2>/dev/null \| head -3 || true
echo "== sudoers =="; sudo -n true 2>&1 && echo "passwordless sudo ok" || echo "sudo needs password"
echo OK
```

## Safety

- `setenforce 0` lowers security; re-enable immediately after debugging.
- Editing sudoers without `visudo` can lock out all admin access; always use `visudo` (syntax-checked).

---

<ponytail: Scope ceiling — local users, permissions, SELinux/AppArmor only; add LDAP/AD integration, Kerberos, and FIPS mode when enterprise auth is required.</ponytail>
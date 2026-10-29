# Others Ansible / cloud-init Troubleshooting

## 1. Ansible unreachable / module missing

```bash
ansible all -m ping
ansible-playbook --syntax-check site.yml
ansible-playbook -v site.yml
```
- Unreachable: SSH key, `ansible_user`, `ansible_port`, sudo password (`--become --ask-become-pass`), firewall
- Module missing on target: `python3`, `python3-apt`, `docker-py`, `openstacksdk`
- Idempotency broken: task uses `shell`/`command` without `creates`/`removes` — use dedicated modules

## 2. cloud-init

```bash
cat /var/log/cloud-init.log
cat /var/log/cloud-init-output.log
cloud-init status --long
cloud-init clean --logs --reboot   # re-run on next boot
```
- Network not configured: `network-config` wrong version (v1 vs v2), NIC names differ (`ens*` vs `eth*`)
- User-data not applied: instance launched without user-data, metadata service unreachable (`curl http://169.254.169.254/latest/meta-data/` on AWS)
- Modules failed: `cloud-init analyze show`, fix YAML syntax (`cloud-init deconstruct` / `devel schema`)

---
## Ansible deep dive

```bash
ansible all -m ping
ansible-playbook --syntax-check site.yml
ansible-playbook -v site.yml
```
- Unreachable → SSH key, `ansible_user`, `ansible_port`, sudo password (`--become --ask-become-pass`), firewall
- Module missing on target → `python3`, `python3-apt`, `docker-py`, `openstacksdk`
- Idempotency broken → task uses `shell`/`command` without `creates`/`removes`; use dedicated modules

## cloud-init

```bash
cat /var/log/cloud-init.log
cat /var/log/cloud-init-output.log
cloud-init status --long
cloud-init clean --logs --reboot   # re-run on next boot
```
- Network not configured → `network-config` wrong version (v1 vs v2), NIC names differ (`ens*` vs `eth*`)
- User-data not applied → instance launched without user-data, metadata service unreachable (`curl http://169.254.169.254/latest/meta-data/` on AWS)
- Modules failed → `cloud-init analyze show`; fix YAML syntax (`cloud-init deconstruct` / `devel schema`)

## Verification

```bash
#!/bin/bash
set -u
echo "== ansible =="; ansible --version 2>/dev/null \| head -1 || true
echo "== cloud-init =="; cloud-init status 2>/dev/null \| head -3 || true
echo OK
```

## Safety

- `cloud-init clean` wipes instance metadata; instance re-runs modules on next boot (may change config).

---

<ponytail: Scope ceiling — Ansible + cloud-init only; add Packer and cloud-init network-config v2 when those are used.</ponytail>
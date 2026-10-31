# Proxmox VE Host Troubleshooting

**Category:** Virtualization

## Symptom → Cause → Fix

| Exact symptom | Likely cause | Fix |
|---------------|--------------|-----|
| `apt` fails / 404 on enterprise repo | No subscription, using enterprise repo without key | Switch to `pve-no-subscription` repo in `/etc/apt/sources.list.d/pve-enterprise.list` |
| `pveversion` command not found | Not Proxmox VE, or path missing | Verify Proxmox VE installed; `/usr/bin/pveversion` |
| Cannot access web UI (8006) | pveproxy down, firewall, wrong IP | `systemctl status pveproxy`, check HTTPS 8006, firewall |
| Node not in cluster | Corosync ring0 issues, node not joined | `pvecm status`, `pvecm add <node>`, check corosync |
| Updates fail | Locked packages, partial upgrade | `apt update && apt full-upgrade`, check `dpkg --configure -a` |

## Diagnosis

```bash
# Proxmox version & subscription
pveversion
cat /etc/pve/.version 2>/dev/null || true

# Services
systemctl status pve-cluster pvestatd pveproxy pvedaemon 2>/dev/null || true
systemctl status corosync 2>/dev/null || true

# Cluster
pvecm status
pvecm nodes
pvecm status --quiet

# APT sources
cat /etc/apt/sources.list.d/pve-enterprise.list 2>/dev/null || true
cat /etc/apt/sources.list 2>/dev/null || true
apt update

# Web UI port
ss -tlnp | grep 8006
```

## Subscription repository deep dive

- **Enterprise repo** → requires valid subscription; `apt` fails without valid key/subscription
- **No-subscription repo** → `deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription` (no subscription needed, community)
- Switch: comment out enterprise line, add no-subscription line, `apt update`

## Update deep dive

- Proxmox VE uses Debian base + Proxmox packages; always `apt full-upgrade` (not `upgrade`) to handle dependency changes
- Reboot after kernel/proxmox-kernel updates
- Backup VMs/CTs before major version upgrades

## Verification

```bash
#!/bin/bash
set -u
echo "== pveversion =="; pveversion 2>/dev/null || true
echo "== pve services =="; systemctl is-active pve-cluster pvestatd pveproxy 2>/dev/null || true
echo "== apt update =="; apt-get update 2>&1 | tail -3 || true
echo OK
```

## Safety

- `apt full-upgrade` may restart services; schedule in maintenance window.
- Changing `/etc/apt/sources.list.d/pve-enterprise.list` affects all nodes; update consistently.

---
<ponytail: Scope ceiling — Proxmox VE host + updates only; add Proxmox VE firewall, SDN, and user management when those are used.</ponytail>
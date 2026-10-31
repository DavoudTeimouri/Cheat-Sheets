# Proxmox VE Cluster Troubleshooting

**Category:** Virtualization

## Symptom → Cause → Fix

| Exact symptom | Likely cause | Fix |
|---------------|--------------|-----|
| Node not in cluster | Corosync not running, ring0 mismatch, node not joined | `pvecm status`, `pvecm add <node>`, check `/etc/pve/corosync.conf` |
| Quorum lost | Fewer than majority nodes up, split-brain | Restart nodes, `pvecm expected 1` (emergency only), fix network |
| HA resources failed | HA manager down, resource misconfigured | `ha-manager status`, `ha-manager debug`, fix resource config |
| Backup sync fails | Target node unreachable, auth mismatch, storage mismatch | Check sync job, source/target storage, SSH keys |

## Diagnosis

```bash
# Cluster status
pvecm status
pvecm nodes
pvecm nodes --quiet
pvecm status --quiet

# Corosync
systemctl status corosync
corosync-cmapctl -s 2>/dev/null || true
cat /etc/corosync/corosync.conf 2>/dev/null || true
cat /etc/pve/corosync.conf 2>/dev/null || true

# HA
ha-manager status
ha-manager debug
cat /etc/pve/ha/resources.cfg 2>/dev/null || true

# Cluster config
ls /etc/pve/
cat /etc/pve/.version 2>/dev/null || true
```

## Corosync ring deep dive

- **ring0** → primary cluster communication; all nodes must agree
- **split-brain** → network partition, quorum lost; emergency: `pvecm expected 1` on one node (dangerous)
- **Multicast vs unicast** → corosync.conf uses `transport: udpu` (multicast) or `udp` (unicast); unicast needs `ring0_addr`/`bindnetaddr`

## HA deep dive

- **HA manager** → `pve-ha-manager` service manages VM/CT failover
- **Resources** → defined in `/etc/pve/ha/resources.cfg`; `ha-manager add <rid> <vmid> --state started`
- **States** → `started`, `stopped`, `disabled`; `ha-manager set <rid> --state started`

## Backup sync

- Proxmox Backup Server sync between nodes; requires PBS datastore access from both
- Check sync jobs: `/etc/pve/vzdump.cron`, PBS tasks

## Verification

```bash
#!/bin/bash
set -u
echo "== pvecm status =="; pvecm status 2>/dev/null || true
echo "== pvecm nodes =="; pvecm nodes 2>/dev/null || true
echo "== ha-manager =="; ha-manager status 2>/dev/null || true
echo "== corosync =="; systemctl is-active corosync 2>/dev/null || true
echo OK
```

## Safety

- `pvecm expected 1` forces quorum with one node; dangerous in multi-node (split-brain data loss). Only for single-node recovery.
- Removing a node from cluster requires `pvecm delnode <node>`; VMs on it must be migrated first.

---
<ponytail: Scope ceiling — Proxmox VE cluster + HA only; add Proxmox VE SDN, firewall, and user/ACL management when those are used.</ponytail>
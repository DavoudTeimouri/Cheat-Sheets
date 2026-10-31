# Proxmox VE Troubleshooting

**Category:** Virtualization

## Subgroups

| Subgroup | Sheet | Covers |
|----------|-------|--------|
| Host | [Host/host.md](Host/host.md) | Installation, subscription repo, apt, updates |
| VM | [VM/vm.md](VM/vm.md) | VM lifecycle, qm commands, guests, cloud-init |
| Storage | [Storage/storage.md](Storage/storage.md) | Storage pools, LVM, ZFS, Ceph, ISOs |
| Cluster | [Cluster/cluster.md](Cluster/cluster.md) | Corosync, HA, backup sync, quorum |

## Quick self-check

```bash
#!/bin/bash
set -u
echo "== pve version =="; pveversion 2>/dev/null || true
echo "== pve services =="; systemctl is-active pve-cluster pvestatd pveproxy 2>/dev/null || true
echo "== nodes =="; pvecm status 2>/dev/null || true
echo OK
```

---
<ponytail: Scope ceiling — Proxmox VE host/VM/storage/cluster only; add Proxmox Backup Server (separate product) when that is used.</ponytail>
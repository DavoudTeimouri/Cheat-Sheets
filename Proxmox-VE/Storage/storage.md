# Proxmox VE Storage Troubleshooting

**Category:** Virtualization

## Symptom → Cause → Fix

| Exact symptom | Likely cause | Fix |
|---------------|--------------|-----|
| Storage pool inactive | Service down, path missing, permissions | `pvesm status`, `pvesm activate <storage>`, check path/mount |
| VM disk allocation fails | Pool full, thin provisioning overcommit, no space | `pvesm status`, expand pool, add disk, enable thin |
| ISO/template not visible | Wrong path, permissions, not scanned | `pvesm scan <storage>`, check `/var/lib/vz/template/iso` |
| Ceph storage slow | CRUSH rules, OSD down, network | `ceph -s`, `ceph osd tree`, check `ceph health` |
| LVM-thin pool full | Thin pool metadata/data full | `lvextend` thin pool, remove old snapshots/backups |

## Diagnosis

```bash
# Storage pools
pvesm status
pvesm scan <storage>
pvesm path <storage>:<filename>

# Config
cat /etc/pve/storage.cfg

# LVM (if LVM-thin)
vgs
lvs
pvs

# Ceph (if Ceph storage)
ceph -s
ceph osd tree
ceph df

# ZFS (if ZFS)
zpool status
zfs list
```

## Storage types

- **dir** → directory on host filesystem; simplest, good for backups/ISOs
- **lvmthin** → LVM thin provisioning; good performance, overcommit possible
- **zfs** → ZFS dataset; snapshots, compression, replication
- **cephfs** → CephFS shared storage; for HA/live migration
- **rbd** → Ceph RBD block storage; high performance block
- **iscsi** → iSCSI LUNs; needs initiator configured

## pvesm commands

```bash
pvesm status
pvesm scan <storage>
pvesm path <storage>:<filename>
pvesm alloc <storage> <vmid> <filename> <size>
pvesm remove <storage>:<filename>
```

## Storage config (`/etc/pve/storage.cfg`)

```ini
dir: local
    path /var/lib/vz
    content iso,vztmpl,backup

lvmthin: local-lvm
    thinpool data
    vgname pve
    content rootdir,images

cephrbd: ceph-rbd
    monhost 10.0.0.1 10.0.0.2 10.0.0.3
    pool rbd
    content images
    krbd 0
```

## Verification

```bash
#!/bin/bash
set -u
echo "== pvesm status =="; pvesm status 2>/dev/null || true
echo "== storage.cfg =="; cat /etc/pve/storage.cfg 2>/dev/null || true
echo "== pools (LVM) =="; pvs 2>/dev/null | head -5 || true
echo OK
```

## Safety

- Thin provisioning overcommit can fill physical disk; monitor `pvesm status` and LVM thin pool metadata.
- Removing a storage with active VMs causes I/O errors; migrate VMs first.

---
<ponytail: Scope ceiling — Proxmox VE storage pools + pvesm only; add Ceph integration details, ZFS replication, and storage migration when those are used.</ponytail>
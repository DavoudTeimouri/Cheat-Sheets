# KVM Storage Troubleshooting

**Category:** Virtualization

## Symptom → Cause → Fix

| Exact symptom | Likely cause | Fix |
|---------------|--------------|-----|
| VM disk read-only | Disk image permissions, snapshot chain, pool inactive | `chown libvirt-qemu:kvm`, `virsh pool-start <pool>`, collapse snapshots |
| qcow2 corrupt | Power loss, host crash, double-write | `qemu-img check`, `qemu-img repair` (destructive), restore from backup |
| Storage pool inactive | `virsh pool-list --all` shows inactive | `virsh pool-start <pool>`, `virsh pool-autostart <pool>` |
| No space on qcow2 | Sparse file grew, host disk full | `qemu-img resize`, expand host disk, collapse internal snapshots |
| Slow disk performance | No virtio, wrong cache/io, snapshot chain deep | `model='virtio'`, `cache='writeback'`, `io='native'`, `virsh blockcommit` |

## Diagnosis

```bash
# Storage pools
virsh -c qemu:///system pool-list --all
virsh -c qemu:///system pool-dumpxml default
virsh -c qemu:///system vol-list default

# Disk image
qemu-img info /var/lib/libvirt/images/<vm>.qcow2
qemu-img check /var/lib/libvirt/images/<vm>.qcow2

# Host disk
df -h /var/lib/libvirt/images
lsblk
```

## Pool types

- **`dir`** → directory on host filesystem; simplest
- **`logical` (LVM)** → LVM volumes as disks; good performance
- **`netfs`** → NFS/GlusterFS shared storage; for live migration
- **`disk`** → raw block device; direct access
- **`iscsi`** → iSCSI LUNs; needs initiator

## virsh volume commands

```bash
virsh -c qemu:///system vol-create-as default <name> <size> --format qcow2
virsh -c qemu:///system vol-delete <vol> --pool default
virsh -c qemu:///system vol-resize <vol> <newsize> --pool default
virsh -c qemu:///system vol-clone <src> <dst> --pool default
```

## Snapshot chain

```bash
virsh -c qemu:///system snapshot-list <vm>
virsh -c qemu:///system blockcommit <vm> vda --base --active --verbose --pivot
```
- Deep snapshot chains slow reads; collapse with `blockcommit` when idle or shutdown.

## Verification

```bash
#!/bin/bash
set -u
echo "== pools =="; virsh -c qemu:///system pool-list --all 2>/dev/null || true
echo "== images =="; virsh -c qemu:///system vol-list default 2>/dev/null | head -5 || true
echo "== host disk =="; df -h /var/lib/libvirt/images 2>/dev/null || true
echo OK
```

## Safety

- `qemu-img repair` can destroy data; use on a copy first, or have backups.
- `vol-delete` removes the qcow2 file; destructive, confirm before running.

---
<ponytail: Scope ceiling — KVM/libvirt storage pools + qcow2 only; add NFS/Gluster shared storage, iSCSI, and live migration storage when those are used.</ponytail>
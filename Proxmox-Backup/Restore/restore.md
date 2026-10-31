# Proxmox Backup Restore Troubleshooting

**Category:** Virtualization

## Symptom → Cause → Fix

| Exact symptom | Likely cause | Fix |
|---------------|--------------|-----|
| Snapshot not found | Wrong datastore/VMID/snapshot name | `proxmox-backup-client snapshot list`, verify exact name/case |
| VM won't boot after restore | Wrong disk/boot config, guest agent missing, network changed | `qm config <vmid>`, fix boot order, check network config |
| CT won't start after restore | Wrong rootfs, features missing, network config | `pct config <vmid>`, check `rootfs`, `features`, network |
| Encrypted restore fails | Missing `.fingerprint` file or wrong password | Provide fingerprint file (`-fingerprint`), correct password |
| Target VM/CT exists | Restore refuses to overwrite | Use different VMID/CTID, or delete target first |

## Diagnosis

```bash
# List available backups
proxmox-backup-client snapshot list root@pam!token@<host>:<datastore>
proxmox-backup-client snapshot list root@pam!token@<host>:<datastore>/vm/100
proxmox-backup-client snapshot list root@pam!token@<host>:<datastore>/ct/100

# Restore VM
proxmox-backup-client restore root@pam!token@<host>:<datastore>/vm/<vmid>/<snapshot> --target <target-host> --storage <storage>

# Restore CT
proxmox-backup-client restore root@pam!token@<host>:<datastore>/ct/<ctid>/<snapshot> --target <target-host> --storage <storage>

# Granular file restore (mount backup)
proxmox-backup-client mount root@pam!token@<host>:<datastore>/vm/<vmid>/<snapshot> /mnt/backup
```

## Restore targets

- **PVE target** → restore directly to a Proxmox VE node via `--target` (node name) and `--storage`
- **File target** → restore to a local directory; manually attach disks to VM/CT
- **Mount** → mount backup as FUSE filesystem; copy individual files out

## Post-restore checklist

- **VM** → `qm config <vmid>`, verify `boot`, `scsi`/`virtio` disk paths, `network0`, `ostype`
- **CT** → `pct config <vmid>`, verify `rootfs`, `features`, `network0`, `ostype`
- **Network** → source network config may not match target; adjust IP/bridge
- **Guest agent** → reinstall/verify `qemu-guest-agent` for graceful operations

## Verification

```bash
#!/bin/bash
set -u
echo "== snapshot list =="; proxmox-backup-client snapshot list "${PBS_URL}" 2>&1 | head -5 || true
echo "== target pvesm =="; pvesm status 2>/dev/null | head -5 || true
echo OK
```

## Safety

- Restoring over an existing VM/CT destroys its current data; use a new ID or delete first.
- Restored VMs may start with old IP addresses/MACs; check for network conflicts.

---
<ponytail: Scope ceiling — PBS restore + post-restore checklist only; add encrypted backup key rotation and granular file recovery when those are used.</ponytail>
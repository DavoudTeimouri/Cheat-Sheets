# Proxmox Backup Server Troubleshooting

**Category:** Virtualization

## Symptom → Cause → Fix

| Exact symptom | Likely cause | Fix |
|---------------|--------------|-----|
| Cannot create datastore | Path missing, permissions, mount not ready | `ls -la /mnt/...`, `chown backup:backup`, `mount -a`, `proxmox-backup-manager datastore create` |
| Backup job fails auth | Wrong API token, user lacks `Datastore.Backup` privilege | Create API token in PBS UI, assign role `Datastore.Backup` |
| Restore fails | Snapshot not found, encryption key missing, target busy | Verify snapshot name, provide `.fingerprint`/key, stop target VM |
| Prune not running | Schedule missing, retention too low/too high | Check `vzdump` cron / PBS prune job, adjust retention |
| Verify fails | Backup corrupt, chunk missing, datastore issue | `proxmox-backup-client verify`, check datastore health |

## Diagnosis

```bash
# PBS version & services
proxmox-backup-manager version
systemctl status proxmox-backup-proxy proxmox-backup-rest-server 2>/dev/null || true

# Datastores
proxmox-backup-manager datastore list 2>/dev/null || true
pvesm status | grep backup 2>/dev/null || true

# API tokens
proxmox-backup-manager user token list root@pam 2>/dev/null || true

# Logs
journalctl -u proxmox-backup-proxy -u proxmox-backup-rest-server -n 100 --no-pager
/var/log/proxmox-backup/  # task logs

# Datastore paths
ls -la /var/lib/proxmox-backup/  # default datastore root
```

## Datastore deep dive

- **datastore** → top-level backup container; has `path` on host, `prune`/`verify` schedules
- **snapshot** → point-in-time backup of VM/CT; incremental via deduplication
- **prune** → removes old snapshots per retention (keep-daily, keep-weekly, keep-monthly, keep-yearly)
- **verify** → reads all chunks, detects corruption; schedule regularly

## Datastore config (`/etc/proxmox-backup/datastore.cfg`)

```ini
datastore: main
    path /var/lib/proxmox-backup/main
    comment Primary backup datastore
    prune-backups keep-daily=7 keep-weekly=4 keep-monthly=1
    verify-new-backups 1
```

## API token deep dive

- Backup clients (PVE, PBS client) authenticate via API token
- Create: `proxmox-backup-manager user token create root@pam <tokenname>`
- Format: `root@pam!tokenname=<value>`; use in `--password` or `PROXMOX_BACKUP_PASSWORD`
- Privileges: `Datastore.Backup`, `Datastore.Read`, `Datastore.Audit`, `Datastore.Allocate`

## Verification

```bash
#!/bin/bash
set -u
echo "== pbs version =="; proxmox-backup-manager version 2>/dev/null || true
echo "== services =="; systemctl is-active proxmox-backup-proxy proxmox-backup-rest-server 2>/dev/null || true
echo "== datastores =="; proxmox-backup-manager datastore list 2>/dev/null || true
echo OK
```

## Safety

- Prune deletes snapshots permanently; verify retention before enabling.
- Encryption: if you lose the `.fingerprint` file/password, backups are unrecoverable; store off-site.

---
<ponytail: Scope ceiling — PBS server + datastore/prune/verify only; add Proxmox Backup Server encryption key management and multi-datastore sync when those are used.</ponytail>
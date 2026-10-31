# Proxmox Backup Client Troubleshooting

**Category:** Virtualization

## Symptom → Cause → Fix

| Exact symptom | Likely cause | Fix |
|---------------|--------------|-----|
| `401 Unauthorized` | Wrong API token, token expired, missing privilege | Regenerate token, check `Datastore.Backup` privilege |
| `403 Forbidden` | User lacks access to datastore | Add user to datastore with `Datastore.Backup` or `Datastore.Read` |
| Backup slow | Network, encryption, chunking, dedup overhead | Check network, tune `--chunk-size`, verify dedup working |
| Restore fails | Snapshot name wrong, encryption key missing, target in use | Verify snapshot via `proxmox-backup-client snapshot list`, provide key |

## Diagnosis

```bash
# Client version
proxmox-backup-client version

# List snapshots in datastore
proxmox-backup-client snapshot list root@pam!token@<host>:<datastore>

# Backup a VM/CT (from PVE host)
vzdump <vmid> --storage <pbs-datastore> --mode snapshot --compress zstd

# Restore
proxmox-backup-client restore root@pam!token@<host>:<datastore>/vm/<vmid>/<snapshot> /mnt/restore

# Verify
proxmox-backup-client verify root@pam!token@<host>:<datastore>/vm/<vmid>/<snapshot>
```

## API token format

- `root@pam!tokenname=<value>` → use as `--password` or set `PROXMOX_BACKUP_PASSWORD`
- Token created on PBS: `proxmox-backup-manager user token create root@pam <tokenname>`
- Store token securely; it grants datastore access

## Remotes

- **PBS remote** → sync backups to another PBS; `proxmox-backup-manager remote add <name> <url>`
- **Verify remote** → periodic integrity check of synced data

## Verification

```bash
#!/bin/bash
set -u
echo "== pbs-client version =="; proxmox-backup-client version 2>/dev/null || true
echo "== snapshot list =="; proxmox-backup-client snapshot list "${PBS_URL}" 2>&1 | head -5 || true
echo OK
```

## Safety

- Backup/restore over WAN is slow; use local PBS where possible, or WAN compression.
- Encryption keys/fingerprints: losing them = losing backups; export and store offline.

---
<ponytail: Scope ceiling — PBS client + snapshots/verify only; add scheduled backup jobs via cron and WAN optimization when those are used.</ponytail>
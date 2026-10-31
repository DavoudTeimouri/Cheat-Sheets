# Proxmox Backup Troubleshooting

**Category:** Virtualization

## Subgroups

| Subgroup | Sheet | Covers |
|----------|-------|--------|
| Server | [Server/server.md](Server/server.md) | PBS server, datastore, prune, verify |
| Client | [Client/client.md](Client/client.md) | proxmox-backup-client, proxy, remotes |
| Restore | [Restore/restore.md](Restore/restore.md) | Restore VMs/CTs, granular restore |

## Quick self-check

```bash
#!/bin/bash
set -u
echo "== pbs version =="; proxmox-backup-manager version 2>/dev/null || true
echo "== pbs services =="; systemctl is-active proxmox-backup-proxy proxmox-backup-rest-server 2>/dev/null || true
echo "== datastores =="; proxmox-backup-manager datastore list 2>/dev/null || true
echo OK
```

---
<ponytail: Scope ceiling — Proxmox Backup Server + client/restore only; add Proxmox Backup Client scheduling and encryption when those are used.</ponytail>
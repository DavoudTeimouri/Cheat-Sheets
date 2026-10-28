# Veeam Backup Troubleshooting

## 1. Backup job fails: "Failed to create snapshot" / VMware snapshot issues

- Snapshot consolidation needed: consolidate in vCenter (Right-click VM > Snapshot > Consolidate), then rerun job
- Snapshot limit exceeded (max 32 per VM): delete old snapshots manually
- VMTools outdated: install/open-vm-tools latest; quiesced backups need current tools
- Disk independent/persistent mode excluded from snapshots → change disk mode or exclude from job
- Datastore full: free space (old snapshots, logs) or storage vMotion
- CBT (Changed Block Tracking) disabled or stuck: `Set-VHvSnapshot -EnableChangedBlockTracking $true` via PowerCLI, or VM hardware version too old — upgrade VM compatibility

PowerCLI check:
```powershell
Get-VM <vm> | Get-Snapshot | Select-Object Name,Created,SizeMB
```

## 2. Changed Block Tracking (CBT) problems

- Full backup every run: CBT disabled or reset after VM clone/template deploy, snapshot with memory, or ESXi upgrade
- PowerCLI reset:
```powershell
Get-VM <vm> | Set-VHvSnapshot -EnableChangedBlockTracking $false
Get-VM <vm> | Set-VHvSnapshot -EnableChangedBlockTracking $true
```
- VM compatibility version: ESXi 6.5+ hardware version 13+ for CBT reliability

---
<ponytail: Scope ceiling — VMware snapshots + CBT only; add Veeam Backup for AWS/Azure and M365 when those workloads are protected.</ponytail>
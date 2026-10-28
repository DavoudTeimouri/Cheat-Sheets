# Veeam Backup & Replication Troubleshooting

**Category:** Data Protection
## 1. Backup job fails: "Failed to create snapshot" / VMware snapshot issues

- Snapshot consolidation needed: consolidate in vCenter (Right-click VM > Snapshot > Consolidate), then rerun job
- Snapshot limit exceeded (max 32 per VM): delete old snapshots manually
- VMTools outdated: install/open-vm-tools latest, quiesced backups need current tools
- Disk independent/persistent mode excluded from snapshots → change disk mode or exclude from job
- Datastore full: free space (old snapshots, logs) or storage vMotion
- CBT (Changed Block Tracking) disabled or stuck: `Set-VHvSnapshot -EnableChangedBlockTracking $true` via PowerCLI, or VM hardware version too old — upgrade VM compatibility

PowerCLI check:
```powershell
Get-VM <vm> | Get-Snapshot | Select-Object Name,Created,SizeMB
```

## 2. Backup repository out of space

- `df -h` on Linux repository (ext4/xfs) or `Get-PSDrive` on Windows repo
- Retention too high: lower restore points in job settings
- Backup files locked by old job: `taskmgr` → Veeam agent processes, or restart Veeam Backup Service
- Dedupe store corrupted (Windows repo with dedupe): run health check, defrag, or move VBK/VIB to new repository and rescan

## 3. Changed Block Tracking (CBT) problems

- Full backup every run: CBT disabled or reset after VM clone/template deploy, snapshot with memory, or ESXi upgrade
- PowerCLI reset:
```powershell
Get-VM <vm> | Set-VHvSnapshot -EnableChangedBlockTracking $false
Get-VM <vm> | Set-VHvSnapshot -EnableChangedBlockTracking $true
```
- VM compatibility version: ESXi 6.5+ hardware version 13+ for CBT reliability

## 4. Proxy / transport mode failures

- HotAdd failed: proxy lacks SCSI controller access to datastore, VM has independent disks, vStorage APIs for Array Integration (VAAI) off, EFI/paravirtual SCSI mismatch — fall back to Network Block Device (NBD) or NBDSSL
- NBDSSL slow: add more proxies, enable LAN-free where possible, check proxy network (10Gb)
- Direct SAN / Direct NFS: storage must present LUNs/NFS to proxy, zoning correct, `vmhba` sees LUN

## 5. VMware backup: "Error: VM is being replicated" / job locking

- Another job holds the VM: wait for it to finish, or stop the conflicting job
- Veeam backup service database locked: restart `VeeamBackupSVC` on backup server
- Stale snapshot from failed job: remove via vCenter, verify no `*-delta.vmdk` remain

## 6. Backup copy / replication job fails

- WAN acceleration: cache on source/target full → clear cache, check `VssSvc` on target
- Replica VM missing: target datastore space, ESXi license limits, target VM powered on with snapshots
- Seed drive: ensure seed VM disks are in correct folder and datastore, checksum matches

## 7. SureBackup / replica verification fails

- Virtual lab network conflict: proxy appliance needs DNS, DHCP, or static IPs; app-group VMs isolated from production
- Application checks fail: credentials wrong, app not listening, timeout too low — increase `Application Timeout`
- VM starts but check script times out: check `vcredist`, PowerShell remoting, WinRM on guest

## 8. Veeam Agent for Windows/Linux

- Windows: `VeeamEndpointBackupSVC` stopped → `net start VeeamEndpointBackupSVC`; VSS errors → `vssadmin list writers`, fix failed writers (often SQL, Hyper-V, or shadow storage too small)
- Linux: `veeamservice` status, `/var/log/veeam/`, kernel headers required for transport mode driver (`dkms`/`kernel-devel`)
- Mount backup fails: `veeamconfig mount` needs root, `mount point busy` → unmount first

## 9. Encryption / repository encryption

- Forgotten encryption password: unrecoverable — Veeam has no backdoor; store in password manager
- Backup files encrypted but key lost: data lost
- Rotate keys: re-encrypt jobs with new key, old backups remain under old key (keep it)

## 10. Database logs not truncating (SQL/Oracle/Exchange)

- VSS writer failed: `vssadmin list writers` → failed writer → restart service, increase shadow storage (`vssadmin add shadowstorage`)
- Transaction log full: run log backup via Veeam or natively (`BACKUP LOG ... WITH TRUNCATE_ONLY` deprecated — use proper log backups)
- Exchange: circular logging enabled disables granular truncation — disable for Veeam-aware backups

## Log locations

- Windows: `C:\ProgramData\Veeam\Backup\<hostname>\` (Jobs, Tasks, Debug, Proxy)
- Linux repository/proxy: `/var/log/veeam/`, `/var/log/veeam/backup/`
- Event Viewer: Applications and Services Logs > Veeam

## Quick self-check

```powershell
$ErrorActionPreference='SilentlyContinue'
Write-Host "== Veeam service =="; Get-Service VeeamBackupSvc,VeeamTransportSvc | Select-Object Name,Status
Write-Host "== repo space =="; Get-PSDrive C | Select-Object Used,Free @{N='FreeGB';E={[math]::Round($_.Free/1GB,2)}}
Write-Host "== CBT check =="; Get-VM * | Select-Object Name,@{N='CBT';E={$_.ExtensionData.Config.ChangeTrackingEnabled}} | Select-Object -First 5
Write-Host OK
```

---
<ponytail: Scope ceiling — VMware vSphere backups, repo, proxies, agents, replication; add Nutanix AHV, Hyper-V, AWS/Azure/Amazon S3 object storage, and Veeam Backup for Microsoft 365 when those platforms are protected.</ponytail>
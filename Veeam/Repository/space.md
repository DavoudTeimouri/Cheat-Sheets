# Veeam Repository Troubleshooting

## 1. Backup repository out of space

- `df -h` on Linux repository (ext4/xfs) or `Get-PSDrive` on Windows repo
- Retention too high: lower restore points in job settings
- Backup files locked by old job: Task Manager → Veeam agent processes, or restart Veeam Backup Service
- Dedupe store corrupted (Windows repo with dedupe): run health check, defrag, or move VBK/VIB to new repository and rescan

## Veeam repository space

```powershell
df -h
Get-PSDrive C
```
- Retention too high → lower restore points
- Backup files locked → restart Veeam Backup Service
- Dedupe store corrupted → health check, defrag, move VBK/VIB to new repository and rescan

## Verification

```powershell
$ErrorActionPreference='SilentlyContinue'
Write-Host "== repo space =="; Get-PSDrive C \| Select-Object Used,Free @{N='FreeGB';E={[math]::Round($_.Free/1GB,2)}}
Write-Host OK
```

## Safety

- Moving VBK/VIB invalidates incrementals in the chain until a new full backup runs.

---

<ponytail: Scope ceiling — repository space + dedupe only; add scale-out repository, object storage, and archive tiers when those are configured.</ponytail>
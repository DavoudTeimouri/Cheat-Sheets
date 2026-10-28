# Veeam Repository Troubleshooting

## 1. Backup repository out of space

- `df -h` on Linux repository (ext4/xfs) or `Get-PSDrive` on Windows repo
- Retention too high: lower restore points in job settings
- Backup files locked by old job: Task Manager → Veeam agent processes, or restart Veeam Backup Service
- Dedupe store corrupted (Windows repo with dedupe): run health check, defrag, or move VBK/VIB to new repository and rescan

---
<ponytail: Scope ceiling — repository space + dedupe only; add scale-out repository, object storage, and archive tiers when those are configured.</ponytail>
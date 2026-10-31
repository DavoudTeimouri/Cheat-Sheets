# SMART Disk Health Troubleshooting

**Category:** Hardware

## Symptom → Cause → Fix

| Exact symptom | Likely cause | Fix |
|---------------|--------------|-----|
| Disk slow / I/O errors | Developing bad sectors, controller retry | `smartctl -a`, replace if `Reallocated_Sector_Ct` rising |
| SMART not available | RAID controller hides disks, NVMe needs `-d nvme`, USB bridge | Use `smartctl -d megaraid,N`, `-d nvme`, or vendor tool |
| Pre-fail attribute worsened | Drive failing soon | Backup immediately, replace drive |
| Drive offline in RAID | SMART trip, failed write, bad sector | Replace drive, rebuild array |
| Cannot read SMART from enclosure | JAB/ enclosure doesn't pass SMART | Use vendor enclosure tool or direct-attached disk |

## Diagnosis

```bash
# Check smartctl installed
which smartctl || (apt-get install smartmontools || yum install smartmontools)

# Scan all disks
smartctl --scan
smartctl --scan --scan-options

# Basic health
smartctl -a /dev/sda
smartctl -H /dev/sda          # health only (PASSED/FAILED)
smartctl -i /dev/sda          # info only

# NVMe
smartctl -a /dev/nvme0n1
smartctl -a /dev/nvme0 -d nvme

# RAID passthrough (MegaRAID)
smartctl -a /dev/sda -d megaraid,N    # N = slot number
smartctl -a /dev/sda -d megaraid,0
smartctl -a /dev/sda -d megaraid,1

# 3ware
smartctl -a /dev/twa0 -d 3ware,N

# Areca
smartctl -a /dev/sgX -d areca,N

# HBA (IT mode) - direct
smartctl -a /dev/sda

# Extended self-test (takes minutes-hours)
smartctl -t long /dev/sda
smartctl -t short /dev/sda
smartctl -c /dev/sda            # check self-test status

# Selective self-test (faster)
smartctl -t select,50-100 /dev/sda

# Error log
smartctl -l error /dev/sda
smartctl -l selftest /dev/sda

# SMART attributes data structure
smartctl -A /dev/sda
smartctl -A /dev/sda | grep -iE 'realloc|pending|uncorrect|seek|crc|timeout'
```

## Key SMART attributes (pre-fail)

| Attribute | ID | Meaning | Action if worsening |
|-----------|-----|---------|---------------------|
| Reallocated_Sector_Ct | 5 | Sectors remapped to spare | Rising = disk failing, replace |
| Reallocated_Event_Count | 196 | Remap events | Rising = ongoing degradation |
| Current_Pending_Sector | 197 | Unstable sectors, not yet remapped | Non-zero = backup, run long test |
| Offline_Uncorrectable | 198 | Uncorrectable errors | Non-zero = data loss risk, replace |
| UDMA_CRC_Error_Count | 7 | Cable/interface errors | Rising = bad cable/port, not disk |
| Spin_Retry_Count | 6 | Spin-up retries | Rising = mechanical failure |
| Power_On_Hours | 9 | Age | Compare to warranty/rating |
| Temperature_Celsius | 194 | Drive temp | Sustained high = cooling issue |

## NVMe SMART (different namespace)

```bash
smartctl -a /dev/nvme0n1
# Critical fields:
#   Critical_Warning
#   Temperature
#   Available_Spare / Available_Spare_Thresh
#   Percentage_Used
#   Data_Units_Written / Read
#   Media_and_Data_Integrity_Errors
#   Error_Information Log Entries
```

## RAID controller SMART passthrough examples

| Controller | smartctl device type |
|------------|---------------------|
| LSI/Broadcom MegaRAID | `megaraid,N` (slot N) |
| 3ware | `3ware,N` |
| Areca | `areca,N` |
| HPE Smart Array (CCISS) | `cciss,N` |
| Direct HBA / JBOD | direct `/dev/sdX` |

## Verification

```bash
#!/bin/bash
set -u
DISK="${1:-/dev/sda}"
echo "== scan =="; smartctl --scan 2>/dev/null || true
echo "== health =="; smartctl -H "$DISK" 2>/dev/null || true
echo "== key attributes =="; smartctl -A "$DISK" 2>/dev/null | grep -iE 'reallocated|pending|uncorrectable|crc|spin_retry|temperature' || true
echo "== error log =="; smartctl -l error "$DISK" 2>/dev/null | head -10 || true
echo OK
```

## Safety

- SMART data can be unreliable; combine with filesystem errors, dmesg I/O errors, and RAID controller status.
- A drive with zero SMART errors can still fail; monitor trends, not just current values.
- `Current_Pending_Sector` may remap after successful write; run `smartctl -t select,...` or write to the sector to force remap.
- Replacing a drive based only on one bad attribute without backup risks data loss during rebuild.

---
<ponytail: Scope ceiling — smartctl disk health only; add vendor enclosure tools, NVMe-over-Fabrics, and cloud/EBS volume health when those are used.</ponytail>
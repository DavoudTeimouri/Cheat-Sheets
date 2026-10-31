# RAID Controller Troubleshooting

**Category:** Hardware

## Symptom → Cause → Fix

| Exact symptom | Likely cause | Fix |
|---------------|--------------|-----|
| Controller not detected | Driver missing, card not seated, PCIe issue | `lspci \| grep -i raid`, reseat card, install driver |
| Volume degraded | One or more physical disks failed | Identify failed disk via tool, replace, start rebuild |
| Rebuild slow / stuck | Other I/O load, rebuild priority low, failing source disk | Lower host I/O, raise rebuild priority, check source disk SMART |
| Physical disk offline/unconfigured | Cable loose, backplane issue, disk failed | Reseat cable/disk, check backplane, replace disk |
| Controller battery/capacitor pack failed | BBU/FBOD charge low, end of life | Replace battery/cap pack, force write cache if urgent (data risk) |
| Cannot create volume | Disks not "unconfigured good", mixed sizes/types | Mark disks unconfigured-good, use compatible disks |
| Controller firmware outdated | Known bugs, compatibility issues | Update firmware via vendor tool (careful, can reset config) |

## Diagnosis

```bash
# Check installed tools
which storcli megacli hpssacli ssacli 2>/dev/null || echo "no raid tool found"

# LSI/Broadcom MegaRAID (storcli preferred, megacli legacy)
storcli /call show
storcli /call/all show
storcli /c0 show
storcli /c0/v0 show
storcli /c0/eall/sall show
storcli /c0/e0/s1 show

# HPE Smart Array (ssacli/hpssacli)
ssacli ctrl all show config
ssacli ctrl slot=0 show config detail
ssacli ctrl slot=0 ld all show
ssacli ctrl slot=0 pd all show

# Adaptec (arcconf)
arcconf getconfig 1
arcconf getstatus 1

# Generic PCIe view
lspci -nn | grep -iE 'raid|scsi|sas'

# Kernel messages
dmesg | grep -iE 'megaraid|hpsa|smartpqi|aacraid|3w-xxxx'
lsmod | grep -iE 'megaraid|hpsa|smartpqi|aacraid'
```

## MegaRAID (storcli) deep dive

```bash
# Summary
storcli /call show

# Controller detail
storcli /c0 show

# Virtual drives (volumes)
storcli /c0/vall show

# Physical drives
storcli /c0/eall/sall show

# Specific drive
storcli /c0/e0/s1 show

# Mark disk missing/offline → unconfigured-good → online
storcli /c0/e0/s1 set missing
storcli /c0/e0/s1 set good
storcli /c0/e0/s1 set online

# Start rebuild manually
storcli /c0/e0/s1 start rebuild

# Set rebuild priority
storcli /c0 set rebuildrate=high

# Controller cache/cachecade
storcli /c0 set cachecade=on
storcli /c0 set bbu=on
```

## HPE Smart Array (ssacli) deep dive

```bash
# Controller config
ssacli ctrl slot=0 show config detail

# Logical drives
ssacli ctrl slot=0 ld all show

# Physical drives
ssacli ctrl slot=0 pd all show status

# Specific drive detail
ssacli ctrl slot=0 pd all show detail

# Replace failed drive (auto-rebuild if new disk inserted)
ssacli ctrl slot=0 pd all show status
```

## BBU / FBOD (write cache)

- **BBU (Battery Backup Unit)** / **FBOD (Flash Backed Write Cache)** protects write cache during power loss.
- If failed/charging: write cache may be disabled → slower writes; data not at risk but performance impacted.
- Replace when `Failed` or `Missing`; charge takes hours.
- **Force write cache** without BBU only if you accept data loss on power loss (not recommended for production).

## Verification

```bash
#!/bin/bash
set -u
echo "== raid cards =="; lspci -nn 2>/dev/null | grep -iE 'raid|sas|scsi' || true
echo "== megaraid/storcli =="; which storcli >/dev/null 2>&1 && storcli /call show 2>/dev/null | head -10 || echo "storcli not found"
echo "== ssacli/hpssacli =="; which ssacli hpssacli >/dev/null 2>&1 && ssacli ctrl all show status 2>/dev/null | head -5 || echo "ssacli not found"
echo "== kernel modules =="; lsmod 2>/dev/null | grep -iE 'megaraid|hpsa|smartpqi|aacraid|3w' || true
echo OK
```

## Safety

- Replacing wrong disk = data loss; identify failed disk by slot/serial before pulling.
- Forcing write cache without BBU can lose data on power loss; only in emergency.
- Controller firmware update can reset configuration; backup config first, have downtime window.

---
<ponytail: Scope ceiling — MegaRAID/HPE Smart Array/Adaptec controllers only; add 3ware, Areca, LSI SAS2IRCU, and software RAID (mdadm/ZFS) when those are used.</ponytail>
# Hardware Troubleshooting

**Category:** Hardware

## Subgroups

| Subgroup | Sheet | Covers |
|----------|-------|--------|
| Out-of-band | [OOB/oob.md](OOB/oob.md) | iDRAC, iLO, IPMI out-of-band management |
| RAID controllers | [RAID/raid.md](RAID/raid.md) | Disk arrays, controller health, rebuild |
| SMART | [SMART/smart.md](SMART/smart.md) | Disk health, reallocated sectors, failure prediction |

## Quick self-check

```bash
#!/bin/bash
set -u
echo "== ipmitool =="; ipmitool mc info 2>&1 | head -3 || true
echo "== smartctl =="; smartctl --scan 2>/dev/null || true
echo "== raid tools =="; which storcli megacli hpssacli ssacli 2>/dev/null || true
echo OK
```

---
<ponytail: Scope ceiling — out-of-band management, RAID controllers, SMART disk health only; add BIOS/UEFI, memory/CPU diagnostics, and chassis intrusion when those are used.</ponytail>
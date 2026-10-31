# Proxmox VE VM Troubleshooting

**Category:** Virtualization

## Symptom → Cause → Fix

| Exact symptom | Likely cause | Fix |
|---------------|--------------|-----|
| VM won't start | Invalid config, missing disk, ISO path wrong | `qm start <vmid>`, `qm config <vmid>`, check `/etc/pve/qemu-server/<vmid>.conf` |
| VM stuck `stopping` | Guest agent not responding, filesystem lock | `qm stop <vmid> --timeout 60`, `qm shutdown <vmid>`, check guest agent |
| No network in guest | `virtio` vs `e1000`, bridge missing, firewall | `qm set <vmid> --net0 virtio,bridge=vmbr0`, check `pve-firewall` |
| Slow disk I/O | Wrong disk format/cache, no SCSI discard, snapshot overhead | Use `virtio-scsi`, `ssd=1`, `discard=1`, collapse snapshots |
| Cannot console | No serial device, wrong display | `qm monitor <vmid>`, `qm terminal <vmid>`, add `serial0: socket` |

## Diagnosis

```bash
# VM state
qm list
qm status <vmid>
qm config <vmid>
qm monitor <vmid>   # type 'info status' then 'quit'

# VM config file
cat /etc/pve/qemu-server/<vmid>.conf

# Logs
journalctl -u pve-cluster -u pvedaemon -n 100 --no-pager
/var/log/pve/tasks/  # task logs
/var/log/syslog

# Guest agent
qm agent ping <vmid>
qm agent command <vmid> '{"execute":"guest-info"}'
```

## qm commands deep dive

- **`qm create <vmid>`** → create new VM
- **`qm start <vmid>` / `qm stop <vmid>` / `qm shutdown <vmid>` / `qm reset <vmid>`** → lifecycle
- **`qm set <vmid> --<option> <value>`** → change config (memory, cores, network, disk)
- **`qm clone <vmid> <newvmid> --name <name>`** → clone VM (full or linked)
- **`qm template <vmid>`** → convert to template
- **`qm destroy <vmid>`** → remove VM and disks (destructive)

## Cloud-init deep dive

- Proxmox VE injects cloud-init via `ide2: cloudinit` or `serial0: socket`
- Set `ciuser`, `cipassword`, `sshkeys`, `ipconfig0` via `qm set`
- Regenerate: `qm cloudinit refresh <vmid>`
- Guest must have cloud-init installed and `qemu-guest-agent` for full integration

## Disk types

- **virtio** → paravirtualized, best performance, needs guest drivers
- **scsi** → virtio-scsi, better for high I/O, supports discard/ssd
- **ide/sata** → compatibility, slower
- **scsi hardware** → `scsihw: lsi53c810` (legacy), `virtio-scsi-pci` (modern)

## Verification

```bash
#!/bin/bash
set -u
VMID="${1:-100}"
echo "== vms =="; qm list 2>/dev/null || true
echo "== config =="; qm config "$VMID" 2>/dev/null | head -20 || true
echo "== status =="; qm status "$VMID" 2>/dev/null || true
echo "== agent =="; qm agent ping "$VMID" 2>/dev/null || true
echo OK
```

## Safety

- `qm destroy <vmid>` deletes VM config and all attached disks; destructive.
- `qm stop` is graceful but may hang if guest agent missing; use `qm stop --timeout` or `qm stop --skiplock`.

---
<ponytail: Scope ceiling — Proxmox VE VM lifecycle + qm commands only; add QEMU guest agent advanced, PCI passthrough, and vfio when those are used.</ponytail>
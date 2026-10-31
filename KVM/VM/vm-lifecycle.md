# KVM VM Troubleshooting

**Category:** Virtualization

## Symptom → Cause → Fix

| Exact symptom | Likely cause | Fix |
|---------------|--------------|-----|
| VM won't start | Invalid XML, missing disk image, resource conflict | `virsh start <vm>`, check `virsh list --all`, `journalctl -u libvirtd` |
| VM stuck `paused` | Host out of memory, guest agent issue, `virsh suspend` | `virsh resume <vm>`, check host RAM, `qm` guest agent |
| No network in guest | Missing network interface, wrong model (virtio vs e1000), firewall | `virsh edit <vm>`, verify `<interface type='network'>`, `virtio` model |
| Slow disk I/O | Wrong disk format/cache, no virtio, snapshot chain too deep | Use `qcow2`, `cache='writeback'`, `io='native'`, collapse snapshots |
| Cannot console into VM | No serial/console configured, wrong `virsh console` target | `virsh edit <vm>`, add `<console type='pty'>`, `virsh console <vm>` |

## Diagnosis

```bash
# VM state
virsh -c qemu:///system list --all
virsh -c qemu:///system dominfo <vm>
virsh -c qemu:///system dumpxml <vm>

# VM logs
journalctl -u libvirtd -n 100 --no-pager
/var/log/libvirt/qemu/<vm>.log

# Guest console
virsh -c qemu:///system console <vm>   # Ctrl-] to exit

# Disk image info
qemu-img info /var/lib/libvirt/images/<vm>.qcow2
qemu-img check /var/lib/libvirt/images/<vm>.qcow2
```

## Guest agent

- **`qemu-guest-agent`** → enables graceful shutdown, time sync, filesystem freeze for snapshots
- Install in guest: `apt install qemu-guest-agent` / `dnf install qemu-guest-agent`
- Verify: `virsh -c qemu:///system qemu-agent-command <vm> '{"execute":"guest-info"}'`

## Disk format deep dive

- **qcow2** → default, supports snapshots, compression, encryption; slight overhead
- **raw** → best performance, no snapshot support natively
- **cache mode** → `writeback` (fast, risk on host crash), `none` (safest), `writethrough`
- **IO mode** → `native` (uses host AIO), `threads` (fallback)

## Verification

```bash
#!/bin/bash
set -u
VM="${1:-}"
echo "== vms =="; virsh -c qemu:///system list --all 2>/dev/null || true
[ -n "$VM" ] && echo "== dominfo ==" && virsh -c qemu:///system dominfo "$VM" 2>/dev/null || true
echo OK
```

## Safety

- `virsh undefine` only removes config; disks remain. Use `--remove-all-storage` to delete disks too (destructive).
- `qemu-img check` on a running VM's active image can corrupt; snapshot or shutdown first.

---
<ponytail: Scope ceiling — KVM VM lifecycle + disks only; add PCI passthrough, vfio-mdev, nested virtualization, and libvirt hooks when those are used.</ponytail>
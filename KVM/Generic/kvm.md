# KVM Troubleshooting

**Category:** Virtualization

## Subgroups

| Subgroup | Sheet | Covers |
|----------|-------|--------|
| Host | [Host/host-setup.md](Host/host-setup.md) | KVM host, libvirt, qemu, kvm module |
| VM | [VM/vm-lifecycle.md](VM/vm-lifecycle.md) | VM lifecycle, virsh, console, guests |
| Network | [Network/networking.md](Network/networking.md) | virtio, bridges, NAT, host networking |
| Storage | [Storage/storage.md](Storage/storage.md) | qcow2, libvirt storage pools, disks |

## Quick self-check

```bash
#!/bin/bash
set -u
echo "== kvm module =="; lsmod | grep kvm || true
echo "== libvirtd =="; systemctl is-active libvirtd 2>/dev/null || true
echo "== vms =="; virsh list --all 2>/dev/null || true
echo OK
```

---
<ponytail: Scope ceiling — KVM host + guest lifecycle only; add QEMU tuning, PCI passthrough, and libvirt networking advanced config when those are used.</ponytail>
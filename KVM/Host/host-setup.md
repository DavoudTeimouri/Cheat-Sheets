# KVM Host Troubleshooting

**Category:** Virtualization

## Symptom → Cause → Fix

| Exact symptom | Likely cause | Fix |
|---------------|--------------|-----|
| `kvm: disabled by BIOS` | Virtualization disabled in BIOS/UEFI | Reboot, enable Intel VT-x / AMD-V in firmware |
| `lsmod` shows no kvm modules | Module not loaded, secure boot blocks it | `modprobe kvm_intel` / `modprobe kvm_amd`; disable secure boot or sign module |
| `libvirtd` won't start | Config syntax error, missing qemu-kvm, port conflict | `systemctl status libvirtd`, `journalctl -u libvirtd`, `virsh -c qemu:///system list` |
| Cannot access `/dev/kvm` | User not in `kvm`/`libvirt` group | `usermod -aG kvm,libvirt <user>`, relogin |
| QEMU process high CPU | Guest vCPU pinned, runaway guest | `virsh vcpucount <vm>`, `virsh vcpupin <vm>`, investigate guest |

## Diagnosis

```bash
# KVM hardware support
grep -E 'vmx|svm' /proc/cpuinfo
lsmod | grep -E 'kvm|vhost'
modprobe kvm_intel   # Intel
modprobe kvm_amd     # AMD

# Libvirt daemon
systemctl status libvirtd
systemctl enable --now libvirtd
journalctl -u libvirtd -n 50 --no-pager
virsh -c qemu:///system list
virsh -c qemu:///system capabilities | head -30

# Host networking for guests
ip addr show virbr0 2>/dev/null || true
brctl show 2>/dev/null || ip link show 2>/dev/null || true
```

## Libvirt deep dive

- **`qemu:///system`** vs **`qemu:///session`** → system connects as root/libvirt-qemu; session as user (limited resources)
- **`virsh define <xml>`** → register a VM without starting; `virsh undefine` removes registration (not disks)
- **`virsh start`/`destroy`/`shutdown`** → `destroy` is power-off (unsafe); `shutdown` is graceful
- **Autostart** → `virsh autostart <vm>`; `virsh autostart --disable <vm>`

## Verification

```bash
#!/bin/bash
set -u
echo "== kvm modules =="; lsmod | grep -E '^kvm|^vhost' || true
echo "== libvirtd =="; systemctl is-active libvirtd 2>/dev/null || true
echo "== vm list =="; virsh -c qemu:///system list --all 2>/dev/null || true
echo OK
```

## Safety

- `virsh destroy` does not shut down gracefully; use `virsh shutdown` first.
- Editing live VM XML with `virsh edit` can break running guests; shutdown first or use `virsh attach-device` for hot changes.

---
<ponytail: Scope ceiling — KVM host + libvirt only; add QEMU tuning, PCI passthrough, vfio, and libvirt advanced networking when those are used.</ponytail>
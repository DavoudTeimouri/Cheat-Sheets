# KVM Networking Troubleshooting

**Category:** Virtualization

## Symptom → Cause → Fix

| Exact symptom | Likely cause | Fix |
|---------------|--------------|-----|
| Guest has no network | No interface defined, wrong source network, firewall | `virsh edit <vm>`, add `<interface type='network' source network='default'>` |
| Guest can't reach host | `virbr0` not forwarding, iptables/nftables blocking | `iptables -L`, check libvirt filter rules, enable IP forwarding |
| Slow guest network | Wrong NIC model (e1000 vs virtio), offloading issues | `<model type='virtio'>`, disable checksum offload in guest |
| Host can't reach guest | Guest on isolated NAT network, no port forward | Use `type='bridge'` or add port forward, floating IP |

## Diagnosis

```bash
# Host bridges
ip addr show virbr0 2>/dev/null || true
brctl show 2>/dev/null || ip link show 2>/dev/null || true
ip link show virbr0 2>/dev/null || true

# libvirt networks
virsh -c qemu:///system net-list --all
virsh -c qemu:///system net-dumpxml default

# iptables/nftables rules from libvirt
iptables -S 2>/dev/null | grep libvirt || true
nft list ruleset 2>/dev/null | grep libvirt || true

# Guest connectivity
virsh -c qemu:///system console <vm>
ip addr show eth0   # inside guest
```

## Network types

- **`default` (NAT)** → guest reaches out, host reaches guest only via port forward; `virbr0` with DHCP (dnsmasq)
- **`bridged`** → guest on same LAN as host; needs physical bridge + host NIC in it
- **`isolated`** → guest-to-guest only, no external
- **`hostdev` (PCI passthrough)** → direct NIC passthrough; needs IOMMU, SR-IOV

## virsh network commands

```bash
virsh -c qemu:///system net-start default
virsh -c qemu:///system net-autostart default
virsh -c qemu:///system net-destroy default
virsh -c qemu:///system net-undefine default
```

## Verification

```bash
#!/bin/bash
set -u
echo "== libvirt nets =="; virsh -c qemu:///system net-list --all 2>/dev/null || true
echo "== virbr0 =="; ip addr show virbr0 2>/dev/null || true
echo "== ip forward =="; sysctl net.ipv4.ip_forward 2>/dev/null || true
echo OK
```

## Safety

- Changing libvirt network while VMs running can drop guest connectivity; restart guests after.
- Bridged mode exposes guest directly to LAN; use firewalld/nftables on host to restrict.

---
<ponytail: Scope ceiling — KVM/libvirt networking only; add SR-IOV, macvtap, and OVN when those are used.</ponytail>
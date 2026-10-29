# vSphere ESXi Troubleshooting

## 1. ESXi host unreachable / disconnected in vCenter

```bash
# Enable SSH via DCUI first, then:
services.sh restart
/esxcli/system/vmknic/list
/esxcli/network/ip/interface/list
ping <vcenter-ip>
```
- Management network down: check vmk0 IP, VLAN, and physical switch port
- `hostd` / `vpxa` not running: `services.sh restart`, check `/var/log/hostd.log`
- DNS/NTP mismatch: host and vCenter must resolve each other, NTP in sync

## 2. VM cannot power on

```bash
vim-cmd vmsvc/getallvms
vim-cmd vmsvc/power.on <vmid>
vim-cmd vmsvc/get.summary <vmid>
```
- Datastore full: free space or storage vMotion VMs elsewhere
- HA admission control: insufficient failover capacity → disable admission control temporarily
- Locked VMX/VMDK: another host holds the lock → check `/var/log/vmkernel.log`, reboot or break lock carefully

## 3. Storage latency / datastore full

```bash
esxcli storage filesystem list
esxcli storage core device list
esxcli storage core device stats -d <naa.xxx>
```
- Datastore full (95%): delete old snapshots, storage vMotion, expand LUN
- Multipathing broken: `esxcli storage nmp device list`, check HBA zoning, array port faults
- High latency: array controller queue full, SAN fabric errors, too many VMs per datastore

## 4. vMotion fails

Requirements: same vSphere version, shared storage, EVC-compatible CPUs, vmkernel port with vMotion enabled, matching MTU/jumbo frames end-to-end, DNS resolvable.
```bash
esxcli network ip interface list     # vmkernel ports
esxcli network vswitch standard list
```
- Check `/var/log/vmkernel.log` and `/var/log/hostd.log` for vMotion errors

## 5. HA / DRS misbehaving

- HA: amber dashed host icon → network isolation, datastore heartbeat fail, admission control enabled with no capacity
- DRS: maintenance mode blocked → VM-to-VM affinity rules, licenses
- Check `/var/log/fdm.log` (HA) and rebalance DRS recommendations

## 6. VMware Tools / open-vm-tools

```bash
vim-cmd vmsvc/tools.upgrade <vmid>
```
- No graceful shutdown/reboot from vCenter: tools not running or outdated
- Time drift: disable host time sync if guest runs chrony/ntp, or enable both consistently
- Network adapters changed after upgrade: reinstall tools to restore vmxnet3 driver

## ESXi host deep dive

```bash
services.sh restart
/esxcli/system/vmknic/list
/esxcli/network/ip/interface/list
ping <vcenter-ip>
vim-cmd vmsvc/getallvms
vim-cmd vmsvc/power.on <vmid>
vim-cmd vmsvc/get.summary <vmid>
```
- Management network down → check vmk0 IP, VLAN, physical switch port
- `hostd`/`vpxa` not running → `services.sh restart`, check `/var/log/hostd.log`
- DNS/NTP mismatch → host and vCenter must resolve each other, NTP in sync

## Datastore & storage deep dive

```bash
esxcli storage filesystem list
esxcli storage core device list
esxcli storage core device stats -d <naa.xxx>
esxcli storage nmp device list
```
- Datastore full (95%) → delete old snapshots, storage vMotion, expand LUN
- Multipathing broken → `esxcli storage nmp device list`, check HBA zoning, array port faults
- Path down (ANA/ALUA) → check HBA zoning, array port, SAN fabric errors

## vMotion / HA / DRS

```bash
esxcli network ip interface list     # vmkernel ports
esxcli network vswitch standard list
```
- vMotion fails → same vSphere version, shared storage, EVC-compatible CPUs, vmkernel port with vMotion enabled, matching MTU/jumbo frames, DNS resolvable
- HA amber dashed icon → network isolation, datastore heartbeat fail, admission control enabled with no capacity; check `/var/log/fdm.log`
- DRS maintenance mode blocked → VM-to-VM affinity rules, licenses

## VMware Tools

```bash
vim-cmd vmsvc/tools.upgrade <vmid>
```
- No graceful shutdown/reboot → tools not running or outdated
- Time drift → disable host time sync if guest runs chrony/ntp, or enable both consistently

## Log locations

- ESXi: `/var/log/vmkernel.log`, `/var/log/hostd.log`, `/var/log/vpxa.log`, `/var/log/syslog.log`

## Verification

```bash
#!/bin/bash
set -u
echo "== hostd =="; services.sh status 2>/dev/null \| grep hostd || true
echo "== storage =="; esxcli storage filesystem list 2>/dev/null \| head -5 || true
echo "== vmotion vmk =="; esxcli network ip interface list 2>/dev/null \| grep -i vmotion || true
echo OK
```

## Safety

- `services.sh restart` briefly drops management connectivity; do from DCUI or have console access.
- Don't mark multiple failing disks `in` at once (backfill storm).

---

<ponytail: Scope ceiling — ESXi host + VM layer only; add vSphere with Tanzu, vSAN, and Lifecycle Manager when adopted.</ponytail>
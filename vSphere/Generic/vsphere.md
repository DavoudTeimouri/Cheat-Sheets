# vSphere Troubleshooting

**Category:** Virtualization
## 1. ESXi host unreachable / disconnected in vCenter

```bash
# On ESXi (enable SSH first via DCUI or Host profile)
services.sh restart
/esxcli/system/vmknic/list
/esxcli/network/ip/interface/list
ping <vcenter-ip>
```
Fix: restart `hostd` and `vpxa`, check management network, verify DNS and NTP, check firewall rules (`esxcli network firewall ruleset list`).

## 2. vCenter server down

- Check VCSA appliance shell: `shell` → `service-control --status --all`
- Restart: `service-control --start --all` or `service-control --stop --all && service-control --start --all`
- Disk full: `/storage/core`, `/storage/log`, `/storage/db` — `df -h`, expand VMDK or clean logs (`logdump`, `vmware-logrotate`)
- Certificates expired: renew via VAMI `https://<vc>:5480` or `certool`

## 3. VM cannot power on / "Ha-... failed"

```bash
vim-cmd vmsvc/getallvms
vim-cmd vmsvc/power.on <vmid>
vim-cmd vmsvc/get.summary <vmid>
```
Causes: datastore full, HA admission control, locked VMX/VMDK, insufficient resources, expired HA lease.

## 4. Datastore full / storage latency

```bash
esxcli storage filesystem list
esxcli storage core device list
esxcli storage core device stats -d <naa.xxx>
```
Fix: delete old snapshots, storage vMotion VMs elsewhere, expand LUN, check array port faults, verify multipathing (`esxcli storage nmp device list`).

## 5. VM snapshot consolidation stuck

- "Consolidate needed" in VM summary → right-click VM → Snapshot → Consolidate
- If fails: check datastore space, delete delta files manually only from shell at your own risk (`ls -lh /vmfs/volumes/<ds>/<vm>/`)

## 6. vMotion fails

Requirements: same vSphere version, shared storage or storage vMotion, compatible CPUs (EVC mode), vmkernel port with vMotion enabled, MTU/jumbo frames matching end-to-end, DNS resolvable.
```bash
esxcli network ip interface list   # vmkernel ports
esxcli network vswitch standard list
```
Check `vmkwarning` and `hostd` logs: `/var/log/vmkernel.log`, `/var/log/hostd.log`.

## 7. HA / DRS misbehaving

- HA: dashed amber host icon → network isolation, datastore heartbeat fail, admission control enabled with no failover capacity
- DRS: "Enter maintenance mode blocked" → VMs with DRS rules, VM-to-VM affinity, licenses
Fix: reconfigure HA cluster, disable admission control temporarily for maintenance, check `fdm.log` (`/var/log/fdm.log`).

## 8. Template / cloning fails

- Template must be powered off and not in use
- Insufficient datastore space on destination
- Customization spec fails: VMware Tools outdated, network adapter type mismatch, Sysprep missing on Windows guest

## 9. Guest tools not running / outdated

```bash
vim-cmd vmsvc/tools.upgrade <vmid>
```
Symptoms: no graceful shutdown/reboot, wrong IP in vCenter, time drift, no shutdown from vCenter. Install/open-vm-tools in guest.

## 10. Certificates / SSL warnings

Replace SSL certs via VAMI or `certool` — regenerate machine SSL, solution user, and STS certs; restart services after `service-control --restart`.

## Log locations

- ESXi: `/var/log/vmkernel.log`, `/var/log/hostd.log`, `/var/log/vpxa.log`, `/var/log/syslog.log`
- vCenter (VCSA): `/var/log/vmware/vpxd/`, `/var/log/vmware/vsphere-client/`, `/var/log/vmware/vcdb/`, `/var/log/vmware/vmwrepo/`

## Quick self-check

```bash
#!/bin/bash
set -u
echo "== ESXi storage =="; esxcli storage filesystem list 2>/dev/null | awk 'NR==1 || /^VMFS/'
echo "== hostd =="; services.sh status 2>/dev/null | grep hostd || true
echo "== vMotion vmk =="; esxcli network ip interface list 2>/dev/null | grep -i vmotion || true
echo OK
```

---
<ponytail: Scope ceiling — Day-2 ops on compute/storage/network only; add NSX-T, vSAN, Lifecycle Manager, and Kubernetes on vSphere (Tanzu/TKR) when those layers exist in the environment.</ponytail>
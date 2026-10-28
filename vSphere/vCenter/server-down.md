# vSphere vCenter Troubleshooting

## 1. vCenter server down / VCSA unresponsive

Appliance shell:
```bash
shell
service-control --status --all
service-control --start --all
service-control --stop --all && service-control --start --all
```
- Disk full: `/storage/core`, `/storage/log`, `/storage/db` → `df -h`, expand VMDK or clean logs
- Certificates expired: renew via VAMI (`https://<vc>:5480`) or `certool`
- Services not starting: check `/var/log/vmware/vpxd/`, `/var/log/vmware/vcdb/`

## 2. Certificates / SSL warnings

Replace machine SSL, solution user, and STS certs via VAMI or `certool`; restart services after:
```bash
service-control --restart --all
```

## 3. HA / DRS cluster issues

- HA dashed amber icon: network isolation, datastore heartbeat failure, admission control enabled with no failover capacity
- Reconfigure HA cluster, temporarily disable admission control for maintenance windows
- Check `/var/log/fdm.log` (HA agent)

## 4. License expiring / expired

- vCenter or ESXi license expired → VMs may not power on, features disabled
- Assign new license in vCenter → Licensing → Assign license to vCenter Server / ESXi hosts

## Log locations

- vCenter (VCSA): `/var/log/vmware/vpxd/`, `/var/log/vmware/vsphere-client/`, `/var/log/vmware/vcdb/`, `/var/log/vmware/vmwrepo/`

---
<ponytail: Scope ceiling — vCenter appliance + cluster services only; add NSX-T, Lifecycle Manager, and vCenter HA when deployed.</ponytail>
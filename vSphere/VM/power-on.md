# vSphere VM Troubleshooting

## 1. VM snapshot consolidation stuck

- "Consolidate needed" in VM summary → right-click VM → Snapshot → Consolidate
- If fails: check datastore space, verify no delta files locked, consolidate from Host Client directly
- Manual delta deletion: only from ESXi shell at your own risk (`ls -lh /vmfs/volumes/<ds>/<vm>/`)

## 2. Template / cloning fails

- Template must be powered off and not in use
- Insufficient destination datastore space
- Customization spec fails: VMware Tools outdated, network adapter type mismatch, Sysprep missing on Windows guest

## 3. Guest tools not running / outdated

```bash
vim-cmd vmsvc/tools.upgrade <vmid>
```
- Symptoms: no graceful shutdown/reboot, wrong IP in vCenter, time drift
- Fix: install open-vm-tools (Linux) or VMware Tools (Windows), restart the service

## 4. VM stuck at 95% / 99% during power-on

- Storage array or datastore unresponsive → check array health, datastore latency
- ESXi host resource contention → CPU/memory reservation limits
- Check `vmware.log` in the VM's datastore folder

## 5. EFI / boot issues

- VM won't boot after firmware upgrade: check BIOS/EFI boot order, Secure Boot compatibility
- "No bootable device": boot from ISO, check disk controller type (PVSCSI vs LSI Logic), disk present in VM settings

---
<ponytail: Scope ceiling — VM lifecycle (power-on, snapshots, tools, templates) only; add VM encryption, fault tolerance, and VMCI/VMXNET3 tuning when used.</ponytail>
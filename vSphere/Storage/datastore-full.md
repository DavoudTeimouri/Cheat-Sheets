# vSphere Storage Troubleshooting

## 1. Datastore full / nearfull

```bash
esxcli storage filesystem list
df -h /vmfs/volumes/<datastore>
```
- Free space: delete old snapshots, storage vMotion VMs elsewhere, expand LUN
- Writes blocked at 95% full: act immediately or VMs suspend

## 2. Multipathing / storage device issues

```bash
esxcli storage core device list
esxcli storage nmp device list
esxcli storage nmp path list
```
- Path down (ANA/ALUA): check HBA zoning, array port, SAN fabric errors
- Device not visible: rescan storage (`esxcli storage core adapter resync --adapter=<vmhba>`), reboot host if needed

## 3. VMFS locking / metadata corruption

- "Failed to lock file" in vmkernel.log: another host holds the lock, stale lock from crashed host
- Resolve: reboot affected hosts, or use `vmkfstools --lock` carefully (last resort)

## 4. NFS / iSCSI datastore disconnect

```bash
esxcli storage nfs list
esxcli iscsi adapter list
```
- NFS stale: check server export, network, `/var/log/vmkernel.log` for NFS errors
- iSCSI session down: CHAP auth mismatch, network isolation, target portal unreachable

## Datastore full deep dive

```bash
esxcli storage filesystem list
df -h /vmfs/volumes/<datastore>
```
- Free space → delete old snapshots, storage vMotion VMs elsewhere, expand LUN
- Writes blocked at 95% full → act immediately or VMs suspend

## Multipathing / device

```bash
esxcli storage core device list
esxcli storage nmp device list
esxcli storage nmp path list
```
- Path down (ANA/ALUA) → check HBA zoning, array port, SAN fabric errors
- Device not visible → rescan storage (`esxcli storage core adapter resync --adapter=<vmhba>`), reboot host if needed

## VMFS locking / metadata corruption

- "Failed to lock file" in vmkernel.log → another host holds lock, stale lock from crashed host
- Reboot affected hosts; `vmkfstools --lock` as last resort

## NFS / iSCSI disconnect

```bash
esxcli storage nfs list
esxcli iscsi adapter list
```
- NFS stale → check server export, network, `/var/log/vmkernel.log` for NFS errors
- iSCSI session down → CHAP auth mismatch, network isolation, target portal unreachable

## Verification

```bash
#!/bin/bash
set -u
echo "== datastores =="; esxcli storage filesystem list 2>/dev/null \| head -5 || true
echo "== devices =="; esxcli storage core device list 2>/dev/null \| head -5 || true
echo OK
```

## Safety

- `vmkfstools --lock` can corrupt metadata; reboot hosts first, use lock only as last resort.

---

<ponytail: Scope ceiling — VMFS/NFS/iSCSI datastores and multipathing only; add vSAN and vSphere Replication when those storage features are in use.</ponytail>
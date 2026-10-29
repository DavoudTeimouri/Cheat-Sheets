# Rook-Ceph Troubleshooting

**Category:** Storage

## Symptom → Cause → Fix

| Exact symptom | Likely cause | Fix |
|---------------|--------------|-----|
| Rook operator pod crash | Config invalid, RBAC missing, image pull failure | `kubectl logs -n rook-ceph rook-ceph-operator`, check RBAC, image tag |
| Cluster not created / stuck `Creating` | `CephCluster` spec invalid, insufficient nodes, storage devices missing | Check `kubectl get cephcluster -n rook-ceph -o yaml`, validate spec |
| OSD not created | No devices specified, device filter excludes all, `crushDeviceClass` mismatch | Add `devices` or `deviceFilter` to storage spec, verify disks available |
| MON quorum lost | Fewer than majority MONs up, `count: 1` in production | Ensure `count: 3` MONs, check `ceph quorum_status`, `ceph mon stat` |
| MDS down / CephFS degraded | Insufficient MDS instances, `allow_standbys` false | `ceph fs set <fs> allow_standbys true`, add MDS daemons |

## Diagnosis

```bash
kubectl get cephcluster -n rook-ceph -o yaml
kubectl get cephblockpool -A
kubectl get cephfilesystem -A
kubectl get cephobjectstore -A
kubectl logs -n rook-ceph rook-ceph-operator --tail=100
kubectl get pods -n rook-ceph
kubectl exec -it -n rook-ceph deploy/rook-ceph-tools -- ceph -s
kubectl exec -it -n rook-ceph deploy/rook-ceph-tools -- ceph health detail
```

## Rook toolbox

```bash
kubectl exec -it -n rook-ceph deploy/rook-ceph-tools -- bash
ceph -s
ceph health detail
ceph osd tree
ceph pg dump pgs | awk '{print $2, $10, $14}' | sort | uniq -c
```
- Use the toolbox for all `ceph` CLI commands inside the cluster
- If no toolbox, deploy: `kubectl apply -f https://raw.githubusercontent.com/rook/rook/master/cluster/examples/kubernetes/ceph/toolbox.yaml`

## Storage spec deep dive

```yaml
apiVersion: ceph.rook.io/v1
kind: CephCluster
metadata:
  name: rook-ceph
  namespace: rook-ceph
spec:
  dataDirHostPath: /var/lib/rook
  mon:
    count: 3
    allowMultiplePerNode: false
  storage:
    useAllNodes: true
    useAllDevices: false
    deviceFilter: "^sd[.]"
    config:
      storeType: bluestore
```
- **`dataDirHostPath`** → host directory for Ceph data; must exist or Rook creates it
- **`mon.count`** → production requires 3 (odd number for quorum)
- **`deviceFilter`** → regex; avoid consuming OS disks accidentally
- **`storeType`** → `bluestore` (recommended) vs `filestore` (deprecated)

## Device management

```bash
# On node
lsblk
ceph-volume lvm list
```
- **Device already has filesystem** → Rook skips; wipe with `wipefs -a /dev/sdX` (destructive)
- **Device class** → set `crushDeviceClass` for SSD/HDD separation in CRUSH rule

## Verification

```bash
#!/bin/bash
set -u
NS="${1:-rook-ceph}"
echo "== cluster =="; kubectl get cephcluster -n "$NS" 2>/dev/null || true
echo "== operator =="; kubectl get pods -n "$NS" -l app=rook-ceph-operator 2>/dev/null || true
echo "== ceph status (toolbox) =="; kubectl exec -it -n "$NS" deploy/rook-ceph-tools -- ceph -s 2>&1 | head -20 || true
echo OK
```

## Safety

- `dataDirHostPath` on root disk can fill root filesystem; use dedicated data disk/partition.
- Deleting a `CephCluster` CRD removes all Ceph data; ensure backups first.
- OSD replacement triggers rebalancing; monitor `ceph -s` recovery% before proceeding.

---
<ponytail: Scope ceiling — Rook-Ceph operator, cluster, MON/OSD/MDS; add Rook-Ceph object store, NFS, and filesystem subvolume groups when those features are used.</ponytail>
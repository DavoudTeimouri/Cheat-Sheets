# Ceph CSI Troubleshooting

**Category:** Storage

## Symptom → Cause → Fix

| Exact symptom | Likely cause | Fix |
|---------------|--------------|-----|
| PVC stuck `Pending` | Ceph CSI provisioner unhealthy, StorageClass mismatch, `volumeBindingMode` wrong | `kubectl get csidrivers`, `kubectl get pods -n rook-ceph -l app=csi-*`, check StorageClass `provisioner: ceph.rook.io/block` |
| `AttachFailed` / `MountFailed` | Node lacks `rbd` kernel module, libceph mismatch, image locked, SELinux blocking | `modprobe rbd`, match libceph/client versions, `rbd lock rm <pool>/ <locker-id>` |
| RBD image cannot map | Image features too new for client kernel | `rbd feature disable <pool>/ object-map fast-diff deep-flatten` |

## Diagnosis

```bash
kubectl get csidrivers | grep ceph
kubectl get pods -n rook-ceph -l app=csi-rbd-plugin -o wide
kubectl get pods -n rook-ceph -l app=csi-cephfs-plugin -o wide
kubectl logs -n rook-ceph -l app=csi-rbd-provisioner --tail=100
kubectl logs -n rook-ceph -l app=csi-rbd-attacher --tail=100
kubectl describe pv <pv>   # CSI: volumeHandle empty?
kubectl describe pvc <pvc> -n <ns>   # events: FailedAttachVolume, MountVolume.SetUp failed
```

## CSI sidecars deep dive

- **`csi-provisioner`** → creates/deletes RBD images via `CreateVolume`/`DeleteVolume`
- **`csi-attacher`** → publishes/unpublishes volume via `NodePublishVolume`/`NodeUnpublishVolume`
- **`csi-resizer`** → expands volume via `ControllerExpandVolume`/`NodeExpandVolume`
- **`csi-snapshotter`** → manages snapshots via `CreateSnapshot`/`DeleteSnapshot`

## RBD kernel module on nodes

```bash
modprobe rbd
lsmod | grep rbd
ceph-volume lvm list
```
- **modprobe rbd** → required on every node consuming RBD via CSI
- **libceph version** → client (node) libceph must match cluster libceph; upgrade Rook/Ceph together

## VolumeHandle empty

```bash
kubectl get pv <pv> -o yaml | grep -A5 csi
```
- `volumeHandle: ""` → provisioner failed to create image; check CephCSI provisioner logs and pool existence
- Verify StorageClass `parameters.pool` exists: `kubectl get cephblockpool -n rook-ceph`

## Verification

```bash
#!/bin/bash
set -u
NS="${1:-rook-ceph}"
echo "== csi drivers =="; kubectl get csidrivers | grep ceph 2>/dev/null || true
echo "== csi pods =="; kubectl get pods -n "$NS" -l app=csi-* 2>/dev/null || true
echo "== storageclasses =="; kubectl get storageclass 2>/dev/null | grep ceph || true
echo "== pvc events =="; kubectl get events -A --field-selector involvedObject.kind=PersistentVolumeClaim 2>/dev/null | grep -iE 'ceph|csi|attach|mount|fail' | tail -10 || true
echo OK
```

## Safety

- Deleting a PVC with `reclaimPolicy: Delete` destroys the RBD image; verify no workloads use it.
- Expanding an RBD image requires `rbd resize` support; filesystem resize (`resize2fs`/`xfs_growfs`) happens via CSI node plugin.
- Image locked by another pod → `rbd lock rm` after confirming no active writer.

---
<ponytail: Scope ceiling — Ceph CSI provisioner/attach/resize; add Ceph CSI snapshot controller, volume encryption, and CSI migration when those features are used.</ponytail>
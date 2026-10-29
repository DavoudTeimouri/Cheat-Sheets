# CSI Drivers Troubleshooting

**Category:** Cloud-Native

## Symptom → Cause → Fix

| Exact symptom | Likely cause | Fix |
|---------------|--------------|-----|
| `AttachFailed` / `MountFailed` | Node lacks driver, `multipathd` not running, SELinux blocking, firewall blocking storage ports | Install CSI driver on node, start multipathd, fix SELinux, open ports (443, 9001 for vSphere CSI) |
| `FailedAttachVolume` after node drain | Stale attachment | Detach via cloud console, `csi rescan`, cordon/uncordon node |
| PVC stuck `Pending` | StorageClass missing, topology/zone mismatch, CSI driver unhealthy | Check `kubectl get csidrivers`, `kubectl get pods -n kube-system -l app=csi-*`, zone alignment |

## Diagnosis

```bash
kubectl get csidrivers
kubectl get pods -n kube-system -l app=csi-...
kubectl describe pv <pv>   # CSI: volumeHandle empty?
kubectl describe pvc <pvc> -n <ns>   # events: FailedAttachVolume, MountVolume.SetUp failed
```

## Ceph CSI deep dive (SDS Ceph)

```bash
kubectl get pods -n rook-ceph -l app=rook-ceph-csi
kubectl logs -n rook-ceph -l app=rook-ceph-csi --tail=100
kubectl get cephblockpool -A
kubectl get storageclass -o yaml | grep -E 'provisioner:|reclaimPolicy:|volumeBindingMode:'
```
- **CSI sidecar** → `csi-provisioner`, `csi-attacher`, `csi-resizer`, `csi-snapshotter` must be Running
- **RBD kernel module** → `modprobe rbd` on nodes; libceph version mismatch between client and cluster
- **Image locked** → `rbd lock ls <pool>/<image>`, `rbd lock rm <pool>/<image> <locker-id>`
- **Topology** → `volumeBindingMode: WaitForFirstConsumer` needed for zone-aware placement; topology keys match failure domain

## Cloud CSI deep dive

- **EBS** → IAM `ec2:DescribeVolumes`, `ec2:AttachVolume`, `ec2:CreateSnapshot`, `ec2:DeleteSnapshot`; AZ mismatch between node and volume
- **GCP PD** → `compute.disks.create`, `compute.disks.attach`; service account on node
- **Azure Disk** → `Microsoft.Compute/disks/write`; managed vs unmanaged disks

## StorageClass deep dive

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ceph-rbd
provisioner: ceph.rook.io/block
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
parameters:
  pool: replicapool
  clusterNamespace: rook-ceph
  fstype: ext4
```
- **`reclaimPolicy: Delete`** → PV deleted with PVC (data loss risk)
- **`reclaimPolicy: Retain`** → PV kept; manual cleanup needed
- **`volumeBindingMode: WaitForFirstConsumer`** → PV provisioned when pod scheduled (required for zone topology)

## Verification

```bash
#!/bin/bash
set -u
echo "== csidrivers =="; kubectl get csidrivers 2>/dev/null || true
echo "== csi pods =="; kubectl get pods -n kube-system -n rook-ceph -l app=csi-* 2>/dev/null || true
echo "== storageclasses =="; kubectl get storageclass 2>/dev/null || true
echo "== csi events =="; kubectl get events -A --field-selector involvedObject.kind=PersistentVolumeClaim 2>/dev/null | grep -iE 'attach|mount|provide|fail' | tail -10 || true
echo OK
```

## Safety

- `reclaimPolicy: Delete` on a PVC in use → data deleted when PVC removed; verify before changing.
- Expanding a PV requires filesystem resize support; XFS/ext4 online resize supported on most CSI drivers.
- Detaching a volume in use by a pod causes I/O errors; cordon and drain the node first.

---
<ponytail: Scope ceiling — Ceph CSI + cloud CSI attach/mount; add CSI snapshot controller, volume expansion, and CSI migration when those features are used.</ponytail>
# Kubernetes Storage Troubleshooting

## 1. PVC not bound

```bash
kubectl get pvc -n <ns>
kubectl get pv
kubectl describe pvc <pvc> -n <ns>
```
- StorageClass missing/default mismatch
- Volume mode/access mode mismatch (RWO vs RWX)
- CSI driver not installed or unhealthy (`kubectl get csidrivers`)
- Topology/zone constraint: PVC in different zone than node

## 2. CSI driver issues

```bash
kubectl get csidrivers
kubectl get pods -n kube-system -l app=csi-...
kubectl describe pv <pv>
```
- `AttachFailed` / `MountFailed`: node lacks driver, `multipathd` not running, SELinux blocking, firewall blocking storage ports
- `FailedAttachVolume` after node drain: stale attachment → detach via cloud console, cordon/uncordon node

## 3. Volume not mounting

```bash
kubectl describe pod <pod> -n <ns>   # events: FailedMount, MountVolume.SetUp failed
```
- Wrong `subPath`, `readOnly`, or `mountPath`
- Secret/ConfigMap key missing from projected volume
- HostPath permission denied on SELinux hosts

## Volume not mounting deep dive

```bash
kubectl describe pod <pod> -n <ns>   # events: FailedMount, MountVolume.SetUp failed
kubectl get pv <pv> -o yaml \| grep -A15 csi
kubectl get sc <sc> -o yaml
```
- Wrong `subPath`, `readOnly`, or `mountPath`
- Secret/ConfigMap key missing from projected volume
- HostPath permission denied on SELinux hosts (`chcon -t container_file_t`)

## CSI driver health

```bash
kubectl get csidrivers
kubectl get pods -n kube-system -l app=csi-...
kubectl describe pv <pv>
```
- `AttachFailed` / `MountFailed` → node lacks driver, `multipathd` not running, SELinux blocking, firewall blocking storage ports
- `FailedAttachVolume` after node drain → stale attachment → detach via cloud console, cordon/uncordon node

## StorageClass selection

```bash
kubectl get sc
kubectl get sc <sc> -o yaml \| grep -E 'provisioner:|reclaimPolicy:|volumeBindingMode:'
```
- `volumeBindingMode: WaitForFirstConsumer` → PV provisioned when pod scheduled (needed for zone topology)
- `reclaimPolicy: Delete` → PV deleted with PVC (data loss risk)
- `reclaimPolicy: Retain` → PV kept, manual cleanup needed

## Verification

```bash
#!/bin/bash
set -u
PVC="${1:-}"
NS="${2:-default}"
echo "== pvc =="; kubectl get pvc "$PVC" -n "$NS" 2>/dev/null || true
echo "== pv bound =="; kubectl get pv -l "claim.namespace=$NS,claim.name=$PVC" 2>/dev/null || true
echo "== events =="; kubectl describe pvc "$PVC" -n "$NS" 2>/dev/null \| grep -iE 'failed|mount|attach|provision' \| tail -5 || true
echo OK
```

## Safety

- `reclaimPolicy: Delete` on a PVC in use → data deleted when PVC removed; verify before changing.
- Expanding a PV requires filesystem resize support; XFS/ext4 online resize supported on most CSI drivers.

---

<ponytail: Scope ceiling — PVC/PV, CSI drivers, volume mounting only; add snapshot/CSI snapshot controller and volume expansion when those features are used.</ponytail>
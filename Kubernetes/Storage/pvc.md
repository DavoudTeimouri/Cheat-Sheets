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

---
<ponytail: Scope ceiling — PVC/PV, CSI drivers, volume mounting only; add snapshot/CSI snapshot controller and volume expansion when those features are used.</ponytail>
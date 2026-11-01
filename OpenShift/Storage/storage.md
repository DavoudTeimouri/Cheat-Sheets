# OpenShift Storage Troubleshooting

**Category:** Cloud-Native

## Symptom → Cause → Fix

| Exact symptom | Likely cause | Fix |
|---------------|--------------|-----|
| PVC Pending | StorageClass missing, no available PV, topology zone mismatch | `oc get pvc`, `oc describe pvc`, check StorageClass and PV |
| Pod Cannot Mount Volume | CSI driver missing, SELinux, wrong `fsType` | Check CSI driver pods, `oc describe pod`, check security context |
| OCS / ODF Degraded | Ceph down, mon/osd issues, RGW down | `oc get storagecluster`, `oc describe storagecluster`, check Ceph |
| StorageClass default missing | No default set, multiple defaults | `oc get storageclass`, set default with `storageclass.kubernetes.io/is-default-class=true` |

## Diagnosis

```bash
# PVC/PV
oc get pvc -A
oc get pv
oc describe pvc <pvc> -n <ns>
oc describe pv <pv>

# StorageClasses
oc get storageclass
oc get storageclass <name> -o yaml

# CSI drivers
oc get pods -n openshift-cluster-storage
oc get csidriver

# OCS/ODF
oc get storagecluster -n openshift-storage
oc describe storagecluster -n openshift-storage
oc get cephcluster -n openshift-storage
oc logs -n openshift-storage -c rook-ceph-operator rook-ceph-operator --tail=100
```

## StorageClass deep dive

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp2
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: ebs.csi.aws.com
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
```

- **`WaitForFirstConsumer`** → PV provisioned when pod scheduled (required for multi-zone/topology).
- **`Delete`** → PV deleted with PVC (data loss risk).
- **`Retain`** → PV kept after PVC deleted; manual cleanup.

## OpenShift Data Foundation (OCF/ODF)

- ODF manages Ceph on OpenShift via `StorageCluster` CRD.
- `oc get storagecluster` shows phase: `Ready` / `Ready:Partial` / `Failure`.
- Rook-Ceph operator manages MON/OSD/MDS/RGW pods inside `openshift-storage`.

## Verification

```bash
#!/bin/bash
set -u
echo "== storageclasses =="; oc get storageclass 2>/dev/null || true
echo "== pvcs pending =="; oc get pvc -A | grep Pending 2>/dev/null || true
echo "== storageclusters =="; oc get storagecluster -A 2>/dev/null || true
echo "== csi drivers =="; oc get csidriver 2>/dev/null || true
echo OK
```

## Safety

- Deleting a PVC with `reclaimPolicy: Delete` destroys data; verify no workloads use it.
- Expanding OCS/ODF storage requires adding nodes/disks; monitor rebalance progress.

---
<ponytail: Scope ceiling — PVC/PV + StorageClass + OCS/ODF only; add CSI snapshot controller, volume replication, and MetroDR when those are used.</ponytail>
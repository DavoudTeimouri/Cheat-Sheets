# OpenShift Troubleshooting

**Category:** Cloud-Native

## Subgroups

| Subgroup | Sheet | Covers |
|----------|-------|--------|
| Cluster | [Cluster/cluster.md](Cluster/cluster.md) | Installation, nodes, MachineConfig, etcd |
| Storage | [Storage/storage.md](Storage/storage.md) | Persistent volumes, OCS, storage classes |
| Network | [Network/network.md](Network/network.md) | OpenShift SDN/OVN, routes, services |
| Operators | [Operators/operators.md](Operators/operators.md) | Operator Lifecycle Manager, OperatorHub, installs |

## Quick self-check

```bash
#!/bin/bash
set -u
echo "== oc version =="; oc version 2>/dev/null || true
echo "== nodes =="; oc get nodes 2>/dev/null || true
echo "== cluster operators =="; oc get clusteroperators 2>/dev/null | grep -vE 'True.*False.*False|True.*True.*True' | head -10 || true
echo OK
```

---
<ponytail: Scope ceiling — OpenShift cluster/admin troubleshooting only; add OpenShift Virtualization, Serverless, and Service Mesh when those operators are installed.</ponytail>
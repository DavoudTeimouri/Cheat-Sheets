# OpenShift Cluster Troubleshooting

**Category:** Cloud-Native

## Symptom → Cause → Fix

| Exact symptom | Likely cause | Fix |
|---------------|--------------|-----|
| Node NotReady | Kubelet down, node agent (machine-config-daemon) degraded, network | `oc get node`, `oc describe node`, check machine-config-daemon |
| ClusterOperator Degraded | Component (ingress, etcd, kube-apiserver) unhealthy | `oc get clusteroperators`, `oc describe clusteroperator <name>` |
| etcd quorum lost | Fewer than majority etcd members up | Restart etcd pods/nodes, check `/etc/etcd`, restore from etcd backup |
| MachineConfig failed | Invalid MachineConfig, boot failed | `oc get machineconfig`, `oc describe machineconfig <name>`, check node boot logs |
| Cannot log in via oc | Wrong cluster API URL, token expired, cert mismatch | `oc login <api-url>`, new token via web console, check CA cert |

## Diagnosis

```bash
# Cluster status
oc version
oc get nodes
oc get clusteroperators
oc get clusterversion
oc describe clusterversion

# etcd
oc get nodes -l node-role.kubernetes.io/master
oc debug node/<node> -- chroot /host etcdctl endpoint health --cacert=/etc/etcd/tls/client-ca.crt --cert=/etc/etcd/tls/client.crt --key=/etc/etcd/tls/client.key --endpoints=https://127.0.0.1:2379

# MachineConfigDaemon
oc get machineconfig
oc describe machineconfig <name>
oc get machineconfigdaemon

# Logs
oc logs -n openshift-etcd etcd-<node>
oc logs -n openshift-machine-config-operator -c machine-config-daemon
```

## etcd deep dive

- OpenShift runs etcd as static pods on control-plane nodes.
- Backup: `oc debug node/<node> -- chroot /host /usr/local/bin/cluster-etcd-operator backup` (or snapshot via etcdctl).
- Restore: disaster recovery procedure; requires etcd backup and control-plane reconstruction.

## MachineConfig deep dive

- MachineConfig objects configure node OS-level settings (kernel args, sysctl, users, storage).
- MCD applies on reboot; node goes `NotReady` / `SchedulingDisabled` during update.
- `oc get machineconfigpool` shows pool status; `oc describe machineconfigpool <name>` shows failures.

## Verification

```bash
#!/bin/bash
set -u
echo "== nodes =="; oc get nodes 2>/dev/null || true
echo "== cluster operators failing =="; oc get clusteroperators 2>/dev/null | awk 'NR==1 || ($3!="True" || $4!="False" || $5!="False")' || true
echo "== clusterversion =="; oc get clusterversion 2>/dev/null || true
echo OK
```

## Safety

- Do not edit etcd data directory directly; use etcdctl or OpenShift backup/restore.
- MachineConfig changes trigger node reboots; stage in a maintenance window.
- Deleting a MachineConfigPool can stop node updates; verify before deleting.

---
<ponytail: Scope ceiling — OpenShift cluster admin + etcd + MachineConfig only; add OpenShift Virtualization, Serverless, and Service Mesh when those operators are installed.</ponytail>
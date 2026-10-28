# Rancher Cluster Troubleshooting

## 1. Cluster registration fails (cluster agent / rke2 / k3s)

```bash
kubectl get nodes -n cattle-system
kubectl logs -n cattle-system deployment/rancher
kubectl get cluster -A
```
- Agent can't reach Rancher URL: API URL wrong, firewall TCP 443 from cluster nodes to Rancher
- `cluster-agent` crash: wrong `clusterRegistrationToken`, expired token, time skew (NTP)
- `rke2`/`k3s` install fails: `curl -sfL https://get.rke2.io | sh -` — check `/var/log/rke2/*.log`, internet access to container registry

## 2. Provisioning: node stuck `Pending` / `Provisioning`

- No cloud credential: AWS IAM key, vCenter credential, Azure SP, GCP SA
- Machine pool mismatch: wrong AMI/template, SSH key not in cloud-init/user-data
- Security group blocks: SSH 22, Kubernetes API 6443, RKE2 9345/10250, k3s 6443/10250
- Node never joins: check `kubectl get nodes`, `journalctl -u rke2-server` / `-u rke2-agent`

## 3. Rancher logs

- RKE2: `/var/log/rke2/`, `/var/lib/rancher/rke2/server/logs/`
- K3s: `/var/log/rancher/k3s/`, `journalctl -u rke2-agent`

---
<ponytail: Scope ceiling — cluster registration + node provisioning only; add Fleet GitOps, Harvester, and Longhorn when those are in the stack.</ponytail>
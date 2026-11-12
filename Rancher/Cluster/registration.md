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
## Cluster registration deep dive

```bash
kubectl get nodes -n cattle-system
kubectl logs -n cattle-system deployment/rancher
kubectl get cluster -A
```
- Agent can't reach Rancher URL → API URL wrong, firewall TCP 443 from cluster nodes to Rancher
- `cluster-agent` crash → wrong `clusterRegistrationToken`, expired token, time skew (NTP)
- `rke2`/`k3s` install fails → `curl -sfL https://get.rke2.io \| sh -`; check `/var/log/rke2/*.log`, registry internet access

## Provisioning deep dive

- No cloud credential → AWS IAM key, vCenter credential, Azure SP, GCP SA
- Machine pool mismatch → wrong AMI/template, SSH key not in cloud-init/user-data
- Security group blocks → SSH 22, Kubernetes API 6443, RKE2 9345/10250, k3s 6443/10250
- Node never joins → `kubectl get nodes`, `journalctl -u rke2-server` / `-u rke2-agent`

## Log locations

- RKE2: `/var/log/rke2/`, `/var/lib/rancher/rke2/server/logs/`
- K3s: `/var/log/rancher/k3s/`, `journalctl -u rke2-agent`

## Safety

- Deleting a cluster in Rancher removes workloads; confirm before deleting.

---

## Verified solutions from web docs (Rancher)

### Cluster registration (cluster agent / rke2 / k3s)
- **`Failed to connect to proxy` / connection refused** — node can't reach Rancher server URL on TCP 443. Fix: `curl -vkI https://<rancher-url>`, `nc -zv <rancher> 443`, open firewall.
- **`x509: certificate signed by unknown authority`** — CA cert not trusted. Fix: get `CATTLE_CA_CHECKSUM` from Rancher `cacerts` setting, or set `CATTLE_CA_CHECKSUM` env on agent; for self-signed use `--insecure-skip-server-verification`.
- **`token is invalid`** — registration command stale/wrong cluster/token revoked. Fix: copy a fresh registration command from the cluster UI; don't reuse across clusters.
- **`node already exists`** — duplicate hostname/node name. Fix: `kubectl delete node <name>` or rename hostname (`hostnamectl set-hostname`).
- **`node already exists` / clone VM** — cloned VM has same `/var/lib/rancher/state`. Fix: `rm -rf /var/lib/rancher/state; docker rm -fv rancher-agent; docker rm -fv rancher-agent-state`, then re-register.
- **Agent fails DNS check (`127.0.0.1` / localhost)** — `/etc/resolv.conf` points to dnsmasq loopback; containers can't reach it. Fix: specify real DNS servers for Docker or disable dnsmasq.
- **Host Registration URL** → `curl -i <url>/v1` should return `401` (auth on) or `200` (auth off). Both HTTP and WebSocket (`ws://`) must work; if behind a proxy/LB, ensure WebSocket passthrough.
- **OpenSSL `tlsv1 alert internal error`** — searchlist domain appended to Rancher URL (e.g. `.standby`). Fix: remove the searchlist domain or use a domain not in searchlist.
- **Swap enabled** — kubelet won't start with swap unless configured otherwise. Fix: `swapoff -a`, remove swap from `/etc/fstab`.
- **br_netfilter / bridge-nf-call-iptables** — CNI traffic not reaching iptables. Fix: `modprobe br_netfilter`, `sysctl net.bridge.bridge-nf-call-iptables=1`.

### Node-level connectivity
- RKE2 agents join supervisor on **9345**, control-plane **6443**; K3s agents join **6443**. Test with `nc -zv <host> <port>`.
- Check `iptables -L INPUT -n -v | grep DROP` or `firewall-cmd --list-all`.
- `cattle-cluster-agent` pod in `cattle-system` must be `Running` with low restart count; check `kubectl logs -n cattle-system -l app=cattle-cluster-agent --previous`.
- RBAC `forbidden: User 'system:serviceaccount:cattle-system:cattle'` → force agent redeploy: `kubectl annotate clusters.management.cattle.io <cluster-id> io.cattle.agent.force.deploy=true`.

<ponytail: Scope ceiling — cluster registration + node provisioning only; add Fleet GitOps, Harvester, and Longhorn when those are in the stack.</ponytail>
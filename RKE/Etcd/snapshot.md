# RKE Etcd Troubleshooting

## 1. etcd down / cluster unhealthy

```bash
rke etcd snapshot save --cluster.yml cluster.yml
rke etcd snapshot ls --cluster.yml cluster.yml
rke etcd snapshot restore --cluster.yml cluster.yml --etcd-snapshot-name <name>
```
- etcd quorum lost: fewer than majority of etcd nodes up — restore from snapshot
- etcd disk full: `/var/lib/etcd` full — compact etcd (`etcdctl compact`), expand disk
- `rke etcd snapshot save` fails: SSH to etcd nodes, docker access, `/opt/rke` writable

## 2. Certificate rotation / expiration

```bash
rke up --cluster.yml cluster.yml --rotate-certificates
```
- Kubelet/controller certs expired: rotate with `--rotate-certificates`, restart kubelet on nodes
- `kubectl` fails `x509: certificate has expired`: regenerate `kube_config_cluster.yml` (`rke up --local` or `rke config`)

## 3. kubectl access

```bash
export KUBECONFIG=kube_config_cluster.yml
kubectl cluster-info
kubectl get nodes
```
- `kube_config_cluster.yml` missing: re-run `rke up` or `rke kubeconfig --cluster.yml cluster.yml --save`
- Context wrong: `kubectl config current-context`, `kubectl config use-context <cluster>`

## RKE etcd deep dive

```bash
rke etcd snapshot save --cluster.yml cluster.yml
rke etcd snapshot ls --cluster.yml cluster.yml
rke etcd snapshot restore --cluster.yml cluster.yml --etcd-snapshot-name <name>
```
- etcd quorum lost → fewer than majority of etcd nodes up; restore from snapshot
- etcd disk full → `/var/lib/etcd` full; compact etcd (`etcdctl compact`), expand disk
- `rke etcd snapshot save` fails → SSH to etcd nodes, docker access, `/opt/rke` writable

## Certificate rotation

```bash
rke up --cluster.yml cluster.yml --rotate-certificates
```
- Kubelet/controller certs expired → rotate with `--rotate-certificates`, restart kubelet on nodes
- `kubectl` fails `x509: certificate has expired` → regenerate `kube_config_cluster.yml` (`rke up --local` or `rke config`)

## kubectl access

```bash
export KUBECONFIG=kube_config_cluster.yml
kubectl cluster-info
kubectl get nodes
```
- `kube_config_cluster.yml` missing → re-run `rke up` or `rke kubeconfig --cluster.yml cluster.yml --save`
- Context wrong → `kubectl config current-context`, `kubectl config use-context <cluster>`

## Log locations

- RKE: local machine `~/.rkestate/`, cluster state rke state file
- Nodes: `/var/log/pods/`, `journalctl -u kubelet`, `docker logs <container>`
- etcd: `/var/lib/etcd/` via `etcdctl` with client certs from `/etc/kubernetes/ssl`

## Safety

- `rke etcd snapshot restore` is destructive; only after confirming quorum loss.

---

<ponytail: Scope ceiling — RKE1 etcd + certs + kubeconfig only.</ponytail>
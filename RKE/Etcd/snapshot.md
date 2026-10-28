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

---
<ponytail: Scope ceiling — RKE1 etcd + certs + kubeconfig only.</ponytail>
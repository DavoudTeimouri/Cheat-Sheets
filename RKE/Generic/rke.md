# RKE Troubleshooting

**Category:** Cloud-Native
## 1. Cluster creation fails (rke up)

```bash
rke up --cluster.yml cluster.yml
rke config
```
- SSH connection failed: node unreachable (`ssh root@<node>`), wrong key path (`ssh_key_path`), port 22 blocked, root login disabled (`PermitRootLogin yes`)
- Docker missing/old: RKE needs Docker on every node; install docker, enable service (`systemctl enable --now docker`)
- `rke` binary not found: download matching release, `chmod +x`, `PATH`

## 2. Nodes NotReady / kubelet issues

```bash
kubectl get nodes
kubectl describe node <node>
ssh <node> journalctl -u kubelet
ssh <node> docker ps
```
- `NotReady`: kubelet not running (`systemctl status kubelet`), container runtime (docker/containerd) down, node lacks `br_netfilter` / `overlay` modules
- Kubelet crashed: disk full (`df -h /var/lib/kubelet`), wrong `--cloud-provider`, certificate mismatch (`/etc/kubernetes/ssl`)
- Flannel/calico not running: CNI pod crash — `kubectl get pods -n kube-system`, check MTU (flannel default 1450 vs jumbo frames), wrong interface (`--iface eth1`)

## 3. etcd down / cluster unhealthy

```bash
rke etcd snapshot save --cluster.yml cluster.yml
rke etcd snapshot ls --cluster.yml cluster.yml
rke etcd snapshot restore --cluster.yml cluster.yml --etcd-snapshot-name <name>
```
- etcd quorum lost: fewer than majority of etcd nodes up — restore from snapshot
- etcd disk full: `/var/lib/etcd` full — compact etcd (`etcdctl compact`), expand disk
- `rke etcd snapshot save` fails: SSH to etcd nodes, docker access, `/opt/rke` writable

## 4. Control plane / worker role issues

- Node has wrong role: `cluster.yml` `roles: [controlplane, etcd, worker]` mismatch — re-run `rke up` after editing
- Controlplane node tainted: tolerations missing on pods, `kubectl get nodes` shows `node-role.kubernetes.io/master:NoSchedule`
- Worker joins but no pods: CNI not ready, `kube-proxy` crash (`kubectl -n kube-system get pods`)

## 5. Upgrade fails (`rke up` with new version)

```bash
rke up --cluster.yml cluster.yml
rke up --cluster.yml cluster.yml --only-kubernetes-version
```
- Upgrade stuck: drain cordon issues, PDBs blocking, node drain timeout — increase `upgrade_strategy` drain timeout in `cluster.yml`
- Version mismatch: `system_images` registry unreachable (default `docker.io/rancher`), use private mirror:
```yaml
system_images:
  etcd: registry.example.com/rancher/etcd:vX.X.X
  kubernetes: registry.example.com/rancher/hyperkube:vX.X.X
```

## 6. Certificate rotation / expiration

```bash
rke up --cluster.yml cluster.yml --rotate-certificates
```
- Kubelet/controller certs expired: rotate with `--rotate-certificates`, restart kubelet on nodes
- `kubectl` fails `x509: certificate has expired`: regenerate `kube_config_cluster.yml` (`rke up --local` or `rke config`)

## 7. `kubectl` access

```bash
export KUBECONFIG=kube_config_cluster.yml
kubectl cluster-info
kubectl get nodes
```
- `kube_config_cluster.yml` missing: re-run `rke up` or `rke kubeconfig --cluster.yml cluster.yml --save`
- Context wrong: `kubectl config current-context`, `kubectl config use-context <cluster>`

## Log locations

- RKE: local machine `~/.rkestate/`, cluster state rke state file
- Nodes: `/var/log/pods/`, `journalctl -u kubelet`, `docker logs <container>`
- etcd: `/var/lib/etcd/` via `etcdctl` with client certs from `/etc/kubernetes/ssl`

## Quick self-check

```bash
#!/bin/bash
set -u
echo "== rke binary =="; rke --version 2>/dev/null || true
echo "== kubeconfig =="; KUBECONFIG=kube_config_cluster.yml kubectl get nodes 2>&1 | head -3 || true
echo OK
```

---
<ponytail: Scope ceiling — RKE1 (classic) clusters only; RKE2 troubleshooting lives in Rancher sheet since RKE2 is provisioned through Rancher.</ponytail>
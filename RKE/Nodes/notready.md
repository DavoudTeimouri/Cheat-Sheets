# RKE Nodes Troubleshooting

## 1. Nodes NotReady / kubelet issues

```bash
kubectl get nodes
kubectl describe node <node>
ssh <node> journalctl -u kubelet
ssh <node> docker ps
```
- `NotReady`: kubelet not running (`systemctl status kubelet`), container runtime (docker/containerd) down, node lacks `br_netfilter` / `overlay` modules
- Kubelet crashed: disk full (`df -h /var/lib/kubelet`), wrong `--cloud-provider`, certificate mismatch (`/etc/kubernetes/ssl`)
- Flannel/calico not running: CNI pod crash — `kubectl get pods -n kube-system`, check MTU (flannel default 1450 vs jumbo frames), wrong interface (`--iface eth1`)

## 2. Control plane / worker roles

- Controlplane node tainted: tolerations missing on pods, `kubectl get nodes` shows `node-role.kubernetes.io/master:NoSchedule`
- Worker joins but no pods: CNI not ready, `kube-proxy` crash (`kubectl -n kube-system get pods`)

---
<ponytail: Scope ceiling — RKE1 node/kubelet/CNI only.</ponytail>
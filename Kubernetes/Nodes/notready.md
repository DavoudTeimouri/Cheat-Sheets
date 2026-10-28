# Kubernetes Node Troubleshooting

## 1. Node NotReady

```bash
kubectl get nodes
kubectl describe node <node>
journalctl -u kubelet -u containerd -u docker
```
- Kubelet down: `systemctl restart kubelet`
- Container runtime down: `systemctl restart containerd` or `docker`
- Node disk full: `/var/lib/kubelet` full → evict pods, expand disk
- Kubelet certificate expired: renew or rotate certs

## 2. Taints / cordon

```bash
kubectl taint nodes <node> key=value:NoSchedule
kubectl uncordon <node>
kubectl cordon <node>
kubectl describe node <node> | grep -i taint
```
- Pods not scheduling: node has taint without matching toleration
- Node cordoned: no new pods scheduled → `kubectl uncordon`

## 3. Kubelet eviction / node pressure

```bash
kubectl describe node <node> | grep -A5 Allocatable
kubectl get events --sort-by=.lastTimestamp
```
- Disk pressure: `/var/lib/kubelet` full → evict pods, image GC, expand disk
- PID pressure: increase `--max-pids`, limit container PIDs
- Memory pressure: evict low-priority pods, add nodes

## 4. kube-proxy issues

```bash
kubectl get pods -n kube-system -l k8s-app=kube-proxy
kubectl logs -n kube-system daemonset/kube-proxy
iptables -t nat -L | grep KUBE   # iptables mode
```
- Services not reachable: kube-proxy crashed, IPVS vs iptables mode mismatch, conntrack full

---
<ponytail: Scope ceiling — node health, kubelet, taints, cordon, eviction only; add node auto-scaling, node problem detector, and GPU nodes when those exist.</ponytail>
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

## Kubelet eviction / node pressure deep dive

```bash
kubectl describe node <node> \| grep -A5 Allocatable
kubectl get events --sort-by=.lastTimestamp
kubectl describe node <node> \| grep -iE 'pressure|evict'
```
- Disk pressure → `/var/lib/kubelet` full → evict pods, image GC (`crictl rmi --prune`), expand disk
- PID pressure → increase `--max-pids`, limit container PIDs
- Memory pressure → evict low-priority pods, add nodes, set `eviction-hard`

## kube-proxy issues

```bash
kubectl get pods -n kube-system -l k8s-app=kube-proxy
kubectl logs -n kube-system daemonset/kube-proxy
iptables -t nat -L \| grep KUBE   # iptables mode
ipvsadm -ln                      # IPVS mode
```
- Services not reachable → kube-proxy crashed, IPVS vs iptables mode mismatch, conntrack full (`conntrack -L \| wc -l`)

## Cordon / drain / uncordon

```bash
kubectl cordon <node>            # mark unschedulable
kubectl drain <node> --ignore-daemonsets --delete-emptydir-data   # evict pods
kubectl uncordon <node>          # mark schedulable again
kubectl get nodes \| grep <node>
```
- Drain blocked by PDB → lower `maxUnavailable` or add replicas
- Drain blocked by local storage → pods with `emptyDir` can't move; delete data or use `--delete-emptydir-data`

## Verification

```bash
#!/bin/bash
set -u
NODE="${1:-}"
echo "== node =="; kubectl get node "$NODE" 2>/dev/null || true
echo "== pressure =="; kubectl describe node "$NODE" 2>/dev/null \| grep -iE 'pressure|kubelet' \| head -5 || true
echo "== pods on node =="; kubectl get pods -A --field-selector spec.nodeName="$NODE" 2>/dev/null \| head -10 || true
echo OK
```

## Safety

- `kubectl drain` evicts all pods; only on nodes you intend to remove from service.
- `--delete-emptydir-data` destroys local ephemeral data; confirm first.

---

<ponytail: Scope ceiling — node health, kubelet, taints, cordon, eviction only; add node auto-scaling, node problem detector, and GPU nodes when those exist.</ponytail>
# Kubernetes Troubleshooting

## 1. Pod in CrashLoopBackOff / OOMKilled

```bash
kubectl get pods -n <ns>
kubectl describe pod <pod> -n <ns>
kubectl logs <pod> -n <ns> --previous
kubectl logs <pod> -n <ns> -c <container>
```
- CrashLoopBackOff: app exits immediately — fix entrypoint, configmaps, secrets, DB connectivity
- OOMKilled: raise `resources.limits.memory`, profile the app, or add swap if supported

## 2. ImagePullBackOff / ErrImagePull

```bash
kubectl describe pod <pod> -n <ns>   # events: FailedToPull, unauthorized, not found
kubectl get secrets -n <ns>          # imagePullSecrets present?
```
Fix: correct image tag/registry, `imagePullSecrets`, registry credentials (`kubernetes.io/dockerconfigjson`), network policy allowing registry egress.

## 3. Pod stuck Pending

```bash
kubectl describe pod <pod> -n <ns>
```
Causes: unschedulable (no node fits), node taints/tolerations, node selector/affinity mismatch, PVC not bound, resource requests exceed node capacity, PriorityClass preemption blocked.

## 4. PVC not bound

```bash
kubectl get pvc -n <ns>
kubectl get pv
kubectl describe pvc <pvc> -n <ns>
```
- StorageClass missing/default mismatch
- Volume mode/access mode mismatch (RWO vs RWX)
- CSI driver not installed or unhealthy (`kubectl get csidrivers`, `kubectl get pods -n kube-system -l app=csi-...`)
- Topology/spread constraints (zone mismatch)

## 5. Service unreachable from pod

```bash
kubectl get svc -n <ns>
kubectl get endpoints <svc> -n <ns>   # empty = no ready pods
kubectl run tmp --rm -i --tty --image=busybox -- nslookup <svc>.<ns>.svc.cluster.local
kubectl run tmp --rm -i --tty --image=busybox -- wget -qO- http://<svc>:<port>
```
- Endpoints empty: pod labels don't match `selector`, pods not Ready
- CoreDNS broken: `kubectl get pods -n kube-system -l k8s-app=kube-dns`, restart CoreDNS

## 6. Ingress returns 502/503/404

```bash
kubectl get ingress -n <ns>
kubectl describe ingress <ing> -n <ns>
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller
```
- 502: backend service/pod unhealthy or wrong targetPort
- 503: no endpoints
- 404: host/path rule mismatch, TLS cert missing, ingress class not set (`kubernetes.io/ingress.class: nginx` or `ingressClassName`)

## 7. Node NotReady

```bash
kubectl get nodes
kubectl describe node <node>
journalctl -u kubelet -u containerd -u docker   # on the node
```
- Kubelet down, container runtime down, node disk full (`df -h /var/lib/kubelet`), CNI missing, certificate expired (`/var/lib/kubelet/pki`), kube-proxy issues.

## 8. DNS resolution fails inside cluster

```bash
kubectl exec -it <pod> -n <ns> -- nslookup kubernetes.default
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl logs -n kube-system deployment/coredns
```
Fix: restart CoreDNS, check `ConfigMap/coredns`, upstream resolvers, NetworkPolicy blocking UDP 53.

## 9. Certificates expired (etcd, kubelet, front-proxy)

```bash
kubectl get csr
kubectl certificate approve <csr-name>
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -dates
```
Control-plane certs: redeploy with `kubeadm certs renew all` (kubeadm clusters) then restart static pods.

## 10. HPA not scaling

```bash
kubectl get hpa -n <ns>
kubectl describe hpa <hpa> -n <ns>
kubectl top pods -n <ns>            # requires metrics-server
```
- No metrics: metrics-server not installed or APIAggregation broken (`kubectl get apiservices | grep False`)
- `targetValue`/`targetAverageValue` never reached

## 11. Eviction / node pressure

```bash
kubectl describe node <node> | grep -A5 Allocatable
kubectl get events --sort-by=.lastTimestamp
```
- Disk pressure: `/var/lib/kubelet` full — evict pods, expand disk, image GC
- PID pressure: increase `max-pids`, limit container PIDs
- Memory pressure: evict low-priority pods, add nodes, set `eviction-hard`

## Log locations

- Control plane (kubeadm): `/var/log/pods/kube-system_*`, static pod logs in `/var/log/pods/`
- Kubelet: `journalctl -u kubelet`
- Container runtime: `journalctl -u containerd` / `journalctl -u docker`
- API server: `journalctl -u kube-apiserver` (static: `/var/log/pods/kube-system_kube-apiserver_*/1.log`)

## Quick self-check

```bash
#!/bin/bash
set -u
echo "== nodes =="; kubectl get nodes
echo "== pending/evicted pods =="; kubectl get pods -A | grep -E 'Pending|Evicted|CrashLoop|ImagePull' || true
echo "== apiservices =="; kubectl get apiservices | grep -v True || true
echo "== coredns =="; kubectl get pods -n kube-system -l k8s-app=kube-dns
echo OK
```

---
<ponytail: Scope ceiling — core cluster ops only; add service mesh (Istio/Linkerd), multi-cluster, and admission webhooks when those run in the cluster.</ponytail>
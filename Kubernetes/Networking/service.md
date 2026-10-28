# Kubernetes Networking Troubleshooting

## 1. Service unreachable from pod

```bash
kubectl get svc -n <ns>
kubectl get endpoints <svc> -n <ns>       # empty = no ready pods
kubectl run tmp --rm -i --tty --image=busybox -- nslookup <svc>.<ns>.svc.cluster.local
kubectl run tmp --rm -i --tty --image=busybox -- wget -qO- http://<svc>:<port>
```
- Endpoints empty: pod labels don't match `selector`, pods not Ready
- CoreDNS broken: restart `coredns` in `kube-system`

## 2. Ingress returns 502 / 503 / 404

```bash
kubectl get ingress -n <ns>
kubectl describe ingress <ing> -n <ns>
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller
```
- 502: backend service/pod unhealthy or wrong `targetPort`
- 503: no endpoints ready
- 404: host/path rule mismatch, TLS cert missing, `ingressClassName` not set

## 3. DNS resolution fails inside cluster

```bash
kubectl exec -it <pod> -n <ns> -- nslookup kubernetes.default
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl logs -n kube-system deployment/coredns
```
- Restart CoreDNS, check `ConfigMap/coredns`, upstream resolvers, NetworkPolicy blocking UDP/TCP 53

## 4. NetworkPolicy blocking traffic

```bash
kubectl get networkpolicy -A
kubectl describe networkpolicy <np> -n <ns>
```
- Default-deny policy blocking egress/ingress: add explicit allow rules for required ports/peers

---
<ponytail: Scope ceiling — Services, Ingress, CoreDNS, NetworkPolicy only; add service mesh (Istio/Linkerd) and CNI-specific debugging when those are installed.</ponytail>
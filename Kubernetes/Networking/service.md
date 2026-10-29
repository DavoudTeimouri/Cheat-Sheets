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

## NetworkPolicy blocking traffic

```bash
kubectl get networkpolicy -A
kubectl describe networkpolicy <np> -n <ns>
kubectl get pod <pod> -n <ns> -o yaml \| grep -A10 networkPolicy
```
- Default-deny policy blocking egress/ingress → add explicit allow rules for required ports/peers
- `podSelector` empty → policy applies to ALL pods in namespace (careful!)

## CoreDNS deep dive

```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl logs -n kube-system deployment/coredns
kubectl exec -it <pod> -n <ns> -- nslookup kubernetes.default
kubectl get configmap coredns -n kube-system -o yaml
```
- `looop` / crash → `Corefile` syntax error, upstream unreachable, `forward` loop
- Services not resolving → `kube-proxy` broken, NetworkPolicy blocking UDP/TCP 53, `resolv.conf` in pod wrong

## Ingress class & controller

```bash
kubectl get ingressclass
kubectl get ingress -n <ns> -o yaml \| grep -A5 ingressClassName
kubectl get -n ingress-nginx deployment/ingress-nginx-controller -o yaml \| grep image
```
- 404 on all paths → `ingressClassName: nginx` not set, or wrong class
- TLS handshake fails → Secret missing `tls.crt`/`tls.key` keys, cert not covering host

## Verification

```bash
#!/bin/bash
set -u
NS="${1:-default}"
echo "== dns test =="; kubectl run dns-test --rm -i --tty --image=busybox -n "$NS" -- nslookup kubernetes.default.svc.cluster.local 2>&1 \| tail -3 || true
echo "== endpoints empty? =="; kubectl get endpoints -n "$NS" 2>/dev/null || true
echo "== networkpolicies =="; kubectl get networkpolicy -n "$NS" 2>/dev/null || true
echo OK
```

## Safety

- Deleting CoreDNS ConfigMap breaks all cluster DNS; edit and apply carefully.
- Default-deny NetworkPolicy applied to all pods can isolate the entire namespace; test on one app first.

---

<ponytail: Scope ceiling — Services, Ingress, CoreDNS, NetworkPolicy only; add service mesh (Istio/Linkerd) and CNI-specific debugging when those are installed.</ponytail>
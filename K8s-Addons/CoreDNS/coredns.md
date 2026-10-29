# CoreDNS Troubleshooting

**Category:** Cloud-Native

## Symptom → Cause → Fix

| Exact symptom | Likely cause | Fix |
|---------------|--------------|-----|
| `Temporary failure in name resolution` | CoreDNS crash/loop, `Corefile` syntax error, upstream unreachable | `kubectl logs -n kube-system deployment/coredns`, restart CoreDNS |
| `looop` / crash loop | `Corefile` `forward` loop, syntax error | Check `ConfigMap/coredns`, fix `forward` upstream, remove loops |
| Services not resolving inside cluster | `kube-proxy` broken, NetworkPolicy blocking UDP/TCP 53, pod `resolv.conf` wrong | Check `kube-proxy` pods, NetworkPolicy, `/etc/resolv.conf` in test pod |
| `pod has unbound ImmediateVolumes` | ephemeral storage PVC not bound | Increase storage or delete old PVCs |

## Diagnosis

```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl logs -n kube-system deployment/coredns --tail=100
kubectl get configmap coredns -n kube-system -o yaml
kubectl exec -it <pod> -n <ns> -- nslookup kubernetes.default.svc.cluster.local
kubectl exec -it <pod> -n <ns> -- cat /etc/resolv.conf
```

## Corefile deep dive

- **`forward . /etc/resolv.conf`** → forwards to host resolver; can cause loops if host points back to CoreDNS
- **`upstream`** → specify external resolvers (e.g., `forward . 8.8.8.8 1.1.1.1`)
- **`loop` detection** → CoreDNS detects and breaks forwarding loops; check logs for `loop` messages

## Verification

```bash
#!/bin/bash
set -u
NS="${1:-kube-system}"
echo "== coredns pods =="; kubectl get pods -n "$NS" -l k8s-app=kube-dns 2>/dev/null || true
echo "== dns test =="; kubectl run dns-test --rm -i --tty --image=busybox -n "$NS" -- nslookup kubernetes.default.svc.cluster.local 2>&1 | tail -3 || true
echo "== resolv.conf =="; kubectl run dns-resolv --rm -i --tty --image=busybox -n "$NS" -- cat /etc/resolv.conf 2>&1 | tail -5 || true
echo OK
```

## Safety

- Deleting the CoreDNS ConfigMap breaks all cluster DNS; edit and `kubectl apply` carefully.
- `forward` loops can cause DNS amplification; test changes on a non-critical namespace first.

---
<ponytail: Scope ceiling — CoreDNS cluster DNS only; add NodeLocal DNSCache, CoreDNS with Kubernetes service discovery debugging, and custom Corefile plugins when used.</ponytail>
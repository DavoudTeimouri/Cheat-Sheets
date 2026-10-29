# Ingress-NGINX Troubleshooting

**Category:** Cloud-Native

## Symptom → Cause → Fix

| Exact symptom | Likely cause | Fix |
|---------------|--------------|-----|
| `502 Bad Gateway` | Backend service/pod not Ready, wrong `targetPort`, health check failing | `kubectl get endpoints <svc>`, fix service selector/pod labels, fix `targetPort` |
| `503 Service Unavailable` | No endpoints ready | Pods failing readiness, scale to >0, fix readiness probe |
| `404 on all paths` | Ingress class not set, host/path rule mismatch | Set `ingressClassName: nginx` or `kubernetes.io/ingress.class: nginx`, check host/path |
| `503` TLS handshake fails | Secret missing `tls.crt`/`tls.key`, cert not covering host | Create secret with both keys, cert SAN covers host |
| Controller pod CrashLoopBackOff | Admission webhook blocking, node port conflict (`hostNetwork`), config invalid | `kubectl logs -n ingress-nginx deployment/ingress-nginx-controller`, `nginx -t` equivalent via config check |

## Diagnosis

```bash
kubectl get ingress -n <ns>
kubectl describe ingress <ing> -n <ns>
kubectl get endpoints <backend-svc> -n <ns>
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller --tail=100
kubectl get -n ingress-nginx service ingress-nginx-controller -o wide
kubectl get -n ingress-nginx daemonset/deployment ingress-nginx-controller -o yaml | grep -A5 image
```

## Common root causes

- **Wrong targetPort** → service `targetPort` must match container port, not nodePort
- **Selector mismatch** → service `selector` labels don't match pod labels; endpoints empty
- **TLS secret keys** → secret must have literal keys `tls.crt` and `tls.key`, not `cert`/`key`
- **Host header** → browser sends `Host` matching ingress `rules[].host`; test with `curl -H 'Host: app.example.com'`
- **Admission webhook** → `ValidatingWebhookConfiguration` rejects malformed Ingress; check controller logs for webhook errors

## Verification

```bash
#!/bin/bash
set -u
NS="${1:-ingress-nginx}"
ING="${2:-}"
echo "== controller =="; kubectl get pods -n "$NS" -l app.kubernetes.io/name=ingress-nginx 2>/dev/null || true
echo "== ingresses =="; kubectl get ingress -A 2>/dev/null | head -10 || true
[ -n "$ING" ] && echo "== describe ==" && kubectl describe ingress "$ING" -n "$NS" 2>/dev/null | tail -20 || true
echo OK
```

## Safety

- Deleting the Ingress-NGINX controller drops all Ingress traffic; drain nodes first if upgrading.
- Changing `ingressClassName` on existing Ingress objects stops routing until reconciled.

---
<ponytail: Scope ceiling — Ingress-NGINX controller only; add NGINX Plus, OpenResty, Kong, and contour when those ingress controllers are used.</ponytail>
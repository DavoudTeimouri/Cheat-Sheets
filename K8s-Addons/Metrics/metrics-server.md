# metrics-server Troubleshooting

**Category:** Cloud-Native

## Symptom → Cause → Fix

| Exact symptom | Likely cause | Fix |
|---------------|--------------|-----|
| `kubectl top nodes/pods` fails | metrics-server not installed, APIService not Ready | `kubectl get apiservices v1beta1.metrics.k8s.io`, install metrics-server |
| `certificate signed by unknown authority` | Kubelet serving cert mismatch, CA bundle wrong | Fix `APIService` CA bundle or Kubelet TLS trust (`--kubelet-use-node-status-port`) |
| HPA shows `<unknown>` / no scaling | No metrics from metrics-server | `kubectl top pods` works? Check metrics-server logs and `--kubelet-use-node-status-port` |
| metrics-server CrashLoopBackOff | Args incompatible with kubelet version, `--kubelet-insecure-tls` needed | Check `kubectl logs -n kube-system deployment/metrics-server` |

## Diagnosis

```bash
kubectl top nodes
kubectl top pods -n <ns>
kubectl get apiservices v1beta1.metrics.k8s.io
kubectl get -n kube-system deployment/metrics-server -o yaml
kubectl logs -n kube-system deployment/metrics-server --tail=100
kubectl get --raw /apis/metrics.k8s.io/v1beta1/nodes
```

## Common root causes

- **Aggregation layer** → `APIService` condition `Available` must be `True`; if `False`, metrics-server or CA bundle is broken
- **Kubelet TLS** → metrics-server connects to kubelet on 10250 with serving cert; mismatch causes `x509: certificate signed by unknown authority`
- **Address types** → `--kubelet-preferred-address-types=InternalDNS,ExternalDNS,InternalIP,ExternalIP,Hostname` controls which node address is used
- **Resource quota** → namespace quota can block metrics-server pods from scheduling

## Verification

```bash
#!/bin/bash
set -u
echo "== apiservice =="; kubectl get apiservices v1beta1.metrics.k8s.io 2>/dev/null || true
echo "== raw nodes =="; kubectl get --raw /apis/metrics.k8s.io/v1beta1/nodes 2>&1 | head -c 200; echo
echo "== top nodes =="; kubectl top nodes 2>&1 | head -5 || true
echo OK
```

## Safety

- Disabling TLS verification (`--kubelet-insecure-tls`) is a workaround only; fix CA trust for production.
- metrics-server restarts briefly interrupt HPA decisions; scale HPA minReplicas up during maintenance if needed.

---
<ponytail: Scope ceiling — metrics-server + HPA metrics only; add Prometheus Adapter, custom metrics, and Kubernetes event-driven autoscaling (KEDA) when those are used.</ponytail>
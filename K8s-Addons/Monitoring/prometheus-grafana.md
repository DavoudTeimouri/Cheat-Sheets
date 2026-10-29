# Prometheus / Grafana Troubleshooting

**Category:** Cloud-Native

## Symptom → Cause → Fix

| Exact symptom | Likely cause | Fix |
|---------------|--------------|-----|
| Prometheus not scraping | `ServiceMonitor` selector mismatch, endpoints missing, namespace label missing | Check `ServiceMonitor` `selector.matchLabels` vs pod labels, add `prometheus: scrape` namespace label |
| Grafana datasource 500 | Prometheus URL wrong, RBAC, `skipTLSVerify` for self-signed certs | Fix datasource URL, add `skipTLSVerify`, check service account |
| Alertmanager not firing | `route` config wrong, `inhibit_rules`, receiver keys missing | Check `Alertmanager` config, receiver names match |

## Diagnosis

```bash
kubectl get pods -n monitoring
kubectl get servicemonitor,prometheusrules -A
kubectl logs -n monitoring prometheus-kube-prometheus-stack-prometheus-0 --tail=100
kubectl logs -n monitoring prometheus-kube-prometheus-stack-grafana --tail=100
kubectl logs -n monitoring prometheus-kube-prometheus-stack-alertmanager --tail=100
kubectl get servicemonitor <name> -n <ns> -o yaml
```

## ServiceMonitor deep dive

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: app-metrics
  labels:
    release: prometheus   # must match Prometheus `serviceMonitorSelector`
spec:
  selector:
    matchLabels:
      app: myapp          # must match pod labels
  endpoints:
  - port: http
    path: /metrics
    interval: 30s
```
- **Namespace label** → some setups require `prometheus: scrape` on the namespace
- **Label match** → `ServiceMonitor.spec.selector` must match pod labels, NOT service labels

## Alertmanager deep dive

- **Receiver mismatch** → alert `receiver` name must exist in `route.receivers`
- **Inhibit rules** → can suppress alerts unexpectedly; check `inhibit_rules`
- **Repeat interval** → alerts re-send after `repeat_interval`; set appropriately

## Verification

```bash
#!/bin/bash
set -u
NS="${1:-monitoring}"
echo "== pods =="; kubectl get pods -n "$NS" 2>/dev/null || true
echo "== servicemonitors =="; kubectl get servicemonitor -A 2>/dev/null | head -5 || true
echo "== prometheus targets =="; kubectl get --raw /api/v1/namespaces/$NS/services/prometheus-operated:9090/proxy/targets 2>/dev/null | head -c 300; echo
echo OK
```

## Safety

- Prometheus restarts clear in-memory series; configure retention and remote write for long-term storage.
- Alertmanager config changes require rollout; test with `amtool` before applying.

---
<ponytail: Scope ceiling — Prometheus/Grafana/Alertmanager + ServiceMonitor; add Thanos, Mimir, VictoriaMetrics, and Grafana Loki when those are used.</ponytail>
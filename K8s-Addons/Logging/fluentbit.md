# FluentBit Troubleshooting

**Category:** Cloud-Native

## Symptom → Cause → Fix

| Exact symptom | Likely cause | Fix |
|---------------|--------------|-----|
| Logs not reaching backend | Backend endpoint unreachable, wrong `Host`/port/TLS, buffer overflow | Check `Host`/`Port`/`tls` in `[OUTPUT]`, `bufsize`/`mem_buf_limit` |
| Missing container logs | `tail` path wrong (`/var/log/containers/*.log`), permission on `/var/log` | Run as privileged or hostPath with correct perms, verify path |
| FluentBit crash | Config syntax error, output plugin unreachable, OOM | `kubectl logs -n logging daemonset/fluent-bit`, validate config |

## Diagnosis

```bash
kubectl logs -n logging daemonset/fluent-bit --tail=100
kubectl get daemonset -n logging
kubectl get configmap -n logging | grep fluentbit
kubectl describe daemonset -n logging fluent-bit
```

## Config deep dive

```ini
[INPUT]
    Name tail
    Path /var/log/containers/*.log
    Tag kube.*
    Read_from_Head true

[OUTPUT]
    Name loki
    Host http://loki.logging.svc.cluster.local
    Port 3100
    Labels job=fluentbit
    Auto_kubernetes_labels true
    bufsize 5M
    mem_buf_limit 50M
```
- **`Path`** → must match where container runtime writes logs (`/var/log/containers/*.log` for containerd/cri-o, `/var/log/pods/` for kubelet)
- **`Read_from_Head`** → `true` reads from beginning; `false` (default) tails new lines only
- **`Auto_kubernetes_labels`** → enriches logs with k8s metadata; requires kubelet read access

## Permission deep dive

- FluentBit DaemonSet runs as privileged or with hostPath `/var/log` mounted
- SELinux → `chcon -Rt container_file_t /var/log` or run privileged
- Node IAM → for cloud outputs, node needs cloud logging permissions

## Verification

```bash
#!/bin/bash
set -u
NS="${1:-logging}"
echo "== daemonset =="; kubectl get daemonset -n "$NS" 2>/dev/null || true
echo "== pods =="; kubectl get pods -n "$NS" -l app=fluentbit 2>/dev/null || true
echo "== log tail =="; kubectl logs -n "$NS" daemonset/fluent-bit --tail=10 2>/dev/null || true
echo OK
```

## Safety

- FluentBit reads `/var/log/containers/*.log` which can grow large; set `bufsize` and rotation.
- Sensitive data in logs → configure `exclude` or mask before shipping to external backend.

---
<ponytail: Scope ceiling — FluentBit + Loki/Elasticsearch log collection; add Fluentd, Vector, and Splunk forwarder when those are used.</ponytail>
# Kubernetes Pod Troubleshooting

## 1. CrashLoopBackOff / OOMKilled

```bash
kubectl get pods -n <ns>
kubectl describe pod <pod> -n <ns>
kubectl logs <pod> -n <ns> --previous
kubectl logs <pod> -n <ns> -c <container>
```
- CrashLoopBackOff: app exits immediately — fix entrypoint, ConfigMaps, Secrets, DB connectivity
- OOMKilled: raise `resources.limits.memory`, profile the app, or add node RAM

## 2. ImagePullBackOff / ErrImagePull

```bash
kubectl describe pod <pod> -n <ns>
kubectl get secrets -n <ns>
```
- Wrong image tag/registry: correct the image reference
- Registry auth: create/update `imagePullSecrets` (`kubernetes.io/dockerconfigjson`)
- Network: allow egress to the registry (port 443)

## 3. Pod stuck Pending

```bash
kubectl describe pod <pod> -n <ns>
```
Causes:
- Unschedulable: no node fits (requests exceed capacity)
- Taints/tolerations: node tainted without matching pod toleration
- Node selector/affinity mismatch: pod can't land on any matching node
- PVC not bound: StorageClass missing, access mode mismatch, topology/zone constraint

## 4. Container restart loop

- Check previous container logs: `kubectl logs <pod> --previous`
- Liveness probe failing: probe too aggressive, app not responding on check path
- Startup probe: app needs more time to initialize → increase `failureThreshold`/`periodSeconds`

## Container restart loop

```bash
# Previous container logs (the crashed one)
kubectl logs <pod> -n <ns> --previous
kubectl logs <pod> -n <ns> -c <container> --previous

# Liveness probe failing → probe too aggressive or app not responding on check path
kubectl describe pod <pod> -n <ns> \| grep -A5 Liveness

# Startup probe: app needs more time to initialize
kubectl get pod <pod> -n <ns> -o yaml \| grep -A8 startupProbe
```

- Restart loop → previous container exit code != 0; check `--previous` logs, not current
- Liveness probe failing → probe interval too short, wrong path/port, app not listening yet; increase `failureThreshold`/`periodSeconds`
- Startup probe → give slow-starting apps more time before liveness kicks in

## ImagePullBackOff / ErrImagePull deep dive

```bash
kubectl describe pod <pod> -n <ns>   # events: FailedToPull, unauthorized, not found
kubectl get secrets -n <ns>          # imagePullSecrets present?
kubectl get sa <sa> -n <ns> -o yaml  # imagePullSecrets referenced?
```

- Wrong image tag/registry → correct the image reference
- Registry auth → create/update `imagePullSecrets` (`kubernetes.io/dockerconfigjson`), reference in ServiceAccount `imagePullSecrets`
- Network → allow egress to registry (TCP 443)
- Image not found → typo in image name/tag, or image deleted from registry

## Node affinity / taints quick reference

| Symptom | Fix |
|---------|-----|
| `0/3 nodes are available: 3 Insufficient cpu` | Lower requests or add nodes |
| `0/3 nodes are available: 3 node(s) had untolerated taint` | Add toleration or remove taint |
| `0/3 nodes are available: 3 node(s) didn't match node selector` | Fix `nodeSelector`/`nodeAffinity` labels |
| `0/3 nodes are available: 1 Insufficient memory, 2 node(s) had untolerated taint` | Mixed causes; read full event |

## Verification

```bash
#!/bin/bash
set -u
POD="${1:-}"
NS="${2:-default}"
echo "== phase =="; kubectl get pod "$POD" -n "$NS" -o jsonpath='{.status.phase}{"\n"}'
echo "== restarts =="; kubectl get pod "$POD" -n "$NS" -o jsonpath='{range .status.containerStatuses[*]}{.name}:{.restartCount} {"\n"}{end}'
echo "== last state =="; kubectl get pod "$POD" -n "$NS" -o jsonpath='{range .status.containerStatuses[*]}{.name}:{.lastState}{"\n"}{end}'
echo OK
```

## Safety

- `kubectl delete pod` on a Deployment-managed pod → ReplicaSet recreates it; doesn't fix root cause.
- Don't `imagePullSecrets: []` to clear; remove the field or set valid secret.

---

## Verified solutions from web docs (Google GKE, Bitnami)

### CrashLoopBackOff (verified causes)
- **OOMKilled / resource exhaustion** — `kubectl describe pod` shows `Reason: OOMKilled`. Fix: raise `resources.limits.memory`, add node RAM, or tune `vm.swappiness`.
- **Liveness probe failure** — default `failureThreshold: 3`; probe timeout kills container. Fix: check `httpGet` path/port, `exec` command exists and returns 0, raise `initialDelaySeconds`/`timeoutSeconds`/`failureThreshold`, fix probe resource consumption.
- **Misconfigured app / non-zero exit code** — inspect `kubectl logs <pod> --previous`. Exit code `0` means entrypoint isn't a persistent process (e.g. `["/bin/bash"]` exits immediately — use `sleep infinity` or a real server). Non-zero = config/env/dependency/auth failure.
- **Uncontrolled image updates (`:latest`)** — use immutable tags/digests (`sha256:...`) in production.
- **External service unavailable / auth failure** — `401 Unauthorized` / `403 Forbidden`; check service account IAM roles and credentials.
- **Timeouts** — app waits on unreachable external service; test from pod with `curl`/`nc`.

### ImagePullBackOff / ErrImagePull (verified causes)
- Image name/tag typo or image deleted → `docker pull ` manually on the node to confirm.
- `imagePullSecrets` missing/invalid → create/update `kubernetes.io/dockerconfigjson` secret, reference in ServiceAccount `imagePullSecrets`.
- Registry DNS lookup failure / `i/o timeout` / `Too Many Requests` (Docker Hub rate limit) → fix DNS, use a mirror/ACR/GA, or push to a private registry.
- `registryPullQPS`/`registryBurst` rate-limited on kubelet → tune node pool kubelet config.
- `no space left on device` on node → resize disk, prune images, set `imageGCHighThresholdPercent`.

### Exit code quick reference
| Exit code | Meaning | Fix |
|-----------|---------|-----|
| `0` | Clean exit — entrypoint isn't persistent | Give container a long-running process (`sleep infinity`, web server) |
| `1` | Generic application error | Read `docker logs`/`kubectl logs --previous` |
| `126` | Command not executable | Check image entrypoint permissions/arch |
| `127` | Command not found | Fix image path/typo |
| `137` | Killed by SIGKILL (OOM) | Raise memory limit, add RAM, fix app leak |

<ponytail: Scope ceiling — pod lifecycle only; add sidecars, init containers, and ephemeral containers when those patterns are used.</ponytail>
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

---
<ponytail: Scope ceiling — pod lifecycle only; add sidecars, init containers, and ephemeral containers when those patterns are used.</ponytail>
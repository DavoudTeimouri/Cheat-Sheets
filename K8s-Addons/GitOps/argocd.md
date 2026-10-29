# ArgoCD Troubleshooting

**Category:** Cloud-Native

## Symptom → Cause → Fix

| Exact symptom | Likely cause | Fix |
|---------------|--------------|-----|
| `OutOfSync` | Drift in manifests, image tag changed, `ignoreDifferences` missing | `argocd app sync <app>`, add `ignoreDifferences`, fix source/target |
| `Degraded` | Component crash, missing CRDs, webhook blocked creation | `kubectl get app <app> -o yaml`, check component health, CRDs installed |
| `Unknown` | Repo credentials wrong, SSH host key, TLS cert self-signed, app-controller can't reach repo server | `argocd repo add` with correct creds, trust SSH host key, set `insecure` for self-signed |
| App stuck `Progressing` | Resource never becomes healthy, reconciliation blocked | Check resource events, health probe, reduce `reconciliationTimeout` |

## Diagnosis

```bash
kubectl get app -A
kubectl logs -n argocd deployment/argocd-application-controller --tail=100
argocd app sync <app>
argocd app history <app>
argocd app diff <app>
kubectl get secret -n argocd | grep repo
```

## Repository deep dive

```bash
argocd repo add https://github.com/org/repo.git \
  --username <user> --password <token> \
  --insecure-skip-server-verification
```
- **SSH host key** → add via `argocd repo add --ssh-private-key-path ...` or trust known_hosts
- **TLS cert** → self-signed cert needs `--insecure-skip-server-verification` or import CA
- **Token vs password** → GitHub fine-grained personal access token with `repo` scope

## Application health

- **Health probe** → ArgoCD uses resource-specific health checks; custom resources need `health.lua`
- **Sync waves** → `annotations: argocd.argoproj.io/sync-wave: "0"` controls order
- **Auto-sync** → enable with `argocd app set <app> --auto-sync` after verifying manual sync works

## Verification

```bash
#!/bin/bash
set -u
NS="${1:-argocd}"
APP="${2:-}"
echo "== apps =="; kubectl get app -A 2>/dev/null | head -10 || true
echo "== controller =="; kubectl get deploy -n "$NS" -l app.kubernetes.io/name=argocd-application-controller 2>/dev/null || true
[ -n "$APP" ] && echo "== app diff ==" && argocd app diff "$APP" 2>&1 | head -30 || true
echo OK
```

## Safety

- `argocd app sync --prune` deletes resources not in source; verify diff first.
- Auto-sync can cause drift loops if source and live state conflict; test manual sync first.

---
<ponytail: Scope ceiling — ArgoCD applications, sync, repos, credentials; add App of Apps, Argo Rollouts, and Argo Workflows when those are used.</ponytail>
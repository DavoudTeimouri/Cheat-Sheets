# Kubernetes kubectl / kubeconfig Troubleshooting

**Category:** Cloud-Native

## Symptom → Cause → Fix

| Exact symptom | Likely cause | Fix |
|---------------|--------------|-----|
| `The connection to the server localhost:8080 was refused` | No kubeconfig, wrong server URL, or pointing to wrong cluster | `kubectl config view`, set correct server with `kubectl config set-cluster` |
| `Unable to connect to the server: dialing...: connection refused` | API server not running, wrong address/port, firewall blocking | Check API server endpoint, network, firewall (6443) |
| `You must be logged in to the server (Unauthorized)` | No valid token/cert in kubeconfig, expired token | Create token, `kubectl config set-credentials`, re-login |
| `error: the server doesn't have a resource type "pods"` | Wrong cluster, wrong API version, RBAC permissions missing | Verify context, check `kubectl api-resources`, check RBAC |
| `context "..." not found` | kubeconfig context missing or misspelled | `kubectl config get-contexts`, `kubectl config use-context` |
| `Unable to connect to the server: x509: certificate signed by unknown authority` | CA cert mismatch, self-signed cert not trusted | `--insecure-skip-tls-verify` (temporary), or add correct CA to kubeconfig |
| `Unable to connect to the server: net/http: TLS handshake timeout` | API server unreachable, network/firewall blocking | Test `curl -vk https://<api-server>:6443/version`, check firewall |
| `command not found: kubectl` | kubectl not installed or not in PATH | Install kubectl, add to PATH |

## Diagnosis

```bash
# Current kubeconfig context
kubectl config current-context
kubectl config view
kubectl config get-contexts

# API server connectivity
kubectl cluster-info
kubectl cluster-info dump

# Test API server directly
curl -vk https://<api-server-ip>:6443/version

# Check kubeconfig file location
echo $KUBECONFIG
ls -la ~/.kube/config
```

## kubeconfig file structure

The kubeconfig file (`~/.kube/config` by default) has three sections:

```yaml
apiVersion: v1
kind: Config
clusters:
- name: my-cluster
  cluster:
    server: https://<api-server-ip>:6443
    certificate-authority-data: <base64-ca-cert>
    insecure-skip-tls-verify: false   # set true only for testing
users:
- name: admin
  user:
    token: <token>
    # or client-certificate-data + client-key-data
    # or username + password
contexts:
- name: my-context
  context:
    cluster: my-cluster
    user: admin
    namespace: default
current-context: my-context
```

## Common fixes

### Add / switch cluster
```bash
kubectl config set-cluster <name> --server=https://<api-server-ip>:6443 --certificate-authority=/path/to/ca.crt
kubectl config set-credentials <user> --token=<token>
kubectl config set-context <context> --cluster=<cluster> --user=<user> --namespace=<ns>
kubectl config use-context <context>
```

### Create token for a service account
```bash
kubectl create serviceaccount <sa-name> -n <ns>
kubectl create token <sa-name> -n <ns>
```

### Fix certificate errors (temporary only)
```bash
kubectl config set-cluster <name> --insecure-skip-tls-verify=true
```
> Only for testing. For production, configure the correct CA cert.

### View effective config
```bash
kubectl config view --minify
kubectl config view --minify --flatten
```

## Verification

```bash
#!/bin/bash
set -u
echo "== kubeconfig =="; kubectl config view --minify 2>/dev/null || true
echo "== current context =="; kubectl config current-context 2>/dev/null || true
echo "== cluster info =="; kubectl cluster-info 2>&1 | head -5 || true
echo "== api version =="; kubectl api-versions 2>&1 | head -3 || true
echo "== nodes =="; kubectl get nodes 2>&1 | head -5 || true
echo OK
```

## Safety

- Never commit `~/.kube/config` containing real tokens/certs to version control.
- `insecure-skip-tls-verify: true` disables TLS verification; use only for testing, not production.
- Token/service account tokens grant cluster access; treat like passwords.

---
<ponytail: Scope ceiling — kubectl/kubeconfig client-side troubleshooting only; add kubeconfig context switching across multiple clusters, exec-based auth (OIDC), and client-go programmatic access when those are used.</ponytail>
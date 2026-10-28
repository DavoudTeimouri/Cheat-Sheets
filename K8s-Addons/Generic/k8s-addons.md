# Kubernetes Add-ons Troubleshooting

## 1. Ingress-NGINX

| Symptom | Check | Fix |
|---------|-------|-----|
| 502 Bad Gateway | `kubectl logs -n ingress-nginx deployment/ingress-nginx-controller` | Wrong targetPort, backend not Ready, health check failing |
| 503 Service Unavailable | `kubectl get endpoints <backend-svc>` | Selector/pod label mismatch, pod not Ready |
| 404 on all paths | Ingress class set? (`kubernetes.io/ingress.class: nginx`) | Add `ingressClassName: nginx` or class annotation |
| TLS handshake fails | `kubectl get secret <tls-secret>` | Secret missing cert/key keys (`tls.crt`, `tls.key`), cert not covering host |

Controller stuck: check DaemonSet/Deployment rollout, node port conflicts (`hostNetwork`), admission webhook blocking (`ValidatingWebhookConfiguration`).

## 2. cert-manager

```bash
kubectl get certificate,issuer,clusterissuer -A
kubectl describe certificate <cert> -n <ns>
kubectl logs -n cert-manager deployment/cert-manager
kubectl logs -n cert-manager deployment/cert-manager-cainjector
kubectl logs -n cert-manager deployment/cert-manager-webhook
```
- `certificate` stuck `Issuing`: CA secret missing, issuer not Ready, DNS-01 credentials invalid, webhook failing
- `Order` failed: DNS challenge — verify TXT record via `dig _acme-challenge.<host> TXT`, firewall UDP/TCP 53, rate limits (Let's Encrypt)
- `cert-manager` not issuing after restore: re-run `cainjector` or restart `cert-manager` to repopulate secrets

## 3. metrics-server

```bash
kubectl top nodes   # fails if metrics-server broken
kubectl get apiservices v1beta1.metrics.k8s.io
kubectl logs -n kube-system deployment/metrics-server
kubectl get -n kube-system deployment/metrics-server -o yaml
```
Common: `certificate signed by unknown authority` — Kubelet serving cert mismatch (`--kubelet-preferred-address-types`, `--kubelet-use-node-status-port`, TLS trust). Fix CA bundle in `APIService` or disable TLS verification for testing only.

## 4. CoreDNS

```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl logs -n kube-system deployment/coredns
kubectl exec -it <pod> -- nslookup kubernetes.default.svc.cluster.local
```
- `looop` / crash: `Corefile` syntax error, upstream unreachable, `forward` loop
- `pod has unbound ImmediateVolumes` (ephemeral storage): increase storage or delete PVCs
- DNS not resolving services: `kube-proxy` broken, NetworkPolicy blocking UDP/TCP 53, `resolv.conf` in pod wrong

## 5. External-DNS

```bash
kubectl logs -n <ns> deployment/external-dns
kubectl get ingress -A -o custom-columns=NAME:.metadata.name,HOSTS:.spec.rules[*].host
```
- No records created: missing `kubectl.kubernetes.io/ingress.class` filter, missing `externaldns.k8s.io/alias` annotation, RBAC `ClusterRole` lacks `ingresses`/`services` list/watch
- Records not deleted: `policy: sync` vs `upsert-only`, finalizers stuck on ingress
- Provider errors: AWS Route53 IAM permissions, GCP DNS API disabled, Azure DNS zone permission

## 6. Prometheus / Grafana (kube-prometheus-stack)

```bash
kubectl get pods -n monitoring
kubectl get servicemonitor,prometheusrules -A
kubectl logs -n monitoring prometheus-kube-prometheus-stack-prometheus-0
```
- `Prometheus` not scraping: `ServiceMonitor` selector mismatch, `endpoints` missing, namespace label `prometheus: scrape` required by some setups
- `Grafana` datasource 500: Prometheus URL wrong, RBAC, `skipTLSVerify` for self-signed certs
- Alertmanager not firing: `route` config, `inhibit_rules`, receiver keys missing

## 7. Fluentbit / Loki / Elasticsearch (logging)

```bash
kubectl logs -n logging daemonset/fluent-bit
kubectl get daemonset -n logging
```
- Logs not reaching backend: backend endpoint unreachable, wrong `Host`, port, TLS, `bufsize`/`mem_buf_limit` overflow
- Missing container logs: `tail` path wrong (`/var/log/containers/*.log`), permission on `/var/log` (root needed — run as privileged or hostPath with correct perms)

## 8. ArgoCD

```bash
kubectl get app -A
kubectl logs -n argocd deployment/argocd-application-controller
argocd app sync <app>
```
- `OutOfSync`: drift in manifests, image tag changed, `ignoreDifferences` missing
- `Degraded`: component crash, missing CRDs, webhook blocked creation
- `Unknown`: repo credentials wrong (`argocd repo add`), SSH host key, TLS cert self-signed (insecure flag), app-controller can't reach repo server

## 9. CSI drivers (EBS, GCP PD, Azure Disk, vSphere CSI, OpenEBS, Longhorn)

```bash
kubectl get csidrivers
kubectl get pods -n kube-system -l app=csi-...
kubectl describe pv <pv>   # CSI: volumeHandle empty?
```
- `AttachFailed` / `MountFailed`: node lacks driver, multipathd not running, SELinux blocking, firewall blocking storage ports (443, 9001 for vSphere CSI), insufficient IAM (cloud CSI)
- `FailedAttachVolume` after node drain: `stale attachment` — detach manually via cloud console or `csi rescan`, cordon/uncordon node

## 10. MetalLB (bare-metal LoadBalancer)

```bash
kubectl get ipaddresspool,lb2poolid -A
kubectl logs -n metallb-system controller
kubectl get svc -o wide   # EXTERNAL-IP stuck <pending>
```
- EXTERNAL-IP stuck: `IPAddressPool` not covering service range, `L2Advertisement`/`BGPAdvertisement` missing, ARP/NDP not reaching clients, BGP peering down (`kubectl get bgppeers`), node interface lacks IP in pool range

## Quick self-check

```bash
#!/bin/bash
set -u
echo "== addon pods not running =="; kubectl get pods -A | grep -v Running | grep -v Completed || true
echo "== ingress-nginx =="; kubectl get pods -n ingress-nginx 2>/dev/null || true
echo "== cert-manager issuers =="; kubectl get issuer,clusterissuer -A 2>/dev/null || true
echo "== metrics API =="; kubectl get --raw /apis/metrics.k8s.io/v1beta1/nodes 2>&1 | head -c 200; echo
echo OK
```

---
<ponytail: Scope ceiling — add-ons above only; add service mesh, backup (Velero), policy (Kyverno/OPA), and gitops beyond ArgoCD when installed.</ponytail>
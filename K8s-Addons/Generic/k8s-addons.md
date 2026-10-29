# K8s add-ons Troubleshooting

**Category:** Cloud-Native

## Subgroups

| Subgroup | Sheet | Covers |
|----------|-------|--------|
| Ingress | [Ingress/ingress-nginx.md](Ingress/ingress-nginx.md) | Ingress-NGINX controller, 502/503/404, TLS |
| Certificate | [CertManager/cert-manager.md](CertManager/cert-manager.md) | Issuers, certificates, DNS-01/HTTP-01 challenges |
| Metrics | [Metrics/metrics-server.md](Metrics/metrics-server.md) | metrics-server, HPA data, APIService |
| DNS | [CoreDNS/coredns.md](CoreDNS/coredns.md) | Cluster DNS, CoreDNS crashes, upstream |
| External DNS | [ExternalDNS/external-dns.md](ExternalDNS/external-dns.md) | Route53/GCP/Azure DNS records from ingress |
| Monitoring | [Monitoring/prometheus-grafana.md](Monitoring/prometheus-grafana.md) | Prometheus, Grafana, Alertmanager, ServiceMonitor |
| Logging | [Logging/fluentbit.md](Logging/fluentbit.md) | FluentBit, Loki, log collection |
| GitOps | [GitOps/argocd.md](GitOps/argocd.md) | ArgoCD apps, sync, repos, credentials |
| Identity | [Identity/keycloak.md](Identity/keycloak.md) | Keycloak realm, clients, LDAP/SAML |
| LoadBalancer | [LoadBalancer/metallb.md](LoadBalancer/metallb.md) | MetalLB L2/BGP, IPAddressPool, EXTERNAL-IP |
| CSI | [CSI/csi.md](CSI/csi.md) | Ceph CSI, cloud CSI, attach/mount failures |

## Quick self-check

```bash
#!/bin/bash
set -u
echo "== addon pods not running =="; kubectl get pods -A | grep -vE 'Running|Completed' || true
echo "== cert-manager issuers =="; kubectl get issuer,clusterissuer -A 2>/dev/null || true
echo "== metallb pools =="; kubectl get ipaddresspool -A 2>/dev/null || true
echo "== argocd apps =="; kubectl get app -A 2>/dev/null || true
echo "== metrics API =="; kubectl get --raw /apis/metrics.k8s.io/v1beta1/nodes 2>&1 | head -c 200; echo
echo OK
```

---
<ponytail: Scope ceiling — add-ons above only; add Velero, Kyverno/OPA, service mesh (Istio/Linkerd), and Harbor when installed.</ponytail>
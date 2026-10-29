# External-DNS Troubleshooting

**Category:** Cloud-Native

## Symptom → Cause → Fix

| Exact symptom | Likely cause | Fix |
|---------------|--------------|-----|
| No DNS records created | Missing `kubectl.kubernetes.io/ingress.class` filter, missing `externaldns.k8s.io/alias` annotation, RBAC lacks `ingresses`/`services` list/watch | Add filter/annotation, fix `ClusterRole` |
| Records not deleted | `policy: sync` vs `upsert-only`, finalizers stuck on ingress | Set `policy: sync`, remove finalizers, re-run |
| Provider errors | AWS Route53 IAM permissions, GCP DNS API disabled, Azure DNS zone permission | Fix IAM policy, enable API, grant zone permission |
| Records duplicate | Multiple External-DNS instances, conflicting `registry` | Use single instance, `txt-owner-id`, `registry=txt` |

## Diagnosis

```bash
kubectl logs -n <ns> deployment/external-dns --tail=100
kubectl get ingress -A -o custom-columns=NAME:.metadata.name,HOSTS:.spec.rules[*].host
kubectl get clusterexternaldns,externaldns -A 2>/dev/null || true
kubectl get clusterrole -o name | grep external-dns || true
```

## Provider deep dive

- **AWS Route53** → IAM: `route53:ChangeResourceRecordSets`, `route53:ListHostedZonesByName`; hosted zone must exist
- **Google Cloud DNS** → DNS API enabled, service account has `dns.admin` or `dns.editor`
- **Azure DNS** → DNS Zone Contributor role on the zone resource group
- **Infoblox / Cloudflare / others** → provider-specific credentials and API endpoints

## RBAC deep dive

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: external-dns
rules:
- apiGroups: [""]
  resources: ["services","endpoints","pods","nodes"]
  verbs: ["get","watch","list"]
- apiGroups: ["networking.k8s.io"]
  resources: ["ingresses"]
  verbs: ["get","watch","list"]
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["get","watch","list"]
```

## Verification

```bash
#!/bin/bash
set -u
NS="${1:-external-dns}"
echo "== deployment =="; kubectl get deploy -n "$NS" 2>/dev/null || true
echo "== logs tail =="; kubectl logs -n "$NS" deployment/external-dns --tail=20 2>/dev/null || true
echo OK
```

## Safety

- `policy: sync` deletes records not managed by External-DNS; test with `dry-run` first.
- Changing `registry` or `txt-owner-id` can orphan existing records.

---
<ponytail: Scope ceiling — External-DNS controller + cloud DNS providers; add Infoblox, PowerDNS, and Crossplane DNS when those providers are used.</ponytail>
# cert-manager Troubleshooting

**Category:** Cloud-Native

## Symptom → Cause → Fix

| Exact symptom | Likely cause | Fix |
|---------------|--------------|-----|
| `Certificate` stuck `Issuing` | CA secret missing, Issuer not Ready, webhook failing | `kubectl describe certificate <cert>`, check Issuer `Ready` condition, `cainjector` logs |
| `Order` failed | DNS-01 challenge: credentials invalid, firewall blocks UDP/TCP 53, rate limits | `dig _acme-challenge.<host> TXT`, verify credentials, check Let's Encrypt rate limits |
| Certificate not issued after restore | Secrets not repopulated | Restart `cert-manager` and `cert-manager-cainjector` deployments |
| `Issuer` not Ready | ACME server unreachable, private key missing, email missing | Check Issuer `status.conditions`, `kubectl logs -n cert-manager deployment/cert-manager` |

## Diagnosis

```bash
kubectl get certificate,issuer,clusterissuer -A
kubectl describe certificate <cert> -n <ns>
kubectl describe issuer <issuer> -n <ns>
kubectl logs -n cert-manager deployment/cert-manager --tail=100
kubectl logs -n cert-manager deployment/cert-manager-cainjector --tail=100
kubectl logs -n cert-manager deployment/cert-manager-webhook --tail=100
kubectl get order -A
kubots get challenge -A   # typo guard: use kubectl
kubectl get challenge -A
```

## ACME challenge deep dive

- **HTTP-01** → port 80 reachable from public internet, `.well-known/acme-challenge/` served by ingress
- **DNS-01** → provider credentials valid (AWS Route53 IAM, GCP DNS API, Azure DNS zone), TXT record published, firewall UDP/TCP 53 open
- **Rate limits** → Let's Encrypt duplicates per week, certificates per registered domain per hour; use staging (`https://acme-staging-v02.api.letsencrypt.org/directory`) for testing

## Verification

```bash
#!/bin/bash
set -u
NS="${1:-cert-manager}"
echo "== deployments =="; kubectl get deploy -n "$NS" 2>/dev/null || true
echo "== issuers =="; kubectl get issuer,clusterissuer -A 2>/dev/null || true
echo "== certificates =="; kubectl get certificate -A 2>/dev/null || true
echo OK
```

## Safety

- `cert-manager` webhook failure blocks all certificate resources; fix webhook before applying new certificates.
- Staging ACME endpoint avoids rate limits during testing; switch to production for real certs.

---
<ponytail: Scope ceiling — cert-manager issuers/certificates + ACME challenges; add Vault issuer, Venafi, and external issuer when those are configured.</ponytail>
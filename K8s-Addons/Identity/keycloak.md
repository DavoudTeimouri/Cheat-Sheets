# Keycloak Troubleshooting

**Category:** Cloud-Native

## Symptom → Cause → Fix

| Exact symptom | Likely cause | Fix |
|---------------|--------------|-----|
| Login fails / 500 | Realm misconfigured, client redirect URI wrong, LDAP/SAML connection down | Check Keycloak admin console, realm settings, client `Valid Redirect URIs` |
| LDAP/SAML user sync fails | LDAP bind DN/password wrong, SAML metadata expired, LDAPS cert untrusted | Test LDAP connection in admin console, update SAML IDP metadata, import LDAPS CA |
| Client not found | `clientId` mismatch, client disabled, realm wrong | Verify `clientId`, enable client, check realm selection |
| Token issues | Clock skew, token expired, wrong issuer URL | Sync NTP, check `issuer` in token, update OIDC discovery URL |

## Diagnosis

```bash
kubectl get pods -n keycloak
kubectl logs -n keycloak statefulset/keycloak --tail=100
kubectl get secret -n keycloak | grep keycloak
kubectl get ingress -n keycloak
kubectl get svc -n keycloak keycloak
```

## Realm / client deep dive

- **Realm** → must match OIDC issuer URL path (`/auth/realms/<realm>`)
- **Client** → `clientId` must match OIDC `client_id`; `Valid Redirect URIs` must include callback URLs
- **Scope** → `openid`, `profile`, `email`, `groups` as needed; `offline_access` for refresh tokens
- **Mapper** → add Group Mapper, User Attribute Mapper to inject claims into tokens

## LDAP / SAML deep dive

- **LDAP** → `Connection URL`, `Bind DN`, `Bind Credential`, `Users DN`; test with `Test connection`
- **LDAPS** → import LDAP server CA into Keycloak truststore; verify hostname matches cert
- **SAML** → IDP Entity ID, SSO URL, Assertion Consumer Service (ACS) URL, public certificate; clocks must be in sync

## Verification

```bash
#!/bin/bash
set -u
NS="${1:-keycloak}"
echo "== pods =="; kubectl get pods -n "$NS" 2>/dev/null || true
echo "== svc =="; kubectl get svc -n "$NS" keycloak 2>/dev/null || true
echo "== ingress =="; kubectl get ingress -n "$NS" 2>/dev/null || true
echo "== health =="; kubectl get -n "$NS" pods -l app.kubernetes.io/name=keycloak -o jsonpath='{.items[*].status.containerStatuses[*].ready}{"\n"}' 2>/dev/null || true
echo OK
```

## Safety

- Changing realm SSL/require-ssl can lock out admin console; keep HTTP fallback or direct pod access.
- Deleting a realm removes all users/clients; export first via admin console.

---
<ponytail: Scope ceiling — Keycloak realm, clients, LDAP/SAML federation; add Keycloak Operator, multi-realm, and Identity Brokering when those are used.</ponytail>
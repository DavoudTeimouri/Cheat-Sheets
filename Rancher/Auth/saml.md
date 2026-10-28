# Rancher Auth Troubleshooting

## 1. Local admin / login

- Local admin password lost: `docker exec <rancher> reset-password` or re-create local auth
- API key expired: generate new token in user profile, update scripts/terraform

## 2. SAML / AD / LDAP login fails

- Group mapping wrong
- Service account lacks `users` read permission
- Cert expired for LDAPS

---
<ponytail: Scope ceiling — local auth + SAML/AD/LDAP login; add OIDC, GitHub OAuth, and freeIPA when those identity providers are used.</ponytail>
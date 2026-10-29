# Rancher Server Troubleshooting

## 1. Rancher server won't start / crash loop

```bash
docker ps -a | grep rancher
docker logs <rancher-container>
docker exec -it <rancher-container> tail -100 /var/log/rancher/rancher.log
```
- Port conflict (80/443): `ss -tlnp | grep -E ':80|:443'`, stop conflicting service or remap with `-p 8080:80 -p 8443:443`
- Volume not mounted: rancher data dir (`/var/lib/rancher`) permissions, SELinux context
- Memory: give container ≥ 4 GB, OOMKilled → raise limit or add host RAM

## 2. Cannot access Rancher UI (502 / timeout)

```bash
curl -vk https://<rancher-host>
docker inspect <rancher-container> | grep -A5 NetworkSettings
docker restart <rancher-container>
```
- 502: container still starting — wait for `rancher/rancher` healthcheck
- SSL cert self-signed: browser warning, add exception or use `--insecure` / import CA
- Hostname mismatch: `--acme-domain` or external DNS/LB pointing at wrong IP

## 3. Rancher logs

- `docker logs <container>`
- `/var/lib/rancher/management-state/`

---
## Rancher server deep dive

```bash
docker ps -a \| grep rancher
docker logs <rancher-container>
docker exec -it <rancher-container> tail -100 /var/log/rancher/rancher.log
```
- Port conflict (80/443) → `ss -tlnp \| grep -E ':80|:443'`; remap with `-p 8080:80 -p 8443:443`
- Volume not mounted → `/var/lib/rancher` permissions, SELinux context
- Memory → ≥ 4 GB; OOMKilled → raise limit or add host RAM
- 502 → container still starting; wait for `rancher/rancher` healthcheck
- SSL self-signed → browser exception or `--insecure` / import CA
- Hostname mismatch → `--acme-domain` or external DNS/LB wrong IP

## Log locations

- Rancher (docker): `docker logs <container>`, `/var/lib/rancher/management-state/`

## Verification

```bash
#!/bin/bash
set -u
echo "== rancher container =="; docker ps \| grep rancher/rancher || true
echo "== api =="; curl -sk -o /dev/null -w '%{http_code}\n' https://localhost/ping 2>/dev/null || true
echo OK
```

## Safety

- Restarting the Rancher container briefly drops the UI and API.

---

<ponytail: Scope ceiling — Rancher server container only; add Rancher HA, external DB, and Helm chart install when deployed at scale.</ponytail>
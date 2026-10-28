# Rancher Troubleshooting

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
- 502: container still starting, wait for `rancher/rancher` healthcheck
- SSL cert self-signed: browser warning, add exception or use `--insecure` / import CA
- Hostname mismatch: `--acme-domain` or external DNS/LB pointing at wrong IP

## 3. Cluster registration fails (cluster agent / rke2 / k3s)

```bash
kubectl get nodes -n cattle-system
kubectl logs -n cattle-system deployment/rancher
kubectl get cluster -A
```
- Agent can't reach Rancher URL: `System Defaults > Agent > Custom Cluster CA` / API URL wrong, firewall TCP 443 from cluster nodes to Rancher
- `cluster-agent` crash: wrong `clusterRegistrationToken`, expired token, time skew (NTP)
- `rke2`/`k3s` install fails: `curl -sfL https://get.rke2.io | sh -` — check `/var/log/rke2/*.log`, internet access to container registry

## 4. Provisioning: node stuck `Pending` / `Provisioning`

- No cloud credential: AWS IAM key, vCenter credential, Azure SP, GCP SA
- Machine pool mismatch: wrong AMI/template, SSH key not in cloud-init/user-data
- Security group blocks: SSH 22, Kubernetes API 6443, RKE2 9345/10250, k3s 6443/10250
- Node never joins: check `kubectl get nodes`, `journalctl -u rke2-server` / `-u rke2-agent`

## 5. Auth / login issues

- Local admin password lost: `docker exec <rancher> reset-password` (rancher v2.x: `sudo docker exec <container> resetting password` via `rancher` shell script) or re-create local auth
- SAML/AD/LDAP login fails: group mapping wrong, `service account` lacks `users` read, cert expired for LDAPS
- API key expired: generate new token in user profile, update scripts/terraform

## 6. Backup / restore

- etcd snapshot (RKE2): `/var/lib/rancher/rke2/server/db/snapshots/` — `rke2-server --cluster-reset --cluster-init` with `--etcd-snapshot`
- Rancher data: docker volume `rancher-data` — `docker run --volumes-from <rancher> -v $(pwd):/backup alpine tar cvf /backup/rancher-data.tar /var/lib/rancher`
- Restore mismatch: Rancher version must match backup version, cluster catalog restored separately

## Log locations

- Rancher (docker): `docker logs <container>`, `/var/lib/rancher/management-state/`
- RKE2: `/var/log/rke2/`, `/var/lib/rancher/rke2/server/logs/`
- K3s: `/var/log/rancher/k3s/`, `journalctl -u rke2-agent`

## Quick self-check

```bash
#!/bin/bash
set -u
echo "== rancher container =="; docker ps | grep rancher/rancher || true
echo "== api =="; curl -sk -o /dev/null -w '%{http_code}\n' https://localhost/ping 2>/dev/null || true
echo OK
```

---
<ponytail: Scope ceiling — Rancher server + RKE2/K3s cluster management; add Fleet/continuous delivery, Harvester, and Longhorn when those are in the stack.</ponytail>
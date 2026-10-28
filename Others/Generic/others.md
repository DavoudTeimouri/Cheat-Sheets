# Others Troubleshooting

## 1. Docker / containers

```bash
docker ps -a
docker inspect <container>
docker logs <container>
docker system df
docker system prune
```
- Container exits immediately: entrypoint wrong, command fails, check `docker logs` and `ENTRYPOINT` vs `CMD`
- Image pull fails: registry auth (`docker login`), network to registry, image name/typo
- No space left on device: `/var/lib/docker` full — prune images/containers/volumes, expand disk
- Container can't resolve DNS: `--dns`, Docker daemon DNS (`/etc/docker/daemon.json`), host `/etc/resolv.conf` uses 127.0.0.1 (Docker can't use loopback)
- Port already allocated: `ss -tlnp | grep <port>`, stop conflicting service or change `published` port

## 2. Nginx / Apache HTTPD

```bash
nginx -t                      # config test
apachectl configtest          # Apache
systemctl status nginx/httpd
tail -f /var/log/nginx/error.log
tail -f /var/log/httpd/error_log
ss -tlnp | grep -E ':80|:443'
```
- 502/503: backend (php-fpm, app server) down or socket permission wrong (`/run/php-fpm/www.sock`)
- 403: file permission, `chown www-data`, SELinux context (`restorecon -Rv /var/www`)
- Certbot SSL renewal fails: port 80 reachable, webroot path correct, `certbot renew --dry-run`

## 3. Databases: PostgreSQL / MySQL / MariaDB

```bash
# PostgreSQL
pg_isready
systemctl status postgresql
tail -f /var/log/postgresql/*.log
su - postgres -c "psql -c 'select pg_is_in_recovery();'"

# MySQL/MariaDB
mysqladmin ping
systemctl status mariadb
tail -f /var/log/mariadb/mariadb.log
```
- Won't start: disk full (`df -h /var/lib/pgsql` or `/var/lib/mysql`), corrupt InnoDB (`innodb_force_recovery`), config syntax error
- Slow queries: `EXPLAIN ANALYZE`, missing indexes, `work_mem`/`shared_buffers` too small
- Too many connections: `max_connections` hit, connection pooler (PgBouncer), close idle app connections

## 4. Redis

```bash
redis-cli ping
redis-cli info memory
redis-cli monitor
tail -f /var/log/redis/redis.log
```
- OOMKilled: `maxmemory-policy` allkeys-lru or volatile-lru, raise `maxmemory`, or add RAM
- Cannot bind port: another process on 6379 (`ss -tlnp | grep 6379`), protected-mode blocks remote access without bind/auth
- Persistence slow: `BGSAVE` forks — disk slow or RAM huge, enable AFS/RDB tuning

## 5. Elasticsearch / OpenSearch

```bash
curl -s localhost:9200/_cluster/health?pretty
curl -s localhost:9200/_cat/nodes?v
curl -s localhost:9200/_cat/shards?v
journalctl -u elasticsearch
```
- Red cluster: unassigned shards — disk full (`flood_stage`), node down, replica allocation blocked (`cluster.routing.allocation.disk.threshold_enabled`)
- Yellow: replica unassigned — single node cluster, add nodes or set `number_of_replicas: 0`
- Circuit breaker: heap too small, `indices.breaker.total.limit`, raise JVM heap (`jvm.options`, max 50% RAM, <= 31GB for compressed oops)

## 6. Terraform

```bash
terraform init
terraform validate
terraform plan
terraform state list
terraform state show <addr>
```
- Provider install fails: offline/airgap — use `terraform init -plugin-dir`, mirror registry
- State locked: `terraform force-unlock <LOCK-ID>` after confirming no other run
- Drift: `terraform plan -refresh-only`, import drifted resources or update config
- Timeout on create: provider API slow, increase `timeouts` in resource or retry

## 7. Ansible

```bash
ansible all -m ping
ansible-playbook --syntax-check site.yml
ansible-playbook -v site.yml
```
- Unreachable: SSH key, `ansible_user`, `ansible_port`, sudo password (`--become --ask-become-pass`), firewall
- Module missing on target: `python3`, `python3-apt`, `docker-py`, `openstacksdk`
- Idempotency broken: task uses `shell`/`command` without `creates`/`removes` — use dedicated modules

## 8. Cloud-init

```bash
cat /var/log/cloud-init.log
cat /var/log/cloud-init-output.log
cloud-init status --long
cloud-init clean --logs --reboot   # re-run on next boot
```
- Network not configured: `network-config` wrong version (v1 vs v2), NIC names differ (`ens*` vs `eth*`)
- User-data not applied: instance launched without user-data, metadata service unreachable (`curl http://169.254.169.254/latest/meta-data/` on AWS)
- Modules failed: `cloud-init analyze show`, fix YAML syntax (`cloud-init deconstruct` / `devel schema`)

## 9. VMware Tools / open-vm-tools

```bash
vmware-toolbox-cmd -v
systemctl status open-vm-tools
ls -l /dev/vmci /dev/vmmemctl
```
- No graceful shutdown/restart from vCenter: tools not running, wrong `vmx` config (`guest.enableShutdown = TRUE`)
- Time drift: disable host time sync if guest runs NTP/chrony, or enable both consistently
- Network adapters changed after upgrade: `vmxnet3` driver missing → reinstall tools

## Quick self-check

```bash
#!/bin/bash
set -u
echo "== docker =="; docker info >/dev/null 2>&1 && echo docker-ok || echo docker-n/a
echo "== nginx =="; nginx -t 2>&1 | tail -1 || true
echo "== redis =="; redis-cli ping 2>/dev/null || echo redis-n/a
echo "== elasticsearch =="; curl -s -o /dev/null -w '%{http_code}' localhost:9200 2>/dev/null || echo es-n/a
echo OK
```

---
<ponytail: Scope ceiling — common infrastructure services only; add SAP, Oracle DB, IBM MQ, SAP HANA, and mainframe-adjacent tooling when those platforms appear.</ponytail>
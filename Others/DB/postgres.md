# Others Databases Troubleshooting

## 1. PostgreSQL / MySQL / MariaDB won't start

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

## 2. Slow queries

- `EXPLAIN ANALYZE`, missing indexes, `work_mem`/`shared_buffers` too small

## 3. Too many connections

- `max_connections` hit — connection pooler (PgBouncer), close idle app connections

## 4. Redis

```bash
redis-cli ping
redis-cli info memory
redis-cli monitor
tail -f /var/log/redis/redis.log
```
- OOMKilled: `maxmemory-policy` allkeys-lru or volatile-lru, raise `maxmemory`, or add RAM
- Cannot bind port: another process on 6379 (`ss -tlnp | grep 6379`), protected-mode blocks remote access without bind/auth

## 5. Elasticsearch / OpenSearch

```bash
curl -s localhost:9200/_cluster/health?pretty
curl -s localhost:9200/_cat/nodes?v
curl -s localhost:9200/_cat/shards?v
journalctl -u elasticsearch
```
- Red cluster: unassigned shards — disk full (`flood_stage`), node down, replica allocation blocked (`cluster.routing.allocation.disk.threshold_enabled`)
- Yellow: replica unassigned — single node cluster, add nodes or set `number_of_replicas: 0`
- Circuit breaker: heap too small, `indices.breaker.total.limit`, raise JVM heap (`jvm.options`, max 50% RAM, <= 31 GB for compressed oops)

---
<ponytail: Scope ceiling — PostgreSQL/MySQL/Redis/Elasticsearch basics only; add Oracle, SAP HANA, and MongoDB when those databases run.</ponytail>
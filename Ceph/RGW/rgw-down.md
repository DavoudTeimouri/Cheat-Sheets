# Ceph RADOS Gateway Troubleshooting

## 1. RGW 403 / 400 errors

- Key/secret wrong, bucket policy, CORS misconfigured
- Time skew between client and cluster (NTP!) — synchronize clocks

## 2. RGW 503 / daemon down

- `radosgw` daemon down or frontend (civetweb/nginx) not listening
- Check `/var/log/ceph/ceph-radosgw.<host>.log`

## 3. Objects not replicating

```bash
ceph radosgw-admin bucket list
ceph radosgw-admin bucket stats --bucket=<bucket>
ceph radosgw-admin sync status
```
- Region/zone config mismatch between sites
- Check RGW metadata pool health (`ceph osd pool stats .rgw`)

## RGW deep dive

```bash
ceph osd lspools \| grep rgw
ceph rgw stats
radosgw-admin bucket list
radosgw-admin bucket stats --bucket=<bucket>
radosgw-admin sync status
```
- 403/400 → key/secret wrong, bucket policy, CORS, time skew between client and cluster (NTP!)
- 503 → `radosgw` daemon down or frontend (civetweb/nginx) not listening
- Objects not replicating → `ceph radosgw-admin sync status`, region/zone config mismatch

## RGW verification

```bash
#!/bin/bash
set -u
BUCKET="${1:-}"
echo "== rgw stats =="; ceph rgw stats 2>/dev/null \| head -5 || true
echo "== buckets =="; radosgw-admin bucket list 2>/dev/null \| head -5 || true
[ -n "$BUCKET" ] && echo "== bucket stats ==" && radosgw-admin bucket stats --bucket="$BUCKET" 2>/dev/null \| head -10 || true
echo OK
```

## Safety

- RGW time skew breaks S3 auth signatures; sync NTP on clients and cluster.
- Multi-site realm/zone changes can pause replication; verify with `radosgw-admin sync status`.

---

<ponytail: Scope ceiling — RGW auth + replication; add multi-site realm/zone failover and S3 bucket lifecycle when object replication is used.</ponytail>
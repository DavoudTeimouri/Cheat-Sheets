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

---
<ponytail: Scope ceiling — RGW auth + replication; add multi-site realm/zone failover and S3 bucket lifecycle when object replication is used.</ponytail>
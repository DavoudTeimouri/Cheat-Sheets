# CephFS / MDS Troubleshooting

## 1. MDS down / laggy

```bash
ceph fs status
ceph mds stat
ceph fs ls
```
- MDS down: `ceph fs set <fs> allow_standbys true`, add MDS daemons
- MDS laggy: too many files in one directory — add MDS instances or shard directories

## 2. CephFS kernel client mount stuck

- `ceph.ko` out of date vs monitor → use `ceph-fuse` as workaround
- Check `dmesg` for ceph client errors and `/var/log/ceph/ceph-mds.<host>.log`

---
<ponytail: Scope ceiling — MDS + CephFS mount; add CephFS mirroring and snapshot scheduling when used.</ponytail>
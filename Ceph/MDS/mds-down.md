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

## CephFS MDS deep dive

```bash
ceph fs status
ceph mds stat
ceph fs ls
ceph fs set <fs> allow_standbys true
```
- MDS down → add MDS daemons, `ceph fs set <fs> allow_standbys true`
- MDS laggy → too many files in one directory; add MDS instances or shard directories
- Kernel client mount stuck → `ceph.ko` out of date vs monitor; use `ceph-fuse` as workaround

## CephFS verification

```bash
#!/bin/bash
set -u
FS="${1:-cephfs}"
echo "== fs status =="; ceph fs status "$FS" 2>/dev/null \| head -20 || true
echo "== mds =="; ceph mds stat 2>/dev/null || true
echo OK
```

## Safety

- Adding/removing MDS triggers filesystem rebalancing; monitor `ceph -s` during changes.

---

<ponytail: Scope ceiling — MDS + CephFS mount; add CephFS mirroring and snapshot scheduling when used.</ponytail>
# Ceph Troubleshooting

**Category:** Storage
## 1. Cluster health: HEALTH_WARN / HEALTH_ERR

```bash
ceph health detail
ceph status
ceph -s
```
Common flags: `PG_NOTDEGRADED`, `PG_AVAILABILITY_RISK`, `OSD_DOWN`, `TOO_FEW_PGS`, `NEEDS_OSD_RESTART`, `MON_DOWN`, `ROGUE_MON`, `MDS_RED`.

## 2. Monitors down / no quorum

```bash
ceph mon stat
ceph quorum_status
ceph mon dump
```
- Mon down: check `ceph-mon` service, `/var/lib/ceph/mon/ceph-<id>/store.db`, `ceph.conf` mon addresses, firewall port 6789/3300
- No quorum: bring monitors back up one at a time; `ceph mon add <new> <ip>` only after quorum exists
- Rogue mon: `ceph mon remove <bad-mon-id>`

## 3. OSDs down / out

```bash
ceph osd stat
ceph osd tree
ceph osd dump | grep -i down
systemctl status ceph-osd@<id>
journalctl -u ceph-osd@<id>
```
- OSD down: disk full (`df -h /var/lib/ceph/osd/<fsid>-<id>`), disk failure (`smartctl -a /dev/sdX`), network partition
- OSD out: mark back in `ceph osd in <id>` after verifying disk health — triggers recovery/rebalancing
- Flapping OSD: check `osd_heartbeat_interval`, network saturation, disk I/O latency (`iostat -x 1`)

## 4. PGs stuck unclean / undersized / degraded

```bash
ceph pg dump pgs | awk '{print $2, $10, $14}' | sort | uniq -c
ceph pg <pgid> query
ceph pg <pgid> stat
```
- `unclean`: replicas diverged — recovery runs automatically; speed up by raising `osd_recovery_max_active`
- `undersized`: fewer replicas than `size` — wait for recovery or add OSDs
- `stale`: no OSD reported the PG recently — OSDs down or network cut
- `recovery_unfound`: objects without complete copies — mark unfound lost only after confirming data loss is acceptable

Backfill tuning:
```bash
ceph tell osd.* injectargs --osd-max-backfills 8
ceph osd pool set <pool> size 3
```

## 5. Cluster full / nearfull

```bash
ceph df
ceph osd df
df -h /var/lib/ceph/osd/*
```
- `nearfull` (85%): delete data, add OSDs/disks
- `full` (95%): writes blocked — free space immediately (delete snapshots, trim RBD, lower retention) or add capacity
- Skewed pools waste space — check `max_avail` vs `bytes_used` in `ceph df`

## 6. RBD (block) issues

```bash
rbd ls -p <pool>
rbd info <pool>/</tool_call>
rbd snap ls <pool>/</tool_call>
rbd map <pool>/</tool_call>
rbd unmap /dev/rbd/<pool>/</tool_call>
```
- Cannot map: kernel module `rbd` not loaded (`modprobe rbd`), libceph/client version mismatch, image locked (`rbd lock rm <pool>/</tool_call> <locker-id>`)
- Slow performance: check `rbd cache` settings, `rbd-mirror` lag, qemu version
- Snapshot fill: delete old snapshots, flatten clones (`rbd flatten <pool>/</tool_call>`)

## 7. CephFS

```bash
ceph fs status
ceph mds stat
ceph fs ls
```
- MDS down: `ceph fs set <fs> allow_standbys true`, add MDS daemons
- MDS laggy: too many files in one directory — add MDS instances
- Kernel client mount stuck: `ceph.ko` out of date vs monitor; use `ceph-fuse` as workaround

## 8. RADOS Gateway (RGW)

```bash
ceph osd lspools | grep rgw
ceph rgw stats
radosgw-admin bucket list
radosgw-admin bucket stats --bucket=<bucket>
```
- 403/400: key/secret wrong, bucket policy, CORS, time skew between client and cluster (NTP!)
- 503: `radosgw` daemon down, frontend not listening
- Objects not replicating: `ceph radosgw-admin sync status`, region/zone config mismatch

## 9. Crush map / rebalancing

```bash
ceph osd crush dump
ceph osd crush rule ls
ceph osd reweight <id> <weight>
```
- CRUSH weight changed too much → backfill storm — adjust `osd_recovery_max_active`, watch `ceph -s` recovery% between changes

## 10. Common service commands

```bash
systemctl status ceph-mon@<host>
systemctl status ceph-mgr@<host>
systemctl status ceph-osd@<id>
ceph mgr services
```

## Quick self-check

```bash
#!/bin/bash
set -u
echo "== health =="; ceph health detail 2>/dev/null || true
echo "== osd tree =="; ceph osd tree 2>/dev/null || true
echo OK
```

---
<ponytail: Scope ceiling — core RADOS pool/OSD/MON/MDS/RGW layers only; add Cephadm orchestrator, multi-site replication, and BlueStore tuning when adopted.</ponytail>
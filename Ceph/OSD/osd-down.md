# Ceph OSDs Troubleshooting

## 1. OSDs down / out

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

## 2. PGs stuck unclean / undersized / degraded

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

## 3. Cluster full / nearfull

```bash
ceph df
ceph osd df
df -h /var/lib/ceph/osd/*
```
- `nearfull` (85%): delete data, add OSDs/disks
- `full` (95%): writes blocked — free space immediately (delete snapshots, trim RBD, lower retention) or add capacity
- Skewed pools waste space — check `max_avail` vs `bytes_used` in `ceph df`

## 4. Crush map / rebalancing

```bash
ceph osd crush dump
ceph osd crush rule ls
ceph osd reweight <id> <weight>
```
- CRUSH weight changed too much → backfill storm — adjust `osd_recovery_max_active`, watch `ceph -s` recovery% between changes

---
<ponytail: Scope ceiling — OSD + PG + CRUSH layers; add BlueStore/rocksdb tuning and cephadm OSD orchestration when adopted.</ponytail>
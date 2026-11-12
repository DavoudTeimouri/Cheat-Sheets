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

## OSD deep dive

```bash
ceph osd stat
ceph osd tree
ceph osd dump \| grep -i down
systemctl status ceph-osd@<id>
journalctl -u ceph-osd@<id>
df -h /var/lib/ceph/osd/<fsid>-<id>
smartctl -a /dev/sdX
iostat -x 1
```
- OSD down → disk full, disk failure, network partition
- OSD out → mark back in `ceph osd in <id>` after verifying disk health (triggers recovery/rebalancing)
- Flapping OSD → check `osd_heartbeat_interval`, network saturation, disk I/O latency

## PG states deep dive

```bash
ceph pg dump pgs \| awk '{print $2, $10, $14}' \| sort \| uniq -c
ceph pg <pgid> query
ceph pg <pgid> stat
```
- `unclean` → replicas diverged; recovery automatic; speed up by raising `osd_recovery_max_active`
- `undersized` → fewer replicas than `size`; wait for recovery or add OSDs
- `stale` → no OSD reported PG recently; OSDs down or network cut
- `recovery_unfound` → objects without complete copies; mark unfound lost only after confirming data loss acceptable

## Backfill tuning

```bash
ceph tell osd.* injectargs --osd-max-backfills 8
ceph osd pool set <pool> size 3
ceph osd pool set <pool> min_size 2
```
- CRUSH weight changed too much → backfill storm; adjust `osd_recovery_max_active`, watch `ceph -s` recovery% between changes

## Cluster full / nearfull

```bash
ceph df
ceph osd df
df -h /var/lib/ceph/osd/*
```
- `nearfull` (85%) → delete data, add OSDs/disks
- `full` (95%) → writes blocked; free space immediately (delete snapshots, trim RBD, lower retention) or add capacity
- Skewed pools waste space → check `max_avail` vs `bytes_used` in `ceph df`

## Verification

```bash
#!/bin/bash
set -u
echo "== health =="; ceph health detail 2>/dev/null || true
echo "== osd tree =="; ceph osd tree 2>/dev/null || true
echo OK
```

## Safety

- Marking an OSD `in` triggers recovery; don't mark multiple failing disks in at once (backfill storm).
- `ceph osd pool set <pool> size 1` risks data loss on single failure; only for temporary shrink.

---

## Verified solutions from web docs (official Ceph docs)

### OSD down / out
- `ceph health detail` reports `HEALTH_WARN 1/3 in osds are down` with `osd.N is down since epoch X, last address <ip>`. Restart: `systemctl restart ceph-FSID@osd.N.service` (cephadm: `ceph orch daemon start osd.N`).
- If `ceph-osd` won't start: verify data/journal partitions mounted (`ceph-volume lvm list`), check for missing keyring (`ERROR: missing keyring`), corrupt superblock (`ERROR: unable to open OSD superblock`), `EIO` = disk failure → replace disk. `FAILED assert(0 == "hit suicide timeout")` → open support ticket.
- `dmesg` for filesystem/disk errors. On high-OSD-count nodes, check `kernel.pid_max` (default 32768; raise to `4194303` if hitting thread limit during recovery).
- `nf_conntrack` table full → mysterious intermittent connection failures; raise `nf_conntrack_max` and `nf_conntrack_buckets` (`buckets × 8 = max`).

### OSD flapping
- OSDs repeatedly marked down/up → private network failure or scrubbing/recovery taking too long. Freeze with `ceph osd set noup` / `ceph osd set nodown` (clears with `unset`), then fix network or wait for scrub/recovery to finish.

### PGs stuck
- Identify stuck PGs: `ceph pg dump_stuck [unclean|inactive|stale|undersized|degraded]`.
- `unclean` = replicas diverged (recovering). `inactive` = waiting for primary OSD with latest data. `stale` = primary OSD down, no recent stats. `degraded` = fewer replicas than desired.
- `PG_DAMAGED` / `OSD_SCRUB_ERRORS` at `HEALTH_ERR` = inconsistent replicas; needs repair.

### Cluster full / nearfull
- `nearfull` (85%) → delete data, add OSDs/disks. `full` (95%) → writes blocked; free space immediately (delete snapshots, trim RBD, lower retention) or add capacity.
- Skewed pools waste space — check `max_avail` vs `bytes_used` in `ceph df`.

### Network
- `netstat -a \| grep ceph`, `netstat -s` for stats. Private network failure while public works → OSDs mark each other down/up (flapping). Use `noup`/`nodown` to freeze states during diagnosis.

<ponytail: Scope ceiling — OSD + PG + CRUSH layers; add BlueStore/rocksdb tuning and cephadm OSD orchestration when adopted.</ponytail>
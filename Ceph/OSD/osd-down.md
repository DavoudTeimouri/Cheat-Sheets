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

## 5. Backfill / recovery troubleshooting

**Category:** Storage  
**Applies to:** Ceph (RADOS pools), any pool type (replicated or erasure-coded)

### Symptom → Cause → Fix

| Exact symptom | Likely cause | Fix |
|---------------|--------------|-----|
| `recovery` % stuck / not progressing | Fewer OSDs than `size`, OSD down/out, backfill throttled, network saturation | `ceph osd stat`, `ceph osd tree`, add OSDs or mark down OSDs `in`, raise `osd_recovery_max_active` |
| `backfill` % stuck / not progressing | Pool newly created / CRUSH weight changed, target OSDs full or flapping | `ceph osd df`, `ceph osd tree`, add capacity, `ceph osd reweight` carefully |
| `recovery_unfound` / objects unfound | Object has no complete copy across replicas | `ceph pg <pgid> query`, confirm data loss acceptable, `ceph pg <pgid> mark_unfound_lost delete` |
| `backfill_toofull` / pool nearfull during backfill | Destination pool nearfull (85%) / full (95%) | `ceph df`, `ceph osd df`, delete data or add OSDs, pause backfill temporarily |
| Backfill storm (many OSDs recovering at once) | CRUSH weight changed too much, many OSDs marked `in` simultaneously | `ceph osd reweight` gradually, `ceph tell osd.* injectargs --osd-recovery-max-chunks 1`, throttle backfills |
| Recovery / backfill slow | `osd_recovery_max_active` too low, `osd_max_backfills` too low, disk/network saturated | `ceph tell osd.* injectargs --osd-recovery-max-chunks 8`, `ceph tell osd.* injectargs --osd-max-backfills 8`, `iostat -x 1` |

### Diagnosis

```bash
# Cluster health and recovery state
ceph health detail
ceph -s
ceph recovery status

# PG states
ceph pg dump pgs | awk '{print $2, $10, $14}' | sort | uniq -c
ceph pg dump_stuck [unclean|inactive|stale|undersized|degraded]

# Per-PG detail
ceph pg <pgid> query
ceph pg <pgid> stat

# OSD state
ceph osd stat
ceph osd tree
ceph osd dump | grep -i down

# Pool capacity
ceph df
ceph osd df

# Recovery / backfill in-flight
ceph recovery status
```

### Recovery / backfill tuning

```bash
# Speed up recovery (more concurrent recovery operations per OSD)
ceph tell osd.* injectargs --osd-recovery-max-chunks 8
ceph tell osd.* injectargs --osd-recovery-max-chunks 1   # throttle: one chunk at a time

# Speed up backfill (more concurrent backfill operations)
ceph tell osd.* injectargs --osd-max-backfills 8
ceph tell osd.* injectargs --osd-max-backfills 1   # throttle

# Pool replica count
ceph osd pool set <pool> size 3
ceph osd pool set <pool> min_size 2

# CRUSH weight changes — do gradually, watch recovery% between changes
ceph osd reweight <id> <weight>
```

### Verification

```bash
#!/bin/bash
set -u
echo "== health =="; ceph health detail 2>/dev/null || true
echo "== recovery =="; ceph recovery status 2>/dev/null || true
echo "== pg states =="; ceph pg dump pgs | awk '{print $2, $10, $14}' | sort | uniq -c || true
echo "== osd tree =="; ceph osd tree 2>/dev/null || true
echo "== pool df =="; ceph osd df 2>/dev/null || true
echo OK
```

### Safety

- Marking an OSD `in` triggers recovery/rebalancing; don't mark multiple failing disks `in` at once (backfill storm).
- Raising `osd_recovery_max_active` / `osd_max_backfills` increases cluster load and can impact client I/O; raise incrementally and monitor `ceph -s`.
- `ceph osd pool set <pool> size 1` risks data loss on single failure; only for temporary shrink.
- `ceph pg <pgid> mark_unfound_lost delete` permanently deletes objects with no complete copy — confirm data loss is acceptable first.

---

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
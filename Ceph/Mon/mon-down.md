# Ceph Monitors Troubleshooting

## 1. Monitors down / no quorum

```bash
ceph mon stat
ceph quorum_status
ceph mon dump
```
- Mon down: check `ceph-mon` service, `/var/lib/ceph/mon/ceph-<id>/store.db`, `ceph.conf` mon addresses, firewall ports 6789/3300
- No quorum: fewer than majority of mons up — bring monitors back one at a time; `ceph mon add <new> <ip>` only after quorum exists
- Rogue mon: `ceph mon remove <bad-mon-id>`

## 2. Monitor store corruption

- `store.db` unreadable: delete and re-add the mon, or recover from another mon's data
- Check `/var/log/ceph/ceph-mon.<host>.log` for store errors

## 3. Monitor clock skew

- MONs must be time-synced (NTP/chrony) — skew causes quorum instability and false `MON_DOWN`
- Check `ceph -s` for `MON_DOWN` with recent timestamps

## 4. Adding / removing monitors

```bash
ceph mon add <new-mon> <ip>
ceph mon remove <bad-mon-id>
```
- Always verify quorum (`ceph quorum_status`) before removing any mon
- New mon needs `ceph.conf` mon entries and keyring

## MON deep dive

```bash
ceph mon stat
ceph quorum_status
ceph mon dump
chronyc tracking
```
- Mon down → check `ceph-mon` service, `/var/lib/ceph/mon/ceph-<id>/store.db`, `ceph.conf` mon addresses, firewall ports 6789/3300
- No quorum → fewer than majority of mons up; bring monitors back one at a time
- Rogue mon → `ceph mon remove <bad-mon-id>`
- Adding mon → `ceph mon add <new-mon> <ip>`, then verify quorum

## MON verification

```bash
#!/bin/bash
set -u
echo "== mon stat =="; ceph mon stat 2>/dev/null || true
echo "== quorum =="; ceph quorum_status 2>/dev/null || true
echo OK
```

## Safety

- Never remove more than one mon at a time while below quorum.
- `store.db` corruption → delete and re-add mon, or recover from another mon's data.

---

<ponytail: Scope ceiling — MON layer only; add Cephadm mon deployment and multi-DC mon stretched clusters when adopted.</ponytail>
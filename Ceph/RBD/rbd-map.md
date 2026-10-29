# Ceph RBD Troubleshooting

## 1. Cannot map RBD image

```bash
rbd ls -p <pool>
rbd info <pool>/</tool_call>
rbd map <pool>/</tool_call>
rbd unmap /dev/rbd/<pool>/</tool_call>
```
- Kernel module `rbd` not loaded: `modprobe rbd`
- libceph/client version mismatch vs cluster
- Image locked: `rbd lock rm <pool>/</tool_call> <locker-id>`

## 2. RBD snapshots / clones

```bash
rbd snap ls <pool>/</tool_call>
```
- Snapshot fill: delete old snapshots, flatten clones (`rbd flatten <pool>/</tool_call>`)
- Cannot delete snapshot with watchers: `rbd unmap` all clients first

## 3. Slow RBD performance

- Check `rbd cache` settings in `ceph.conf` / guest
- `rbd-mirror` lagging: `rbd mirror image status <pool>/</tool_call>`
- QEMU version too old for image features → disable `object-map`, `fast-diff`, `deep-flatten` on legacy clients

## RBD deep dive

```bash
rbd ls -p <pool>
rbd info <pool>/</tool_call>
rbd snap ls <pool>/</tool_call>
rbd map <pool>/</tool_call>
rbd unmap /dev/rbd/<pool>/</tool_call>
rbd lock ls <pool>/</tool_call>
```
- Cannot map → kernel module `rbd` not loaded (`modprobe rbd`), libceph/client version mismatch, image locked (`rbd lock rm <pool>/</tool_call> <locker-id>`)
- Slow performance → check `rbd cache` settings in `ceph.conf`/guest, `rbd-mirror` lag (`rbd mirror image status`), qemu version
- Snapshot fill → delete old snapshots, flatten clones (`rbd flatten <pool>/</tool_call>`)

## RBD image features & legacy clients

```bash
rbd feature disable <pool>/</tool_call> object-map fast-diff deep-flatten   # old kernel client
```
- Old kernel client can't map image with new features → disable features or upgrade client

## Verification

```bash
#!/bin/bash
set -u
POOL="${1:-rbd}"
IMG="${2:-}"
echo "== images =="; rbd ls -p "$POOL" 2>/dev/null || true
[ -n "$IMG" ] && echo "== info ==" && rbd info "$POOL/$IMG" 2>/dev/null || true
echo OK
```

## Safety

- `rbd flatten` breaks clone relationship and copies all data; ensure space.
- Deleting a snapshot with watchers fails; `rbd unmap` all clients first.

---

<ponytail: Scope ceiling — RBD map/unmap, snapshots, features; add rbd-mirror and Ceph block QoS when mirroring is used.</ponytail>
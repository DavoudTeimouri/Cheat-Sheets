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

---
<ponytail: Scope ceiling — RBD map/unmap, snapshots, features; add rbd-mirror and Ceph block QoS when mirroring is used.</ponytail>
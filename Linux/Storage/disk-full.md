# Linux Storage Troubleshooting

## 1. Disk full

```bash
df -h
du -ahx / | sort -rh | head -20
journalctl --vacuum-size=100M
find /var/log -type f -exec truncate -s 0 {} +
```
- `/var` or `/` full: rotate logs (`logrotate`), truncate large logs, clean package cache (`apt clean`, `dnf clean all`)
- Deleted file still holding space: process holds open handle → `lsof | grep deleted`, restart the process

## 2. Inodes exhausted

```bash
df -i
find / -xdev -type f | wc -l
find /var/spool /tmp /var/cache -type f | sort | uniq -c | sort -rh | head
```
- Too many small files: clean mail queues, session files, container logs, npm/node_modules caches

## 3. Filesystem read-only / I/O errors

```bash
dmesg | grep -iE 'i/o error|fail|panic'
fsck -y /dev/<device>
smartctl -a /dev/sdX
```
- Read-only remount: kernel detected filesystem errors → run fsck from rescue/live ISO
- SMART reallocated sectors increasing: disk failing, replace immediately

## 4. LVM issues

```bash
pvs
vgs
lvs
lvdisplay
pvdisplay
vgdisplay
```
- Physical volume missing: `pvscan --cache`, check disk/cable
- Volume group not activated: `vgchange -ay <vg>`
- Logical volume full: `lvextend -L +10G /dev/<vg>/<lv> && resize2fs /dev/<vg>/<lv>` (ext4) or `xfs_growfs /mount` (xfs)

## 5. Mount fails / stale NFS

```bash
mount | grep <mountpoint>
df -h <mountpoint>
umount -l <mountpoint>
showmount -e <nfs-server>
```
- Stale NFS handle: `umount -l` (lazy), then remount; check server export and network
- Busy mount: `fuser -mv <mountpoint>`, kill processes or `umount -l`

## Mount fails / stale NFS

```bash
mount \| grep <mountpoint>
df -h <mountpoint>
umount -l <mountpoint>
showmount -e <nfs-server>
```
- Stale NFS handle: `umount -l` (lazy), then remount; check server export and network
- Busy mount: `fuser -mv <mountpoint>`, kill processes or `umount -l`

## LVM deep dive

```bash
pvs          # physical volumes, size, free, VG
vgs          # volume groups
lvs          # logical volumes, size, origin, data%
lvdisplay    # full LV detail
pvdisplay    # full PV detail
vgdisplay    # full VG detail
```
- PV missing → `pvscan --cache`, check disk/cable/zoning
- VG not active → `vgchange -ay <vg>`
- LV full → `lvextend -L +10G /dev/<vg>/<lv> && resize2fs /dev/<vg>/<lv>` (ext4) or `xfs_growfs /mount` (xfs)
- Shrink only ext4 (unmount first): `lvreduce -L -10G /dev/<vg>/<lv> && resize2fs /dev/<vg>/<lv>`; XFS cannot shrink
- Move data off a failing PV: `pvmove /dev/sdX`

## Filesystem read-only / I/O errors

```bash
dmesg \| grep -iE 'i/o error|fail|panic'
fsck -y /dev/<device>
smartctl -a /dev/sdX
```
- Read-only remount → kernel detected filesystem errors; boot rescue ISO, `chroot`, `fsck -y /dev/<device>`
- SMART `Reallocated_Sector_Ct` increasing → disk failing; replace immediately
- XFS: `xfs_repair` on unmounted filesystem; `xfs_repair -n` dry-run first

## Inode exhaustion cleanup

```bash
df -i
find / -xdev -type f \| wc -l
find /var/spool /tmp /var/cache -type f -printf '%h\n' \| sort \| uniq -c \| sort -rh \| head
find /var/log -type f -mtime +30 -delete
```
- Too many small files → clean mail queues, session files, container logs, npm/node_modules caches
- Single directory with millions of files → `find <dir> -type f -delete` (rm may fail with arg list too long)

## XFS vs ext4 grow

| Task | ext4 | XFS |
|------|------|-----|
| Grow LV | `lvextend -L +10G ... && resize2fs /dev/<vg>/<lv>` | `lvextend -L +10G ... && xfs_growfs /mount` |
| Grow online | yes | yes |
| Shrink | yes (unmount) | no |

## Verification

```bash
#!/bin/bash
set -u
echo "== space =="; df -h /
echo "== inodes =="; df -i /
echo "== VG =="; vgs 2>/dev/null \| head -5 || true
echo "== LVM errors =="; dmesg \| grep -iE 'lvm|device-mapper|I/O error' \| tail -5 || true
echo OK
```

## Safety

- `fsck` on mounted filesystem → corruption risk; only on unmounted/rescue.
- `lvreduce` destroys data; backup first, verify LV not in use.
- Truncating logs of a running process frees space but the process keeps the fd; restart the process after truncation.

---

<ponytail: Scope ceiling — local and NFS storage only; add iSCSI, multipath, Ceph/RBD, and ZFS when those backends are in use.</ponytail>
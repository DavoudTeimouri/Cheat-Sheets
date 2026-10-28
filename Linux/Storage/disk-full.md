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

---
<ponytail: Scope ceiling — local and NFS storage only; add iSCSI, multipath, Ceph/RBD, and ZFS when those backends are in use.</ponytail>
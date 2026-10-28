# Linux Memory Troubleshooting

## 1. OOM killer / out of memory

```bash
free -h
ps aux --sort=-%mem | head -10
dmesg | grep -i 'killed process'
journalctl -k | grep -i oom
```
- `Out of memory: Kill process` in dmesg: identify victim, raise `vm.swappiness`, add swap, or kill the consumer
- Container OOMKilled: raise `resources.limits.memory` in the pod spec, profile the app

## 2. Swap configuration

```bash
swapon --show
free -h
cat /proc/sys/vm/swappiness
```
- No swap: `fallocate -l 4G /swapfile`, `chmod 600 /swapfile`, `mkswap /swapfile`, `swapon /swapfile`, add to `/etc/fstab`
- Swappiness too high (constant swapping): `sysctl -w vm.swappiness=10`

## 3. High memory usage / cache

```bash
free -h
slabtop -o | head
ps aux --sort=-%rss | head -10
```
- "Missing" RAM is usually page cache (normal, reclaimable) — not a problem
- Slab cache huge: kernel object leak — `slabtop` to identify, restart service or reboot

## 4. Transparent Huge Pages (THP) latency

```bash
cat /sys/kernel/mm/transparent_hugepage/enabled
cat /sys/kernel/mm/transparent_hugepage/defrag
```
- Database latency spikes (MongoDB, MySQL): set `madvise` or `never`, persist via tuned profile or grub cmdline

---
<ponytail: Scope ceiling — physical/virtual host memory only; add cgroups v2, systemd-oomd, and Kubernetes memory QoS when containers run on the host.</ponytail>
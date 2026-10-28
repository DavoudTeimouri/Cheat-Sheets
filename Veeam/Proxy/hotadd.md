# Veeam Proxy Troubleshooting

## 1. Proxy / transport mode failures

- HotAdd failed: proxy lacks SCSI controller access to datastore, VM has independent disks, VAAI off, EFI/paravirtual SCSI mismatch — fall back to Network Block Device (NBD) or NBDSSL
- NBDSSL slow: add more proxies, enable LAN-free where possible, check proxy network (10 Gb)
- Direct SAN / Direct NFS: storage must present LUNs/NFS to proxy, zoning correct, `vmhba` sees LUN

## 2. Backup copy / replication job fails

- WAN acceleration: cache on source/target full → clear cache, check `VssSvc` on target
- Replica VM missing: target datastore space, ESXi license limits, target VM powered on with snapshots
- Seed drive: ensure seed VM disks are in correct folder and datastore, checksum matches

---
<ponytail: Scope ceiling — proxy transport modes + replication only; add vSphere tags-based backup and storage integration when those features are used.</ponytail>
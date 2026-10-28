# RKE Install Troubleshooting

## 1. Cluster creation fails (`rke up`)

```bash
rke up --cluster.yml cluster.yml
rke config
```
- SSH connection failed: node unreachable (`ssh root@<node>`), wrong key path (`ssh_key_path`), port 22 blocked, root login disabled (`PermitRootLogin yes`)
- Docker missing/old: RKE needs Docker on every node — install docker, enable service (`systemctl enable --now docker`)
- `rke` binary not found: download matching release, `chmod +x`, add to `PATH`

## 2. cluster.yml wrong roles / versions

- Node has wrong role: `roles: [controlplane, etcd, worker]` mismatch — re-run `rke up` after editing `cluster.yml`
- Version mismatch: `system_images` registry unreachable (default `docker.io/rancher`) — use private mirror:
```yaml
system_images:
  etcd: registry.example.com/rancher/etcd:vX.X.X
  kubernetes: registry.example.com/rancher/hyperkube:vX.X.X
```

---
<ponytail: Scope ceiling — RKE1 install only; RKE2 is provisioned through Rancher (see Rancher sheet).</ponytail>
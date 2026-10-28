# Others Docker Troubleshooting

## 1. Container exits immediately

```bash
docker ps -a
docker inspect <container>
docker logs <container>
```
- Entrypoint wrong, command fails — check `docker logs` and `ENTRYPOINT` vs `CMD`

## 2. Image pull fails

- Registry auth: `docker login`
- Network to registry unreachable, image name/typo

## 3. No space left on device

- `/var/lib/docker` full — `docker system prune`, prune images/containers/volumes, expand disk

## 4. Container DNS fails

- `--dns`, Docker daemon DNS (`/etc/docker/daemon.json`), host `/etc/resolv.conf` uses 127.0.0.1 (Docker can't use loopback)

## 5. Port already allocated

```bash
ss -tlnp | grep <port>
```
- Stop conflicting service or change `published` port

---
<ponytail: Scope ceiling — Docker engine basics only; add Docker Compose, rootless Docker, and containerd debugging when those run.</ponytail>
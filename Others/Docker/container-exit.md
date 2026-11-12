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
## Docker deep dive

```bash
docker ps -a
docker inspect <container>
docker logs <container>
docker system df
docker system prune
```
- Container exits immediately → entrypoint wrong, command fails; check `docker logs` and `ENTRYPOINT` vs `CMD`
- Image pull fails → registry auth (`docker login`), network to registry, image name/typo
- No space left on device → `/var/lib/docker` full; prune images/containers/volumes, expand disk
- Container can't resolve DNS → `--dns`, Docker daemon DNS (`/etc/docker/daemon.json`), host `/etc/resolv.conf` uses 127.0.0.1 (Docker can't use loopback)
- Port already allocated → `ss -tlnp \| grep <port>`; stop conflicting service or change `published` port

## Verification

```bash
#!/bin/bash
set -u
echo "== docker =="; docker info >/dev/null 2>&1 && echo docker-ok || echo docker-n/a
echo "== containers =="; docker ps -aq 2>/dev/null \| wc -l
echo OK
```

## Safety

- `docker system prune` removes stopped containers, unused networks, dangling images; confirm before running.

---

## Verified solutions from web docs (Docker)

### Container exits immediately
- **Exit code `0`** — clean exit, not a crash. Most common cause: entrypoint isn't a persistent process (e.g. `["/bin/bash"]` with `-d` and no TTY exits immediately). Fix: give it a long-running process (`sleep infinity`, `nginx`, `python app.py`) or run interactively (`docker run -it image bash`).
- **Non-zero exit code** — app crash. Read `docker logs <container>`; fix missing env var, bad config, unreachable database, or wrong entrypoint.

### Port / networking
- **`port is already allocated` / `address already in use`** — host port bound by another container or host process. Fix: `ss -tlnp | grep <port>` / `docker ps`, stop conflicting container, or change mapping `-p 8081:80` (left=host, right=container).
- **Container name already in use** — `docker rm -f <name>` then rerun.
- **`exec format error`** — wrong architecture (ARM image on x86 host or vice versa). Rebuild/pull correct arch image.
- **Container can't reach database** — containers on different networks, wrong hostname (`localhost` instead of service name), DB not ready yet, wrong credentials. Fix: put both on a custom network (`docker network create`), use service name as hostname, add healthcheck + `depends_on: condition: service_healthy`.
- **DNS failure inside container** — containers on default bridge can't resolve each other by name. Fix: use a custom bridge network; Docker embedded DNS only works on custom networks. Also Docker inherits host `/etc/resolv.conf`; if it uses `127.0.0.1` (systemd-resolved/dnsmasq), containers can't use it — set `--dns` or `/etc/docker/daemon.json`.

### Permissions / memory / arch
- **`Permission denied` on mounted files** — container runs as different UID than host bind-mount owner. Fix: align UID (`--user $(id -u):$(id -g)`), or `chown` host dir.
- **`OOMKilled` / exit code 137** — container exceeded memory limit or host out of memory. Fix: `--memory` limit, add swap/RAM, or fix app leak. Confirm with `docker inspect -f '{{.State.OOMKilled}}' <name>`.
- **`network declared as external but could not be found`** — Compose references an external network that doesn't exist. Fix: `docker network create <name>` first.

### Debug flow
1. `docker ps -a` → is it running or Exited?
2. `docker logs <container>` → error message.
3. `docker inspect -f '{{.State.ExitCode}}' <name>` → exit code meaning.
4. `docker exec -it <container> sh` (if running) → inspect env/files.
5. `docker network inspect <net>` → confirm both containers attached.
6. Rebuild image if needed.

<ponytail: Scope ceiling — Docker engine basics only; add Docker Compose, rootless Docker, and containerd debugging when those run.</ponytail>
# Cheat-Sheets

Troubleshooting cheat sheets: **Linux, vSphere, Kubernetes, K8s add-ons, Ceph, Rancher, RKE, Windows, Veeam** and **Others** (Docker, Nginx, databases, Terraform, Ansible, cloud-init, …).

Use the search bar above to find a symptom or command across every sheet.

## How sheets are organized

Each topic lives at `<Topic>/Generic/<topic>.md` in this repo and follows one pattern:

| Section | Purpose |
|---------|---------|
| Symptom → Likely cause → Fix | What breaks, why, and the commands to fix it |
| Log locations | Where to look for evidence |
| Quick self-check | A command you can run to verify the fix |

## Contribute

Found something missing or wrong?

- Open a **[New troubleshooting entry](https://github.com/DavoudTeimouri/Cheat-Sheets/issues/new?template=troubleshooting.md)** issue — structured form, a maintainer turns it into a sheet.
- Or send a **PR** adding `<Topic>/Generic/<topic>.md`. See [CONTRIBUTING.md](https://github.com/DavoudTeimouri/Cheat-Sheets/blob/main/CONTRIBUTING.md).

The site rebuilds and redeploys automatically on every push to `main` (GitHub Pages).

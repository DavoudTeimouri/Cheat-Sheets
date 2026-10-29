# Roadmap & Suggested Additions

## Suggested new topics

| Category | Topic | Why add it |
|----------|-------|------------|
| Operating System | macOS | Common dev/laptop fleet; different from Linux |
| Operating System | FreeBSD / SUSE | Used in hosting and enterprise |
| Operating System | Solaris / AIX | Legacy enterprise still in production |
| Cloud-Native | OpenShift | Kubernetes distribution with its own failure modes |
| Cloud-Native | K3s / RKE2 | Lightweight Kubernetes, common at edge |
| Cloud-Native | Helm | Chart install/upgrade failures |
| Cloud-Native | ArgoCD / Fleet | GitOps drift and sync errors |
| Cloud-Native | Istio / Linkerd | Service mesh mTLS and sidecar issues |
| Cloud-Native | Harbor | Image registry and replication |
| Cloud-Native | Longhorn | Cloud-native block storage |
| Cloud-Native | cert-manager | Certificate issuance and DNS-01 challenges |
| Virtualization | Proxmox VE | Popular open-source hypervisor |
| Virtualization | KVM / QEMU | Underlying Linux virtualization |
| Virtualization | Hyper-V | Windows virtualization |
| Virtualization | Nutanix AHV | HCI appliance |
| Storage | NetApp ONTAP | Enterprise NAS/SAN |
| Storage | Pure Storage | All-flash array |
| Storage | vSAN | VMware HCI storage |
| Storage | ZFS | Filesystem and volume manager |
| Storage | iSCSI | Block over IP |
| Networking | Cisco IOS / NX-OS | Switch and router |
| Networking | pfSense / OPNsense | Firewall and router |
| Networking | F5 BIG-IP | Load balancer |
| Networking | HAProxy | Load balancer and proxy |
| Networking | BIND / PowerDNS | Authoritative DNS |
| Networking | WireGuard / IPsec | VPN tunnels |
| Databases | MS SQL Server | Enterprise relational DB |
| Databases | MongoDB | Document DB |
| Databases | Cassandra | Wide-column DB |
| Observability | Prometheus / Grafana | Metrics and alerting |
| Observability | Loki / ELK | Log aggregation |
| Observability | Zabbix | Monitoring |
| CI/CD | Jenkins | Build and deploy |
| CI/CD | GitLab CI | Build and deploy |
| CI/CD | GitHub Actions | Build and deploy |
| Security | TLS / PKI | Certificates and trust |
| Security | Kerberos | Authentication |
| Security | HashiCorp Vault | Secrets management |
| Security | Falco | Runtime security |
| Cloud | AWS | EC2, IAM, S3, VPC |
| Cloud | Azure | VM, AD, Storage |
| Cloud | GCP | Compute, IAM, Cloud Storage |
| Email | Exchange | Mail flow and databases |
| Email | Postfix | SMTP relay |
| Hardware | iDRAC / iLO / IPMI | Out-of-band management |
| Hardware | RAID controllers | Disk arrays |
| Hardware | SMART | Disk health |

## Suggested new subgroups for existing topics

- **Linux**: bonding, VLAN, bridge, WireGuard/IPsec, eBPF/tc, cgroups v2, kernel sysctl
- **Kubernetes**: service mesh (Istio/Linkerd), admission webhooks, multi-cluster, CSI snapshot controller
- **Ceph**: Cephadm orchestrator, BlueStore/rocksdb tuning, multi-site replication
- **vSphere**: NSX-T, vSAN, Lifecycle Manager, Tanzu/Kubernetes on vSphere
- **Windows**: RD Gateway, RD Web, Azure AD/Entra, Intune, WSUS
- **Veeam**: Backup for AWS/Azure/M365, Nutanix AHV, Hyper-V
- **Rancher**: Fleet, Harvester, Longhorn
- **RKE**: RKE2 (already covered via Rancher sheet note)
- **Others**: Packer, rootless Docker, containerd, Terraform Cloud

## How to add a new topic

1. Create `<Topic>/Generic/<topic>.md` (overview with `**Category:**` line and subgroup table)
2. Create `<Topic>/<Subgroup>/<subtopic>.md` detail sheets
3. Add symlinks in `docs/` pointing to the canonical files
4. Add a nav entry to `mkdocs.yml` under the right category
5. Open a PR against `main`; the MkDocs site deploys automatically via GitHub Pages

## Contribution intake

Use the **[New troubleshooting entry](https://github.com/DavoudTeimouri/Cheat-Sheets/issues/new?template=troubleshooting.md)** issue template for suggestions or fixes. See [CONTRIBUTING.md](https://github.com/DavoudTeimouri/Cheat-Sheets/blob/main/CONTRIBUTING.md).

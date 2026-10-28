# Others Terraform Troubleshooting

## 1. Provider / state issues

```bash
terraform init
terraform validate
terraform plan
terraform state list
terraform state show <addr>
```
- Provider install fails: offline/airgap — use `terraform init -plugin-dir`, mirror registry
- State locked: `terraform force-unlock <LOCK-ID>` after confirming no other run
- Drift: `terraform plan -refresh-only`, import drifted resources or update config
- Timeout on create: provider API slow — increase `timeouts` in resource or retry

---
<ponytail: Scope ceiling — Terraform provider/state only; add Terraform Cloud/Enterprise, providers beyond AWS/Azure/GCP when those are used.</ponytail>
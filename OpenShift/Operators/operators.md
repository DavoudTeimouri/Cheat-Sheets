# OpenShift Operators Troubleshooting

**Category:** Cloud-Native

## Symptom → Cause → Fix

| Exact symptom | Likely cause | Fix |
|---------------|--------------|-----|
| Operator install stuck | CatalogSource missing, package not available, approval required | `oc get catsrc`, `oc get subscription`, check `installPlanApproval: Manual` |
| Operator pod CrashLoopBackOff | Wrong CRD versions, RBAC missing, image pull fail | `oc get csv`, `oc describe csv`, `oc logs -n openshift-operators <operator>` |
| CRD not found | CRD not installed, operator not running | Install operator via OperatorHub, check `oc get crd` |
| Subscription stuck | `installPlanApproval: Manual` waiting, channel mismatch | `oc approve installplan <name>`, check subscription channel |

## Diagnosis

```bash
# Operators/subscriptions
oc get subscription -A
oc get installplan -A
oc get csv -A
oc get catsrc -A

# Operator logs
oc get pods -n openshift-operators
oc logs -n openshift-operators -c <operator-container> --tail=100

# CRDs
oc get crd | grep <operator-name>
oc describe crd <crd-name>
```

## Subscription deep dive

```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: <operator-name>
  namespace: openshift-operators
spec:
  channel: stable
  name: <operator-package>
  source: redhat-operators
  sourceNamespace: openshift-marketplace
  installPlanApproval: Manual   # or Automatic
```

- **Channel** → release track (stable, alpha, beta, candidate).
- **installPlanApproval: Manual** → requires `oc approve installplan <name>` before install.
- **source** → OperatorSource/CatalogSource (`redhat-operators`, `community-operators`).

## CSV (ClusterServiceVersion)

- CSV represents an installed operator version.
- `oc get csv -A` shows phase: `InstallSucceeded`, `InstallFailed`, `Pending`.
- Failed CSV → check `status.reason`, `status.message`, operator pod logs.

## Verification

```bash
#!/bin/bash
set -u
echo "== subscriptions =="; oc get subscription -A 2>/dev/null || true
echo "== installplans pending =="; oc get installplan -A 2>/dev/null | awk 'NR==1 || $3!="Installed"' || true
echo "== csvs =="; oc get csv -A 2>/dev/null | awk 'NR==1 || $3!="InstallSucceeded"' || true
echo "== catalog sources =="; oc get catsrc -A 2>/dev/null || true
echo OK
```

## Safety

- Deleting an Operator/CSV removes its managed CRDs and can orphan workloads; verify dependents first.
- Changing subscription channel can trigger major version upgrade; review release notes first.

---
<ponytail: Scope ceiling — Operator Lifecycle Manager + Subscriptions + CSVs only; add Operator SDK development, catalog source mirroring, and disconnected installs when those are used.</ponytail>
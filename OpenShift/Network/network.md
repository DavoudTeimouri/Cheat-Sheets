# OpenShift Network Troubleshooting

**Category:** Cloud-Native

## Symptom → Cause → Fix

| Exact symptom | Likely cause | Fix |
|---------------|--------------|-----|
| Service unreachable | Wrong service type, no endpoints, network policy | `oc get svc`, `oc get endpoints`, check NetworkPolicy |
| Route 502/503 | Router (ingress controller) down, backend not Ready | `oc get route`, `oc get ingresscontroller`, check router pods |
| Pod cannot resolve DNS | CoreDNS/dns-default down, wrong cluster domain | `oc get dns.operator`, check CoreDNS pods, `resolv.conf` in pod |
| Cannot expose service | Route missing, wrong port, insecure/edge passthrough mismatch | `oc expose svc/<name>`, check route spec, TLS cert |

## Diagnosis

```bash
# Services/Endpoints
oc get svc -n <ns>
oc get endpoints -n <ns>
oc describe svc <svc> -n <ns>

# Routes
oc get route -n <ns>
oc describe route <route> -n <ns>
oc get ingresscontroller -n openshift-ingress-operator

# DNS
oc get dns.operator/default -o yaml
oc get pods -n openshift-dns
oc debug node/<node> -- chroot /host resolvectl status

# Network policy
oc get networkpolicy -n <ns>
oc describe networkpolicy <np> -n <ns>
```

## SDN/OVN deep dive

- OpenShift uses **SDN** (older) or **OVN-Kubernetes** (default in 4.x+) for pod networking.
- **OVN-Kubernetes** → `ovnkube-node`, `ovnkube-master`, `ovsdb` pods in `openshift-ovn-kubernetes`.
- **Routes** → handled by Ingress Controller (`openshift-ingress` namespace), HAProxy-based router.
- **Services** → ClusterIP, NodePort, LoadBalancer; LoadBalancer needs cloud integration.

## Route types

- **edge** → TLS terminated at router.
- **passthrough** → TLS passed to backend pod.
- **re-encrypt** → TLS terminated at router, re-encrypted to backend.
- **insecure** → HTTP only.

## Verification

```bash
#!/bin/bash
set -u
NS="${1:-default}"
echo "== services =="; oc get svc -n "$NS" 2>/dev/null || true
echo "== routes =="; oc get route -n "$NS" 2>/dev/null || true
echo "== endpoints empty =="; oc get endpoints -n "$NS" 2>/dev/null | awk 'NR==1 || $2=="0"' || true
echo "== ingresscontroller =="; oc get ingresscontroller -n openshift-ingress-operator 2>/dev/null || true
echo OK
```

## Safety

- Deleting an IngressController drops all route traffic; scale down instead for maintenance.
- NetworkPolicies default-deny can isolate all pods in a namespace; test on one app first.

---
<ponytail: Scope ceiling — OpenShift SDN/OVN + Routes + Services only; add OpenShift SDN to OVN migration, IPv6, and egress network policy when those are used.</ponytail>
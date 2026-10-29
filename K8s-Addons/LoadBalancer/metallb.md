# MetalLB Troubleshooting

**Category:** Cloud-Native

## Symptom → Cause → Fix

| Exact symptom | Likely cause | Fix |
|---------------|--------------|-----|
| `EXTERNAL-IP` stuck `<pending>` | `IPAddressPool` not covering service range, `L2Advertisement`/`BGPAdvertisement` missing, ARP/NDP not reaching clients | Create pool + advertisement, check BGP peering, verify node interface IP in pool range |
| Service gets wrong IP | Multiple pools overlap, pool selection by annotation wrong | Set `metallb.universe.tf/allow-shared-ip`, use `loadBalancerIP` or pool annotation |
| BGP session down | Peer ASN wrong, IP unreachable, firewall blocks TCP 179 | Fix `BGPPeer` config, check BGP logs, open TCP 179 |
| IP not announced | Node interface lacks IP in pool range, `nodeSelector` mismatch | Verify node has IP from pool, check advertisement `nodeSelectors` |

## Diagnosis

```bash
kubectl get ipaddresspool,ipaddresspoolclaim -A
kubectl get l2advertisement,bgpadvertisement -A 2>/dev/null || true
kubectl get bgppeer -A 2>/dev/null || true
kubectl logs -n metallb-system controller --tail=100
kubectl logs -n metallb-system speaker --tail=100
kubectl get svc -o wide   # EXTERNAL-IP stuck <pending>
```

## L2 mode deep dive

- **L2Advertisement** → announces service IP via ARP/NDP on node interface
- **ARP/NDP not reaching clients** → client and node on same L2, no firewall blocking ARP, `rp_filter` not dropping
- **Node selection** → `nodeSelectors` in L2Advertisement controls which nodes announce

## BGP mode deep dive

- **BGPPeer** → `peerAddress`, `peerASN`, `myASN`, `holdTime`; router ID defaults to node IP
- **BGP multipath** → enables ECMP across multiple nodes
- **BFD** → fast failure detection; enable `bfdProfile` for sub-second failover

## Verification

```bash
#!/bin/bash
set -u
NS="${1:-metallb-system}"
echo "== pools =="; kubectl get ipaddresspool -A 2>/dev/null || true
echo "== advertisements =="; kubectl get l2advertisement,bgpadvertisement -A 2>/dev/null || true
echo "== peers =="; kubectl get bgppeer -A 2>/dev/null || true
echo "== services =="; kubectl get svc -A -o custom-columns=NAME:.metadata.name,IP:.status.loadBalancer.ingress[0].ip 2>/dev/null || true
echo OK
```

## Safety

- Changing `IPAddressPool` ranges can flap service IPs; drain services first.
- BGP misconfiguration can black-hole traffic; test with a single peer first.

---
<ponytail: Scope ceiling — MetalLB L2/BGP + IPAddressPool; add BGP communities, BFD, and MetalLB with FRR when those features are used.</ponytail>
# Kubernetes Control Plane Troubleshooting

## 1. etcd issues

```bash
kubectl get componentstatuses
etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint health
```
- etcd quorum lost: restore from snapshot (`etcdctl snapshot restore`)
- etcd disk full: compact etcd (`etcdctl compact`), expand disk

## 2. API server / certificates expired

```bash
kubectl get csr
kubectl certificate approve <csr-name>
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -dates
kubeadm certs renew all   # kubeadm clusters, then restart static pods
```

## 3. metrics-server / HPA not scaling

```bash
kubectl top nodes
kubectl get apiservices v1beta1.metrics.k8s.io
kubectl logs -n kube-system deployment/metrics-server
kubectl get hpa -n <ns>
kubectl describe hpa <hpa> -n <ns>
```
- No metrics: metrics-server not installed or APIAggregation broken (`kubectl get apiservices | grep False`)
- `certificate signed by unknown authority`: fix CA bundle in APIService or Kubelet TLS trust

## 4. Eviction / pod priority

```bash
kubectl describe node <node> | grep -A5 Allocatable
kubectl get priorityclass
kubectl describe pod <pod> -n <ns> | grep -i evict
```
- Preemption blocked: PriorityClass settings, PDBs blocking drain
- Disk/memory/PID pressure: evict low-priority pods first

## metrics-server / HPA not scaling deep dive

```bash
kubectl top nodes
kubectl get apiservices v1beta1.metrics.k8s.io
kubectl logs -n kube-system deployment/metrics-server
kubectl get hpa -n <ns>
kubectl describe hpa <hpa> -n <ns>
kubectl get --raw /apis/metrics.k8s.io/v1beta1/nodes
```
- No metrics → metrics-server not installed or APIAggregation broken (`kubectl get apiservices \| grep False`)
- `certificate signed by unknown authority` → fix CA bundle in APIService or Kubelet TLS trust (`--kubelet-use-node-status-port`, TLS CA)
- `targetValue`/`targetAverageValue` never reached → metric never collected or below threshold

## Eviction / pod priority deep dive

```bash
kubectl describe node <node> \| grep -A5 Allocatable
kubectl get priorityclass
kubectl describe pod <pod> -n <ns> \| grep -i evict
```
- Preemption blocked → PriorityClass settings, PDBs blocking drain
- Disk/memory/PID pressure → evict low-priority pods first

## Control-plane certs deep dive

```bash
kubectl get csr
kubectl certificate approve <csr-name>
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -dates
kubeadm certs renew all   # kubeadm clusters, then restart static pods
```
- Expired kubelet/controller certs → rotate with `kubeadm certs renew all`, restart kubelet/static pods
- `kubectl` fails `x509: certificate has expired` → regenerate `kube_config_cluster.yml` (`rke up --local` or `rke config` for RKE)

## Verification

```bash
#!/bin/bash
set -u
echo "== metrics API =="; kubectl get --raw /apis/metrics.k8s.io/v1beta1/nodes 2>&1 \| head -c 120; echo
echo "== apiservices not True =="; kubectl get apiservices \| grep -v True \| head -5 || true
echo "== hpa =="; kubectl get hpa -A 2>/dev/null \| head -5 || true
echo OK
```

## Safety

- `kubeadm certs renew all` requires restarting static pods (brief API outage).
- Don't delete PriorityClass while pods reference it; eviction behavior changes.

---

<ponytail: Scope ceiling — etcd, API server, certs, metrics-server, HPA only; add etcd backup/restore automation, multi-control-plane HA, and Kubelet TLS bootstrapping when the control plane scales.</ponytail>
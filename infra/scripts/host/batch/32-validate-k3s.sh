#!/usr/bin/env bash
set -Eeuo pipefail

# Validate the single-node k3s cluster and exercise a disposable PVC.
# Cleanup is automatic. Rollback: delete the validation namespace if needed.
step() { printf '\n===== %s =====\n' "$1"; }
fail() { printf 'ERROR: %s\n' "$1" >&2; exit 1; }
step 'Validate prerequisites'
[[ "$(id -u)" -eq 0 ]] || fail 'run with sudo'
for command_name in systemctl kubectl; do command -v "$command_name" >/dev/null || fail "missing $command_name"; done
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
systemctl is-active --quiet k3s || fail 'k3s is not active'
kubectl wait --for=condition=Ready node --all --timeout=120s
step 'Cluster health'
kubectl get nodes -o wide
kubectl get pods -A
kubectl get storageclass
kubectl get events -A --sort-by=.lastTimestamp
kubectl -n kube-system wait --for=condition=Ready pod -l k8s-app=kube-dns --timeout=120s
kubectl -n kube-system get pods -l k8s-app=metrics-server
step 'Disposable PVC validation'
kubectl apply -f - <<'MANIFEST'
apiVersion: v1
kind: Namespace
metadata:
  name: homelab-validation
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: smoke
  namespace: homelab-validation
spec:
  accessModes: [ReadWriteOnce]
  resources:
    requests: {storage: 64Mi}
  storageClassName: local-path
---
apiVersion: v1
kind: Pod
metadata:
  name: smoke
  namespace: homelab-validation
spec:
  restartPolicy: Never
  containers:
    - name: smoke
      image: busybox:1.36.1
      command: ["sh", "-c", "echo phase-c-ok >/data/result && test -s /data/result"]
      volumeMounts: [{name: data, mountPath: /data}]
  volumes: [{name: data, persistentVolumeClaim: {claimName: smoke}}]
MANIFEST
cleanup() { kubectl delete namespace homelab-validation --wait=false >/dev/null 2>&1 || true; }
trap cleanup EXIT
kubectl wait -n homelab-validation --for=jsonpath='{.status.phase}'=Succeeded pod/smoke --timeout=180s
kubectl logs -n homelab-validation smoke
step 'Lifecycle validation'
systemctl stop k3s
systemctl is-active --quiet k3s && fail 'k3s remained active after stop'
systemctl start k3s
systemctl is-active --quiet k3s || fail 'k3s did not restart'
kubectl get nodes
printf '%s\n' 'k3s validation passed; disposable namespace cleanup is pending via trap.'

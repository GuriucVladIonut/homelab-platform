#!/usr/bin/env bash
set -Eeuo pipefail

step() { printf '\n===== %s =====\n' "$1"; }
fail() { printf 'ERROR: %s\n' "$1" >&2; exit 1; }
[[ $EUID -eq 0 ]] || fail 'run with sudo'
[[ -n ${SUDO_USER:-} && $SUDO_USER != root ]] || fail 'run through sudo from the operator account'
for command_name in kubectl install mktemp getent systemctl stat base64; do command -v "$command_name" >/dev/null || fail "missing prerequisite: $command_name"; done
[[ -r /etc/rancher/k3s/k3s.yaml ]] || fail 'root k3s kubeconfig missing'
[[ -r /opt/homelab/control/endpoints.yaml ]] || fail 'homelab-control is not installed'
getent group homelab-control >/dev/null || fail 'homelab-control group missing'
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
step 'Validate read-only RBAC resources'
kubectl -n homelab-system get serviceaccount homelab-control-reader >/dev/null || fail 'ServiceAccount missing; reconcile infrastructure-base first'
kubectl get clusterrole homelab-control-reader >/dev/null || fail 'ClusterRole missing; reconcile infrastructure-base first'
kubectl get clusterrolebinding homelab-control-reader >/dev/null || fail 'ClusterRoleBinding missing; reconcile infrastructure-base first'
step 'Read generated service-account token'
token=''
for attempt in {1..20}; do
  token=$(kubectl -n homelab-system get secret homelab-control-reader-token -o jsonpath='{.data.token}' 2>/dev/null | base64 -d 2>/dev/null || true)
  [[ -n $token ]] && break
  sleep 1
done
[[ -n $token ]] || fail 'service-account token Secret is not populated yet'
ca_data=$(kubectl config view --raw --minify -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')
[[ -n $ca_data ]] || fail 'k3s CA data unavailable'
step 'Install least-privilege kubeconfig'
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
cat >"$tmpdir/kubeconfig" <<EOF
apiVersion: v1
kind: Config
clusters:
- name: homelab
  cluster:
    server: https://127.0.0.1:6443
    certificate-authority-data: ${ca_data}
users:
- name: homelab-control-reader
  user:
    token: ${token}
contexts:
- name: homelab
  context:
    cluster: homelab
    user: homelab-control-reader
current-context: homelab
EOF
install -m 0640 -o root -g homelab-control "$tmpdir/kubeconfig" /opt/homelab/control/kubeconfig-reader
step 'Validate permissions and read-only access'
[[ $(stat -c '%a %U %G' /opt/homelab/control/kubeconfig-reader) == '640 root homelab-control' ]] || fail 'unexpected kubeconfig permissions'
kubectl --kubeconfig /opt/homelab/control/kubeconfig-reader get nodes >/dev/null || fail 'reader kubeconfig cannot read nodes'
if kubectl --kubeconfig /opt/homelab/control/kubeconfig-reader auth can-i create pods 2>/dev/null | grep -qx yes; then fail 'reader kubeconfig has write permission'; fi
systemctl restart homelab-control
systemctl is-active --quiet homelab-control || fail 'homelab-control failed after reader installation'
printf '%s\n' 'Read-only homelab-control kubeconfig installed; no secrets or cluster-admin access granted.'

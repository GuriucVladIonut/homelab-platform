#!/usr/bin/env bash
set -Eeuo pipefail

# Read-only post-reboot/platform validation. Rollback: none; no changes.
step() { printf '\n===== %s =====\n' "$1"; }
fail() { printf 'ERROR: %s\n' "$1" >&2; exit 1; }
[[ $EUID -eq 0 ]] || fail 'run as root'
for command_name in systemctl kubectl flux swapon ufw ss; do
  command -v "$command_name" >/dev/null || fail "missing prerequisite: $command_name"
done
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
step 'Host services and swap'
if systemctl --failed --no-legend | grep -q .; then fail 'failed systemd units are present'; fi
systemctl is-enabled --quiet k3s || fail 'k3s is not enabled'
systemctl is-active --quiet k3s || fail 'k3s is not active'
swapon --show
swapon --show=NAME --noheadings | grep -Fxq /dev/zram0 || fail 'zram swap is not active'
if swapon --show=NAME --noheadings | grep -vFxq /dev/zram0; then fail 'unexpected disk-backed swap is active'; fi
step 'Host kernel and firewall'
test -d /sys/module/overlay || fail 'overlay is not loaded'
test -d /sys/module/br_netfilter || fail 'br_netfilter is not loaded'
test "$(sysctl -n net.ipv4.ip_forward)" = 1 || fail 'ip_forward is not 1'
test "$(sysctl -n net.bridge.bridge-nf-call-iptables)" = 1 || fail 'bridge iptables sysctl is not 1'
test "$(sysctl -n net.bridge.bridge-nf-call-ip6tables)" = 1 || fail 'bridge ip6tables sysctl is not 1'
ufw status | grep -q '^Status: active$' || fail 'UFW is not active'
step 'Cluster and GitOps'
kubectl get nodes
kubectl get nodes --no-headers | awk '$2 != "Ready" {bad=1} END {exit bad}' || fail 'node is not Ready'
flux get all -A
step 'Required workloads'
kubectl -n kube-system rollout status deployment/coredns --timeout=120s
kubectl -n kube-system rollout status deployment/local-path-provisioner --timeout=120s
kubectl -n kube-system rollout status deployment/metrics-server --timeout=120s
kubectl -n ingress rollout status deployment/traefik --timeout=120s
kubectl -n cert-manager rollout status deployment/cert-manager --timeout=120s
kubectl -n cert-manager rollout status deployment/cert-manager-cainjector --timeout=120s
kubectl -n cert-manager rollout status deployment/cert-manager-webhook --timeout=120s
kubectl -n flux-system rollout status deployment/helm-controller --timeout=120s
kubectl -n flux-system rollout status deployment/kustomize-controller --timeout=120s
kubectl -n flux-system rollout status deployment/notification-controller --timeout=120s
kubectl -n flux-system rollout status deployment/source-controller --timeout=120s
kubectl -n observability rollout status deployment/observability-grafana --timeout=120s
kubectl -n observability rollout status deployment/observability-kube-prometh-operator --timeout=120s
kubectl -n observability rollout status deployment/observability-kube-state-metrics --timeout=120s
kubectl -n observability rollout status daemonset/observability-prometheus-node-exporter --timeout=120s
kubectl -n observability rollout status statefulset/prometheus-observability-kube-prometh-prometheus --timeout=120s
kubectl -n kube-system get pods -l svccontroller.k3s.cattle.io/svcname=traefik --no-headers | grep -q '2/2' || fail 'ServiceLB Traefik pod is not 2/2 Ready'
step 'TLS and platform state'
kubectl get clusterissuer letsencrypt-staging-cloudflare
kubectl -n ingress get certificate homelab-wildcard-staging
kubectl -n ingress get tlsstore default
step 'Unexpected application ports'
ss -lntup | grep -E ':(6443|10250|3000|9090|8090)\b' || true
printf '%s\n' 'Platform recovery validation passed.'

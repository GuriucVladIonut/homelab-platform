#!/usr/bin/env bash
set -Eeuo pipefail

# Rollback: remove the drop-in below and restart k3s. No user data is touched.
step() { printf '\n===== %s =====\n' "$1"; }
fail() { printf 'ERROR: %s\n' "$1" >&2; exit 1; }
[[ $EUID -eq 0 ]] || fail 'run as root'
for command_name in kubectl systemctl install sleep; do
  command -v "$command_name" >/dev/null || fail "missing prerequisite: $command_name"
done
step 'Validate current ownership'
systemctl is-active --quiet k3s || fail 'k3s is not active'
kubectl -n ingress get helmrelease traefik >/dev/null 2>&1 || fail 'Flux Traefik HelmRelease is not present'
step 'Persist bundled Traefik disablement'
install -d -m 0750 /etc/rancher/k3s/config.yaml.d
install -m 0644 /dev/stdin /etc/rancher/k3s/config.yaml.d/10-homelab-traefik.yaml <<'CONFIG'
disable:
  - traefik
  - traefik-crd
CONFIG
step 'Restart k3s and wait for API'
systemctl restart k3s
for _ in {1..60}; do
  kubectl get --raw=/readyz >/dev/null 2>&1 && break
  sleep 2
done
kubectl get --raw=/readyz >/dev/null || fail 'k3s API did not become ready'
step 'Remove only generated Traefik HelmCharts'
for chart in traefik traefik-crd; do
  if kubectl -n kube-system get helmchart.helm.cattle.io "$chart" >/dev/null 2>&1; then
    kubectl -n kube-system delete helmchart.helm.cattle.io "$chart" --wait=true
  fi
done
step 'Validate ownership result'
for chart in traefik traefik-crd; do
  if kubectl -n kube-system get helmchart.helm.cattle.io "$chart" >/dev/null 2>&1; then
    fail "bundled HelmChart/$chart still exists"
  fi
done
kubectl -n ingress get helmrelease traefik -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' | grep -Fxq True || fail 'Flux Traefik is not Ready'
printf '%s\n' 'Bundled Traefik disablement persisted; no user data was deleted.'

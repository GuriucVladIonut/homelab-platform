#!/usr/bin/env bash
set -Eeuo pipefail

# Read-only post-reboot/platform validation. Rollback: none; no changes.
step() { printf '\n===== %s =====\n' "$1"; }
fail() { printf 'ERROR: %s\n' "$1" >&2; exit 1; }
[[ $EUID -eq 0 ]] || fail 'run as root'
for command_name in systemctl kubectl flux swapon ufw ss restic date stat curl; do
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
route_https() {
  local namespace=$1 name=$2 host=$3 status
  if kubectl -n "$namespace" get ingressroute "$name" >/dev/null 2>&1; then
    status=$(curl --silent --show-error --insecure --max-time 10 --resolve "$host:443:127.0.0.1" -o /dev/null -w '%{http_code}' "https://$host/") || fail "HTTPS route probe failed: $host"
    [[ $status =~ ^[23][0-9][0-9]$ ]] || fail "HTTPS route returned $status: $host"
  fi
}
step 'Enabled HTTPS routes'
route_https catalog catalog catalog.homelab.gvlad.dev
route_https observability grafana grafana.homelab.gvlad.dev
route_https observability prometheus prometheus.homelab.gvlad.dev
route_https validation whoami validation.homelab.gvlad.dev
if kubectl -n media get deployment jellyfin >/dev/null 2>&1; then
  kubectl -n media rollout status deployment/jellyfin --timeout=180s
  route_https media jellyfin media.homelab.gvlad.dev
fi
if kubectl -n media get deployment navidrome >/dev/null 2>&1; then
  kubectl -n media rollout status deployment/navidrome --timeout=180s
  route_https media navidrome music.homelab.gvlad.dev
fi
if kubectl -n media get deployment books >/dev/null 2>&1; then
  kubectl -n media rollout status deployment/books --timeout=180s
  route_https media books books.homelab.gvlad.dev
fi
if systemctl list-unit-files homelab-private-dns-update.timer 2>/dev/null | grep -q '^homelab-private-dns-update.timer'; then
  systemctl is-active --quiet homelab-private-dns-update.timer || fail 'private DNS update timer is not active'
  for host in catalog grafana prometheus media music books; do
    getent ahostsv4 "$host.homelab.gvlad.dev" >/dev/null || fail "private DNS does not resolve $host.homelab.gvlad.dev"
  done
fi
step 'Backup and storage baseline'
systemctl is-enabled --quiet homelab-backup.timer || fail 'backup timer is not enabled'
systemctl is-active --quiet homelab-backup.timer || fail 'backup timer is not active'
[[ -r /etc/homelab/restic.env ]] || fail 'restic environment is missing'
source /etc/homelab/restic.env
[[ -n ${RESTIC_REPOSITORY:-} && -n ${RESTIC_PASSWORD_FILE:-} ]] || fail 'restic environment variables are missing'
export RESTIC_REPOSITORY RESTIC_PASSWORD_FILE
[[ -r ${RESTIC_PASSWORD_FILE:-} ]] || fail 'restic password file is missing'
restic snapshots --latest 1 >/dev/null || fail 'restic repository is not accessible'
[[ -s /srv/homelab/backups/k3s/latest ]] || fail 'latest k3s snapshot link is missing'
[[ -r /var/lib/homelab-backup/status.env ]] || fail 'backup status file is missing'
grep -q '^STATE=OK$' /var/lib/homelab-backup/status.env || fail 'last backup did not succeed'
last_backup=$(awk -F= '$1 == "LAST_BACKUP" {print $2}' /var/lib/homelab-backup/status.env)
last_backup_epoch=$(date -d "$last_backup" +%s 2>/dev/null || printf 0)
(( last_backup_epoch > 0 && $(date +%s) - last_backup_epoch < 172800 )) || fail 'latest backup is older than 48 hours'
grep -q '^LAST_VERIFICATION=[^[:space:]]' /var/lib/homelab-backup/status.env || fail 'backup verification has not succeeded'
[[ -d /srv/homelab/data ]] || fail 'canonical data directory is missing'
[[ "$(stat -c '%U:%G %a' /srv/homelab/data)" == 'root:homelab-data 2770' ]] || fail 'data directory ownership or mode is unsafe'
step 'Unexpected application ports'
ss -lntup | grep -E ':(6443|10250|3000|9090|8090)\b' || true
printf '%s\n' 'Platform recovery validation passed.'

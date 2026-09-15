#!/usr/bin/env bash
set -Eeuo pipefail

# Install pinned k3s; no curl|sh. Rollback: disable k3s and remove only the
# unit/config after review; never delete /var/lib/rancher/k3s automatically.
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../../../" && pwd)"
source "$ROOT_DIR/infra/versions/k3s.env"
readonly BASE_URL="https://github.com/k3s-io/k3s/releases/download/${K3S_VERSION}"
step() { printf '\n===== %s =====\n' "$1"; }
fail() { printf 'ERROR: %s\n' "$1" >&2; exit 1; }
step 'Validate prerequisites'
[[ "$(id -u)" -eq 0 ]] || fail 'run with sudo'
[[ "$K3S_ARCH" == amd64 ]] || fail 'bundle supports amd64 only'
for command_name in curl install sha256sum grep ip systemctl stat; do command -v "$command_name" >/dev/null || fail "missing $command_name"; done
if [[ ! -f /etc/rancher/k3s/config.yaml ]]; then
    ip route | grep -Eq '(^| )10\.42\.[0-9.]+/[0-9]+|(^| )10\.43\.[0-9.]+/[0-9]+' && fail 'pod/service CIDR collides with existing route' || true
else
    printf '%s\n' 'Existing k3s configuration found; expected k3s CIDR routes are allowed for idempotent rerun.'
fi
step 'Download and verify pinned k3s artifact'
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
curl --fail --location --proto '=https' --tlsv1.2 -o "$tmpdir/k3s" "$BASE_URL/k3s"
curl --fail --location --proto '=https' --tlsv1.2 -o "$tmpdir/checksums.txt" "$BASE_URL/sha256sum-amd64.txt"
grep -E '[[:space:]]k3s$' "$tmpdir/checksums.txt" > "$tmpdir/k3s.checksum" || fail 'official checksum entry missing'
(cd "$tmpdir" && sha256sum --check k3s.checksum) || fail 'k3s checksum verification failed'
step 'Install configuration and systemd unit'
install -d -m 0750 /etc/rancher/k3s
install -m 0640 -o root -g root /dev/stdin /etc/rancher/k3s/config.yaml <<CONFIG
write-kubeconfig-mode: "0640"
disable:
  - traefik
  - traefik-crd
cluster-cidr: ${K3S_CLUSTER_CIDR}
service-cidr: ${K3S_SERVICE_CIDR}
cluster-dns: ${K3S_CLUSTER_DNS}
cluster-domain: ${K3S_CLUSTER_DOMAIN}
CONFIG
install -m 0755 "$tmpdir/k3s" /usr/local/bin/k3s
ln -sfn /usr/local/bin/k3s /usr/local/bin/kubectl
install -m 0644 /dev/stdin /etc/systemd/system/k3s.service <<'UNIT'
[Unit]
Description=Lightweight Kubernetes
After=network-online.target
Wants=network-online.target
[Service]
Type=exec
ExecStart=/usr/local/bin/k3s server
KillMode=process
Delegate=yes
Restart=always
RestartSec=5s
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity
[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable --now k3s
step 'Validate k3s service'
systemctl is-active --quiet k3s || { systemctl status k3s --no-pager; fail 'k3s failed to start'; }
for attempt in {1..60}; do
    [[ -s /etc/rancher/k3s/k3s.yaml ]] && break
    sleep 1
done
[[ -s /etc/rancher/k3s/k3s.yaml ]] || fail 'kubeconfig was not created after 60 seconds'
[[ "$(stat -c '%a' /etc/rancher/k3s/k3s.yaml)" != 644 ]] || fail 'kubeconfig is too broad'
printf '%s\n' "Installed pinned k3s ${K3S_VERSION}; bundled Traefik disabled; systemd enabled."

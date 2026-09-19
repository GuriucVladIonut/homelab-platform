#!/usr/bin/env bash
set -euo pipefail
ROOT=${1:-"$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../" && pwd)"}
fail() { echo "ERROR: $*" >&2; exit 1; }
[[ $EUID -eq 0 ]] || fail "run as root"
command -v apt-get >/dev/null || fail "apt-get is required"
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y dnsmasq dnsutils
install -D -m 0755 "$ROOT/infra/scripts/host/private-dns-update.sh" /usr/local/sbin/homelab-private-dns-update
install -D -m 0644 "$ROOT/infra/systemd/homelab-private-dns-update.service" /etc/systemd/system/homelab-private-dns-update.service
install -D -m 0644 "$ROOT/infra/systemd/homelab-private-dns-update.timer" /etc/systemd/system/homelab-private-dns-update.timer
systemctl daemon-reload
systemctl stop dnsmasq.service 2>/dev/null || true
systemctl enable --now homelab-private-dns-update.timer
systemctl start homelab-private-dns-update.service
systemctl enable --now dnsmasq.service
systemctl restart dnsmasq.service
if command -v ufw >/dev/null && ufw status | grep -q '^Status: active'; then
  ufw allow from 10.0.0.0/8 to any port 53 proto udp comment 'homelab private DNS'
  ufw allow from 10.0.0.0/8 to any port 53 proto tcp comment 'homelab private DNS'
  ufw allow from 172.16.0.0/12 to any port 53 proto udp comment 'homelab private DNS'
  ufw allow from 172.16.0.0/12 to any port 53 proto tcp comment 'homelab private DNS'
  ufw allow from 192.168.0.0/16 to any port 53 proto udp comment 'homelab private DNS'
  ufw allow from 192.168.0.0/16 to any port 53 proto tcp comment 'homelab private DNS'
fi
echo "Private DNS installed. It is opt-in for clients and is not household DNS."

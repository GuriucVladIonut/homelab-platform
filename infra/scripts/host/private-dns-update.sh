#!/usr/bin/env bash
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "must run as root" >&2; exit 1; }
source_ip=$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for (i=1; i<=NF; i++) if ($i == "src") {print $(i+1); exit}}')
interface=$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for (i=1; i<=NF; i++) if ($i == "dev") {print $(i+1); exit}}')
[[ $source_ip =~ ^192\.168\.|^10\.|^172\.(1[6-9]|2[0-9]|3[0-1])\. ]] || { echo "no RFC1918 source route" >&2; exit 1; }
[[ -n $interface ]] || { echo "no private route interface" >&2; exit 1; }
tmp=$(mktemp /etc/dnsmasq.d/homelab.XXXXXX)
trap 'rm -f "$tmp"' EXIT
cat >"$tmp" <<EOF
no-resolv
resolv-file=/run/systemd/resolve/resolv.conf
bind-interfaces
listen-address=127.0.0.1,$source_ip
domain-needed
bogus-priv
cache-size=256
address=/catalog.homelab.gvlad.dev/$source_ip
address=/grafana.homelab.gvlad.dev/$source_ip
address=/prometheus.homelab.gvlad.dev/$source_ip
address=/media.homelab.gvlad.dev/$source_ip
address=/music.homelab.gvlad.dev/$source_ip
address=/books.homelab.gvlad.dev/$source_ip
address=/validation.homelab.gvlad.dev/$source_ip
EOF
install -o root -g root -m 0644 "$tmp" /etc/dnsmasq.d/homelab.conf
rm -f /etc/dnsmasq.d/homelab.??????
resolvectl dns "$interface" 127.0.0.1 || true
resolvectl domain "$interface" '~homelab.gvlad.dev' || true
systemctl reload dnsmasq.service || systemctl restart dnsmasq.service
printf 'private DNS active on %s (%s)\n' "$source_ip" "$interface"

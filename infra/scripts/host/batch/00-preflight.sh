#!/usr/bin/env bash
set -Eeuo pipefail

# Read-only host/platform preflight. No rollback is required.
step() { printf '\n===== %s =====\n' "$1"; }
show() { step "$1"; "$@" 2>&1 || printf 'UNAVAILABLE/FAILED: %s\n' "$*"; }
printf '%s\n' 'Phase B/C preflight (read-only)'
show lsb_release -ds
show uname -a
show systemctl --failed --no-legend
show free -h
show swapon --show
show zramctl
show df -h / /srv/homelab /opt/homelab
show smartctl -H /dev/sda
show nmcli -f NAME,TYPE,AUTOCONNECT,AUTOCONNECT-PRIORITY connection show
show ip route
show resolvectl status
show ufw status verbose
show nft list ruleset
show ss -lntup
show sshd -T
show modinfo overlay
show modinfo br_netfilter
show sysctl net.ipv4.ip_forward net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables
show find /etc/rancher /var/lib/rancher /etc/kubernetes /var/lib/kubelet -maxdepth 2 -print
for command_name in k3s kubectl helm k9s flux; do
    step "Tool: $command_name"
    command -v "$command_name" || printf '%s\n' 'not installed'
done
printf '%s\n' 'Preflight complete; no host state changed.'

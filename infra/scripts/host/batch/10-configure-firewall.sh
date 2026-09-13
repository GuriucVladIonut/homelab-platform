#!/usr/bin/env bash
set -Eeuo pipefail

# Conservative private-host firewall. No public service exposure.
# Rollback: sudo ufw disable; review/remove rules with sudo ufw status numbered.
step() { printf '\n===== %s =====\n' "$1"; }
fail() { printf 'ERROR: %s\n' "$1" >&2; exit 1; }
step 'Validate prerequisites'
[[ "$(id -u)" -eq 0 ]] || fail 'run with sudo'
for command_name in ufw nft iptables-save ss; do command -v "$command_name" >/dev/null || fail "missing $command_name"; done
systemctl is-active --quiet ssh || fail 'SSH is not active; refusing firewall change'
ufw status | grep -Eq '^Status: active$' && fail 'UFW is already active; review manually before this script'
step 'Configure policy'
ufw default deny incoming
ufw default allow outgoing
ufw default deny routed
ufw allow from 10.0.0.0/8 to any port 22 proto tcp comment 'private LAN SSH'
ufw allow from 172.16.0.0/12 to any port 22 proto tcp comment 'private LAN SSH'
ufw allow from 192.168.0.0/16 to any port 22 proto tcp comment 'private LAN SSH'
ufw --force enable
step 'Validate firewall'
ufw status verbose
ufw status | grep -Eq '^Status: active$' || fail 'UFW is not active'
for private_range in 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16; do
    ufw status | grep -Fq "$private_range" || fail "missing private SSH rule: $private_range"
done
if ufw status | grep -Eq 'Anywhere \(v6\).*22|22/tcp.*Anywhere \(v6\)'; then
    fail 'global IPv6 SSH rule detected'
fi
nft list ruleset
iptables-save
ss -lntup
printf '%s\n' 'Firewall enabled: private IPv4 SSH only; no Kubernetes/API/database/dashboard rules added.'

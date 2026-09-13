#!/usr/bin/env bash
set -Eeuo pipefail

# Phase B privileged inspection. This script is read-only.
#
# Collects:
# - UFW, nftables, and iptables firewall state;
# - full SMART health/attribute data for /dev/sda;
# - effective sshd configuration;
# - apt dependency consistency;
# - listening TCP/UDP sockets and owning processes.
#
# No secrets are requested, changed, or written. Output may contain hostnames,
# addresses, usernames, package sources, and service details; review before
# sharing. Rollback: none required because this script performs no mutations.

readonly DISK_DEVICE="/dev/sda"

step() {
    printf '\n===== %s =====\n' "$1"
}

run_required() {
    local label="$1"
    shift
    step "$label"
    "$@"
}

printf '%s\n' 'Phase B privileged host inspection (read-only)'
printf '%s\n' "Host: $(hostname --fqdn 2>/dev/null || hostname)"
printf '%s\n' "Date: $(date --iso-8601=seconds)"

for command_name in ufw nft iptables-save smartctl sshd apt-get ss lsof; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        printf 'ERROR: required command not found: %s\n' "$command_name" >&2
        exit 1
    fi
done

if [[ ! -b "$DISK_DEVICE" ]]; then
    printf 'ERROR: expected block device is unavailable: %s\n' "$DISK_DEVICE" >&2
    exit 1
fi

run_required 'UFW status' ufw status verbose
run_required 'nftables ruleset' nft list ruleset
run_required 'iptables ruleset' iptables-save
run_required "SMART report: ${DISK_DEVICE}" smartctl -a "$DISK_DEVICE"
run_required 'Effective sshd configuration' sshd -T
run_required 'APT dependency consistency' apt-get check
run_required 'Listening sockets and owning processes' ss -lntup
run_required 'Process-aware network handles' lsof -nP -i

step 'Inspection complete'
printf '%s\n' 'No host state was changed. Preserve this output for Phase B review.'

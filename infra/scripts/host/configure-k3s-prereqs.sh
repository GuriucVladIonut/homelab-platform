#!/usr/bin/env bash
set -Eeuo pipefail

# Configure only the kernel prerequisites needed by the future k3s install.
# This loads and persists overlay and br_netfilter, then applies and persists
# the three required sysctls. It does not install k3s or change other sysctls.
# Safe to rerun. Rollback is documented in infra/docs/phase-b-k3s-prereqs.md.

readonly MODULES_FILE=/etc/modules-load.d/homelab-k8s.conf
readonly SYSCTL_FILE=/etc/sysctl.d/90-homelab-k8s.conf
step() { printf '\n===== %s =====\n' "$1"; }
fail() { printf 'ERROR: %s\n' "$1" >&2; exit 1; }

step 'Validate prerequisites'
[[ "$(id -u)" -eq 0 ]] || fail 'run through sudo from a trusted host terminal'
for command_name in modprobe modinfo lsmod sysctl install; do
    command -v "$command_name" >/dev/null || fail "missing command: $command_name"
done
step 'Load required kernel modules'
for module in overlay br_netfilter; do
    printf 'Checking module: %s\n' "$module"
    modinfo "$module" >/dev/null 2>&1 || fail "kernel module unavailable: $module"
    if [[ ! -d "/sys/module/$module" ]]; then
        printf 'Loading module: %s\n' "$module"
        modprobe "$module"
    else
        printf 'Already loaded: %s\n' "$module"
    fi
    [[ -d "/sys/module/$module" ]] || fail "module could not be loaded: $module"
done

step 'Persist required kernel modules'
install -m 0644 /dev/stdin "$MODULES_FILE" <<'MODULES'
overlay
br_netfilter
MODULES

step 'Persist and apply required sysctls'
install -m 0644 /dev/stdin "$SYSCTL_FILE" <<'SYSCTLS'
net.ipv4.ip_forward=1
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
SYSCTLS
sysctl --load "$SYSCTL_FILE"

step 'Validate results'
[[ "$(sysctl -n net.ipv4.ip_forward)" == 1 ]] || fail 'net.ipv4.ip_forward is not 1'
[[ "$(sysctl -n net.bridge.bridge-nf-call-iptables)" == 1 ]] || fail 'bridge-nf-call-iptables is not 1'
[[ "$(sysctl -n net.bridge.bridge-nf-call-ip6tables)" == 1 ]] || fail 'bridge-nf-call-ip6tables is not 1'
printf '%s\n' 'Loaded modules:'
for module in overlay br_netfilter; do
    [[ -d "/sys/module/$module" ]] || fail "module is not loaded after configuration: $module"
    printf '%s: loaded\n' "$module"
done
printf '%s\n' 'Applied sysctls:'
sysctl net.ipv4.ip_forward net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables
printf '%s\n' 'Persistent k3s prerequisites are configured. k3s was not installed.'

#!/usr/bin/env bash
set -Eeuo pipefail

# Read-only Phase B gate. Reports every failed reason and exits nonzero on any.
reasons=()
check() { if "$@" >/dev/null 2>&1; then printf 'PASS %s\n' "$*"; else printf 'FAIL %s\n' "$*"; reasons+=("$*"); fi; }
[[ "$(id -u)" -eq 0 ]] || { echo 'REQUIRES_ROOT'; exit 2; }
printf '%s\n' 'Phase B validation (read-only)'
check bash -c '! systemctl --failed --no-legend | grep -q .'
check systemctl is-enabled --quiet homelab-zram.service
check bash -c 'swapon --show=NAME --noheadings | grep -Fxq /dev/zram0'
check bash -c '! swapon --show=NAME --noheadings | grep -vFxq /dev/zram0'
check bash -c 'size=$(zramctl --bytes --noheadings --output DISKSIZE /dev/zram0 | tr -d "[:space:]"); test "$size" -ge 4294967296 -a "$size" -le 6442450944'
check bash -c 'sshd -T | grep -Fxq "permitrootlogin no"'
check bash -c 'sshd -T | grep -Fxq "passwordauthentication yes"'
check bash -c 'ufw status | grep -Eq "^Status: active$"'
check bash -c 'nmcli -g connection.autoconnect-priority connection show "Wired connection 1" | grep -Fxq 600'
check test -d /srv/homelab/volumes/databases
check test -d /srv/homelab/volumes/apps
check test -d /srv/homelab/backups
check test -d /opt/homelab/scripts
check test -d /sys/module/overlay
check test -d /sys/module/br_netfilter
check bash -c 'test "$(sysctl -n net.ipv4.ip_forward)" = 1'
check bash -c 'test "$(sysctl -n net.bridge.bridge-nf-call-iptables)" = 1'
check bash -c 'test "$(sysctl -n net.bridge.bridge-nf-call-ip6tables)" = 1'
check smartctl -H /dev/sda
check apt-get check
check bash -c '! ss -lntup | grep -E "docker|mysqld|rabbitmq"'
check bash -c '! command -v k3s'
check getent hosts github.com
check bash -c 'timeout 5 bash -c "</dev/tcp/1.1.1.1/443"'
if ((${#reasons[@]})); then printf 'PHASE B: FAIL (%s reason(s))\n' "${#reasons[@]}"; exit 1; fi
printf '%s\n' 'PHASE B: PASS'

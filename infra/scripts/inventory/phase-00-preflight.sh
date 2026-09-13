#!/usr/bin/env bash

set -Eeuo pipefail

STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="$HOME/homelab-phase-00-$STAMP.txt"

exec > >(tee "$OUT") 2>&1

echo "============================================================"
echo "HOMELAB PHASE 00 PREFLIGHT"
echo "============================================================"
echo
date
echo

echo "=== HOST ==="
hostnamectl || true
echo

echo "=== OS ==="
cat /etc/os-release
echo

echo "=== KERNEL ==="
uname -a
echo

echo "=== UPTIME ==="
uptime
echo

echo "=== MEMORY ==="
free -h
echo

echo "=== SWAP ==="
swapon --show
echo

echo "=== FILESYSTEMS ==="
df -hT
echo

echo "=== BLOCK DEVICES ==="
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINTS,MODEL
echo

echo "=== FAILED SYSTEMD UNITS ==="
systemctl --failed --no-pager || true
echo

echo "=== LOGROTATE STATUS ==="
systemctl status logrotate.service --no-pager || true
echo

echo "=== LOGROTATE JOURNAL ==="
journalctl -u logrotate.service -n 100 --no-pager || true
echo

echo "=== ENABLED SERVICES OF INTEREST ==="
for svc in docker containerd mysql rabbitmq-server ssh; do
    echo
    echo "--- $svc ---"
    systemctl is-enabled "$svc" 2>/dev/null || true
    systemctl is-active "$svc" 2>/dev/null || true
done
echo

echo "=== LISTENING SOCKETS ==="
ss -lntup || true
echo

echo "=== DOCKER ==="
docker version 2>/dev/null || true
echo
docker ps -a 2>/dev/null || true
echo

echo "=== MYSQL ==="
systemctl status mysql --no-pager 2>/dev/null || true
echo

echo "=== RABBITMQ ==="
systemctl status rabbitmq-server --no-pager 2>/dev/null || true
echo

echo "=== SSH ==="
systemctl status ssh --no-pager 2>/dev/null || true
echo

echo "=== NETWORK ==="
ip -brief address
echo
ip route
echo

echo "=== DNS ==="
resolvectl status 2>/dev/null || true
echo

echo "=== FIREWALL ==="
ufw status verbose 2>/dev/null || true
echo

echo "=== KVM ==="
ls -l /dev/kvm 2>/dev/null || true
echo

echo "=== KERNEL MODULES ==="
for mod in overlay br_netfilter nf_conntrack vxlan; do
    printf "%-20s " "$mod"
    if lsmod | awk '{print $1}' | grep -qx "$mod"; then
        echo "loaded"
    else
        echo "not loaded"
    fi
done
echo

echo "=== SYSCTL ==="
sysctl net.ipv4.ip_forward 2>/dev/null || true
sysctl net.bridge.bridge-nf-call-iptables 2>/dev/null || true
sysctl net.bridge.bridge-nf-call-ip6tables 2>/dev/null || true
echo

echo "=== AVAILABLE TOOLS ==="
for cmd in \
    git curl jq yq \
    smartctl sensors iw \
    docker containerd \
    kubectl helm k9s k3s \
    virsh qemu-system-x86_64 \
    restic sops age
do
    printf "%-24s " "$cmd"
    if command -v "$cmd" >/dev/null 2>&1; then
        command -v "$cmd"
    else
        echo "MISSING"
    fi
done

echo
echo "============================================================"
echo "REPORT"
echo "============================================================"
echo "$OUT"

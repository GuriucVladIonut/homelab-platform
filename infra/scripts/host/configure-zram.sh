#!/usr/bin/env bash
set -Eeuo pipefail

# Persistent 5 GiB zram swap; no disk-backed swapfile.
# Rollback: sudo systemctl disable --now homelab-zram.service; remove the unit
# and helper below; run systemctl daemon-reload.

readonly UNIT=/etc/systemd/system/homelab-zram.service
readonly HELPER=/usr/local/sbin/homelab-zram-setup
readonly DEVICE=/dev/zram0
readonly SIZE=$((5 * 1024 * 1024 * 1024))
step() { printf '\n===== %s =====\n' "$1"; }
fail() { printf 'ERROR: %s\n' "$1" >&2; exit 1; }

step 'Validate prerequisites'
[[ "$(id -u)" -eq 0 ]] || fail 'run through sudo from a trusted host terminal'
for command_name in free modprobe mkswap swapon swapoff zramctl systemctl install; do
    command -v "$command_name" >/dev/null || fail "missing command: $command_name"
done
# The sysfs control directory is created by the module, so load it before
# checking that interface. This also makes a first run work on a clean host.
modprobe zram
[[ -d /sys/class/zram-control ]] || fail 'kernel zram control is unavailable'
[[ "$(free -b | awk '/^Mem:/ {print $2}')" -ge $((8 * 1024 * 1024 * 1024)) ]] || fail 'less than 8 GiB RAM'
if awk 'NR > 1 {print $1}' /proc/swaps | grep -v '^/dev/zram' | grep -q .; then
    fail 'unrelated active swap exists; refusing to alter it'
fi

step 'Install zram helper'
install -m 0755 /dev/stdin "$HELPER" <<'HELPER'
#!/usr/bin/env bash
set -Eeuo pipefail
readonly DEVICE=/dev/zram0
readonly SIZE=$((5 * 1024 * 1024 * 1024))
modprobe zram
if [[ -b "$DEVICE" ]]; then
    swapon --show=NAME --noheadings | awk '{print $1}' | grep -Fxq "$DEVICE" && swapoff "$DEVICE" || true
    zramctl --reset "$DEVICE"
fi
zramctl --find --size "$SIZE" --algorithm lz4 >/dev/null
[[ -b "$DEVICE" ]] || { echo "expected device was not created: $DEVICE" >&2; exit 1; }
mkswap -L homelab-zram "$DEVICE" >/dev/null
swapon --priority 100 "$DEVICE"
HELPER

step 'Install persistent systemd unit'
install -m 0644 /dev/stdin "$UNIT" <<'UNIT'
[Unit]
Description=Homelab zram swap
After=local-fs.target
Before=swap.target

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/homelab-zram-setup
ExecStop=/bin/sh -c 'if swapon --show=NAME --noheadings | awk '\''{print $1}'\'' | grep -Fxq /dev/zram0; then swapoff /dev/zram0; fi; zramctl --reset /dev/zram0'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
UNIT

step 'Apply and validate'
systemctl stop homelab-zram.service 2>/dev/null || true
systemctl daemon-reload
systemctl enable --now homelab-zram.service
swapon --show
zramctl
swapon --show=NAME --noheadings | awk '{print $1}' | grep -Fxq "$DEVICE" || fail 'zram swap is not active'
actual="$(zramctl --bytes --noheadings --output DISKSIZE "$DEVICE" | tr -d '[:space:]')"
[[ "$actual" -ge $((4 * 1024 * 1024 * 1024)) && "$actual" -le $((6 * 1024 * 1024 * 1024)) ]] || fail 'zram size is outside 4–6 GiB'
systemctl is-enabled homelab-zram.service >/dev/null
systemctl is-active homelab-zram.service >/dev/null
printf '%s\n' 'Persistent 5 GiB zram is active; no disk-backed swapfile was created.'
printf '%s\n' 'Inspect: swapon --show; zramctl; systemctl status homelab-zram.service'
printf '%s\n' 'Disable: sudo systemctl disable --now homelab-zram.service'
printf '%s\n' "Resize: edit SIZE in ${HELPER}, then rerun this script"
printf '%s\n' 'Remove: follow rollback in infra/docs/phase-b-zram.md'

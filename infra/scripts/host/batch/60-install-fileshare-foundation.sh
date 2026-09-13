#!/usr/bin/env bash
set -Eeuo pipefail
# Optional Samba package foundation, disabled by default. It creates no users,
# passwords, shares, or guest-writable storage. Rollback: review /etc/samba,
# then apt remove samba samba-common-bin if explicitly approved.
step() { printf '\n===== %s =====\n' "$1"; }
fail() { printf 'ERROR: %s\n' "$1" >&2; exit 1; }
[[ "$(id -u)" -eq 0 ]] || fail 'run with sudo'
if [[ "${ENABLE_SAMBA:-0}" != 1 ]]; then
    printf '%s\n' 'Samba is OPTIONAL_DISABLED. Set ENABLE_SAMBA=1 only after explicit approval.'
    exit 0
fi
for command_name in apt-get systemctl testparm; do command -v "$command_name" >/dev/null || fail "missing $command_name"; done
step 'Install package foundation without shares'
apt-get install --yes samba samba-common-bin
systemctl disable --now smbd nmbd 2>/dev/null || true
testparm -s >/dev/null
printf '%s\n' 'Samba packages installed; services disabled; no shares or credentials configured.'

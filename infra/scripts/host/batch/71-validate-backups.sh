#!/usr/bin/env bash
set -Eeuo pipefail

# Non-destructive verification. Restores into a temporary directory only.
step() { printf '\n===== %s =====\n' "$1"; }
fail() { printf 'ERROR: %s\n' "$1" >&2; exit 1; }
[[ $EUID -eq 0 ]] || fail 'run with sudo'
for command_name in restic mktemp find test install awk date; do command -v "$command_name" >/dev/null || fail "missing $command_name"; done
[[ -r /etc/homelab/restic.env ]] || fail 'missing /etc/homelab/restic.env'
source /etc/homelab/restic.env
export RESTIC_REPOSITORY RESTIC_PASSWORD_FILE
[[ -r $RESTIC_PASSWORD_FILE ]] || fail 'restic password file is missing'
step 'Check repository'
restic check --read-data-subset=1/20
step 'Restore latest snapshot into temporary directory'
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
restic restore latest --target "$tmpdir"
find "$tmpdir" -path '*/etc/rancher/k3s/config.yaml' -print -quit | grep -q . || fail 'restored k3s config is missing'
find "$tmpdir" -path '*/srv/homelab/backups/k3s/*' -type f -size +0c -print -quit | grep -q . || fail 'restored k3s snapshot is missing'
status=/var/lib/homelab-backup/status.env
[[ -r $status ]] || fail 'backup status file is missing'
verified_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)
tmpstatus=$(mktemp)
trap 'rm -rf "$tmpdir" "$tmpstatus"' EXIT
awk -F= -v stamp="$verified_at" 'BEGIN {updated=0} /^LAST_VERIFICATION=/ {print "LAST_VERIFICATION=" stamp; updated=1; next} {print} END {if (!updated) print "LAST_VERIFICATION=" stamp}' "$status" >"$tmpstatus"
install -o root -g homelab-control -m 0640 "$tmpstatus" "$status"
printf '%s\n' 'Backup repository check and temporary restore validation passed.'
printf '%s\n' 'THIS IS NOT DISASTER RECOVERY.'

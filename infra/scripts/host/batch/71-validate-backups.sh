#!/usr/bin/env bash
set -Eeuo pipefail

# Non-destructive verification. Restores into a temporary directory only.
step() { printf '\n===== %s =====\n' "$1"; }
fail() { printf 'ERROR: %s\n' "$1" >&2; exit 1; }
[[ $EUID -eq 0 ]] || fail 'run with sudo'
for command_name in restic mktemp find test; do command -v "$command_name" >/dev/null || fail "missing $command_name"; done
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
printf '%s\n' 'Backup repository check and temporary restore validation passed.'
printf '%s\n' 'THIS IS NOT DISASTER RECOVERY.'

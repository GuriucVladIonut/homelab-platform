#!/usr/bin/env bash
set -Eeuo pipefail

# Creates the local Restic password and environment file without displaying
# the password. Refuses to overwrite an initialized repository.
fail() { printf 'ERROR: %s\n' "$1" >&2; exit 1; }
[[ $EUID -eq 0 ]] || fail 'run with sudo'
for command_name in openssl install mkdir mv mktemp; do command -v "$command_name" >/dev/null || fail "missing $command_name"; done
base=/etc/homelab
repo=/srv/homelab/backups/restic
install -d -o root -g root -m 0700 "$base"
if [[ -f "$repo/config" ]]; then
  fail 'Restic repository is already initialized; refusing to rotate its password automatically'
fi
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
umask 077
openssl rand -hex 32 >"$tmpdir/restic-password"
printf '%s\n' 'RESTIC_REPOSITORY=/srv/homelab/backups/restic' 'RESTIC_PASSWORD_FILE=/etc/homelab/restic-password' >"$tmpdir/restic.env"
install -o root -g root -m 0600 "$tmpdir/restic-password" "$base/restic-password"
install -o root -g root -m 0600 "$tmpdir/restic.env" "$base/restic.env"
printf '%s\n' 'Restic secret initialized. The password was not displayed.'
printf '%s\n' 'Store the password file in a secure password manager before continuing.'

#!/usr/bin/env bash
set -Eeuo pipefail

# Create the approved Phase B host directory hierarchy. This script does not
# recurse into existing directories, delete data, or change files inside them.
# It is safe to rerun. Rollback is documented in infra/docs/phase-b-storage.md
# and removes directories only when they are empty.

step() { printf '\n===== %s =====\n' "$1"; }
fail() { printf 'ERROR: %s\n' "$1" >&2; exit 1; }

readonly -a ROOT_DIRS=(
    /srv/homelab
    /srv/homelab/volumes
    /srv/homelab/volumes/databases
    /srv/homelab/volumes/apps
    /srv/homelab/volumes/media
    /srv/homelab/volumes/observability
    /srv/homelab/backups
    /srv/homelab/lab
    /srv/homelab/cache
    /opt/homelab
    /opt/homelab/bootstrap
    /opt/homelab/scripts
)

step 'Validate prerequisites'
[[ "$(id -u)" -eq 0 ]] || fail 'run through sudo from a trusted host terminal'
command -v install >/dev/null || fail 'missing command: install'
command -v stat >/dev/null || fail 'missing command: stat'

step 'Create directories with conservative ownership and permissions'
for directory in "${ROOT_DIRS[@]}"; do
    mode=0750
    [[ "$directory" == /srv/homelab || "$directory" == /opt/homelab ]] && mode=0755
    [[ "$directory" == /srv/homelab/backups ]] && mode=0700
    printf 'Ensuring root:root %s %s\n' "$mode" "$directory"
    install -d -o root -g root -m "$mode" "$directory"
done

step 'Validate results'
for directory in "${ROOT_DIRS[@]}"; do
    [[ -d "$directory" ]] || fail "directory missing: $directory"
    owner_group="$(stat -c '%U:%G' "$directory")"
    [[ "$owner_group" == root:root ]] || fail "unexpected owner for $directory: $owner_group"
done
printf '%s\n' 'Directory hierarchy, ownership, and permissions:'
stat -c '%A %U:%G %n' "${ROOT_DIRS[@]}"
printf '%s\n' 'No existing files were recursively changed or removed.'

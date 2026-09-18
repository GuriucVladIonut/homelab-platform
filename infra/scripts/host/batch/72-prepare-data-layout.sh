#!/usr/bin/env bash
set -Eeuo pipefail

# Creates canonical data directories only. It never moves or deletes data.
fail() { printf 'ERROR: %s\n' "$1" >&2; exit 1; }
[[ $EUID -eq 0 ]] || fail 'run with sudo'
for command_name in groupadd usermod install getent id; do command -v "$command_name" >/dev/null || fail "missing $command_name"; done
[[ -d /srv/homelab ]] || fail '/srv/homelab is missing'
getent group homelab-data >/dev/null || groupadd --system homelab-data
id jamal >/dev/null 2>&1 && usermod -a -G homelab-data jamal
install -d -o root -g homelab-data -m 2770 /srv/homelab/data
for directory in incoming music books movies photos; do
  install -d -o root -g homelab-data -m 2770 "/srv/homelab/data/$directory"
done
printf '%s\n' 'Canonical data layout prepared; existing personal data was not moved.'
printf '%s\n' 'Samba remains DISABLED and no household credentials or shares were created.'

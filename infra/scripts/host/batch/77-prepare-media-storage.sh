#!/usr/bin/env bash
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo 'ERROR: run as root' >&2; exit 1; }
for path in /srv/homelab/volumes/apps/media/jellyfin /srv/homelab/volumes/apps/media/navidrome /srv/homelab/volumes/apps/media/books; do
  install -d -o 1000 -g 1000 -m 0770 "$path"
  chown -R 1000:1000 "$path"
  chmod -R u+rwX,g+rwX,o-rwx "$path"
done
for path in /srv/homelab/data/movies /srv/homelab/data/music /srv/homelab/data/books /srv/homelab/data/photos; do
  install -d -m 2770 "$path"
done
echo 'Media config directories prepared for UID/GID 1000; canonical media ownership was not changed.'

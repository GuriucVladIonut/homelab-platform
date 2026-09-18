#!/usr/bin/env bash
set -Eeuo pipefail

fail() { printf 'ERROR: %s\n' "$1" >&2; exit 1; }
[[ $EUID -eq 0 ]] || fail 'run with sudo'
repo_root=${1:-$(pwd)}
image=docker.io/library/homelab-catalog:0.1.0
builder=
if command -v docker >/dev/null; then
  builder=docker
  docker build --tag "$image" "$repo_root/apps/catalog"
elif command -v podman >/dev/null; then
  builder=podman
  podman build --tag "$image" "$repo_root/apps/catalog"
elif command -v buildah >/dev/null; then
  builder=buildah
  buildah bud --tag "$image" "$repo_root/apps/catalog"
else
  fail 'install one image builder first: sudo apt-get install --yes podman'
fi
printf '%s\n' "Catalog image built: $image"
printf '%s\n' 'Loading into containerd namespace k8s.io...'
if [[ $builder == docker ]]; then
  docker save "$image" | k3s ctr -n k8s.io images import -
else
  podman save "$image" | k3s ctr -n k8s.io images import -
fi
printf '%s\n' 'Catalog image imported into containerd namespace k8s.io.'

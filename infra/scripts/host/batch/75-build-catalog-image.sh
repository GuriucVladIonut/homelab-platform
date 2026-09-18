#!/usr/bin/env bash
set -Eeuo pipefail

fail() { printf 'ERROR: %s\n' "$1" >&2; exit 1; }
[[ $EUID -eq 0 ]] || fail 'run with sudo'
repo_root=${1:-$(pwd)}
if command -v docker >/dev/null; then
  docker build --tag homelab-catalog:0.1.0 "$repo_root/apps/catalog"
elif command -v podman >/dev/null; then
  podman build --tag homelab-catalog:0.1.0 "$repo_root/apps/catalog"
elif command -v buildah >/dev/null; then
  buildah bud --tag homelab-catalog:0.1.0 "$repo_root/apps/catalog"
else
  fail 'install one image builder first: sudo apt-get install --yes podman'
fi
if command -v podman >/dev/null && podman image exists localhost/homelab-catalog:0.1.0; then
  podman tag localhost/homelab-catalog:0.1.0 homelab-catalog:0.1.0
fi
printf '%s\n' 'Catalog image built. Load it into k3s containerd before enabling the Flux catalog Kustomization:'
printf '%s\n' 'podman save homelab-catalog:0.1.0 | sudo k3s ctr images import -'

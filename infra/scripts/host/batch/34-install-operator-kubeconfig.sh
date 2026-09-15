#!/usr/bin/env bash
set -Eeuo pipefail

# Rollback: remove only ~/.kube/config-homelab. The root k3s kubeconfig is not
# modified and no credentials are printed.
step() { printf '\n===== %s =====\n' "$1"; }
fail() { printf 'ERROR: %s\n' "$1" >&2; exit 1; }
[[ $EUID -eq 0 ]] || fail 'run as root'
[[ -n ${SUDO_USER:-} && $SUDO_USER != root ]] || fail 'run through sudo from the operator account'
for command_name in install sed stat getent runuser kubectl mktemp; do
  command -v "$command_name" >/dev/null || fail "missing prerequisite: $command_name"
done
[[ -s /etc/rancher/k3s/k3s.yaml ]] || fail 'k3s kubeconfig is missing'
operator_home=$(getent passwd "$SUDO_USER" | cut -d: -f6)
[[ -d $operator_home ]] || fail 'operator home directory is missing'
step 'Create private operator kubeconfig'
install -d -m 0700 -o "$SUDO_USER" -g "$SUDO_USER" "$operator_home/.kube"
tmpfile=$(mktemp)
trap 'rm -f "$tmpfile"' EXIT
sed 's#^\([[:space:]]*server:[[:space:]]*\).*$#\1https://127.0.0.1:6443#' /etc/rancher/k3s/k3s.yaml >"$tmpfile"
install -m 0600 -o "$SUDO_USER" -g "$SUDO_USER" "$tmpfile" "$operator_home/.kube/config-homelab"
step 'Validate permissions and access'
[[ $(stat -c '%a' "$operator_home/.kube/config-homelab") == 600 ]] || fail 'kubeconfig is not mode 0600'
KUBECONFIG="$operator_home/.kube/config-homelab" runuser -u "$SUDO_USER" -- kubectl get --raw=/version >/dev/null || fail 'operator kubectl access failed'
printf 'Installed %s\n' "$operator_home/.kube/config-homelab"
printf '%s\n' 'Use: export KUBECONFIG="$HOME/.kube/config-homelab"'

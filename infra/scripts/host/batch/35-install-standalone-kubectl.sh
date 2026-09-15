#!/usr/bin/env bash
set -Eeuo pipefail

# Install exact upstream kubectl matching the pinned k3s minor.
# Rollback: recreate the former link with:
# ln -s /usr/local/bin/k3s /usr/local/bin/kubectl

readonly KUBECTL_VERSION='v1.36.4'
readonly BASE_URL="https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64"
step() { printf '\n===== %s =====\n' "$1"; }
fail() { printf 'ERROR: %s\n' "$1" >&2; exit 1; }
[[ $EUID -eq 0 ]] || fail 'run as root'
[[ -n ${SUDO_USER:-} && $SUDO_USER != root ]] || fail 'run through sudo from the operator account'
for command_name in curl sha256sum install mktemp getent runuser stat readlink; do
  command -v "$command_name" >/dev/null || fail "missing prerequisite: $command_name"
done
[[ -x /usr/local/bin/k3s ]] || fail 'k3s binary is missing'
operator_home=$(getent passwd "$SUDO_USER" | cut -d: -f6)
config_file="$operator_home/.kube/config-homelab"
[[ -r $config_file ]] || fail "operator kubeconfig missing: $config_file"
step 'Download and verify upstream kubectl'
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
curl --fail --location --proto '=https' --tlsv1.2 -o "$tmpdir/kubectl" "$BASE_URL/kubectl"
curl --fail --location --proto '=https' --tlsv1.2 -o "$tmpdir/kubectl.sha256" "$BASE_URL/kubectl.sha256"
expected=$(tr -d '[:space:]' <"$tmpdir/kubectl.sha256")
[[ $expected =~ ^[0-9a-fA-F]{64}$ ]] || fail 'kubectl checksum has unexpected format'
actual=$(sha256sum "$tmpdir/kubectl" | awk '{print $1}')
[[ $expected == "$actual" ]] || fail 'kubectl checksum verification failed'
step 'Install standalone kubectl'
if [[ -L /usr/local/bin/kubectl && $(readlink -f /usr/local/bin/kubectl) == /usr/local/bin/k3s ]]; then
  rm -f /usr/local/bin/kubectl
fi
install -m 0755 "$tmpdir/kubectl" /usr/local/bin/kubectl
step 'Validate client and operator access'
[[ $(readlink -f /usr/local/bin/kubectl) != /usr/local/bin/k3s ]] || fail 'kubectl still resolves to k3s'
KUBECONFIG="$config_file" runuser -u "$SUDO_USER" -- kubectl version --client >/dev/null
KUBECONFIG="$config_file" runuser -u "$SUDO_USER" -- kubectl get nodes >/dev/null || fail 'operator kubectl access failed'
printf 'Installed kubectl %s at /usr/local/bin/kubectl\n' "$KUBECTL_VERSION"

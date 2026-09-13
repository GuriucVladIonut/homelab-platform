#!/usr/bin/env bash
set -Eeuo pipefail

# Install pinned Helm and k9s binaries with official checksum verification.
# kubectl is provided by the k3s binary and is not duplicated. Rollback:
# remove /usr/local/bin/helm and /usr/local/bin/k9s after stopping users.
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../../../" && pwd)"
source "$ROOT_DIR/infra/versions/tools.env"
step() { printf '\n===== %s =====\n' "$1"; }
fail() { printf 'ERROR: %s\n' "$1" >&2; exit 1; }
step 'Validate prerequisites'
[[ "$(id -u)" -eq 0 ]] || fail 'run with sudo'
for command_name in curl sha256sum tar install k3s; do command -v "$command_name" >/dev/null || fail "missing $command_name"; done
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
step 'Download and verify Helm'
helm_archive="helm-${HELM_VERSION}-linux-amd64.tar.gz"
curl --fail --location --proto '=https' --tlsv1.2 -o "$tmpdir/$helm_archive" "https://get.helm.sh/$helm_archive"
curl --fail --location --proto '=https' --tlsv1.2 -o "$tmpdir/helm.sha256" "https://get.helm.sh/$helm_archive.sha256sum"
(cd "$tmpdir" && sha256sum --check helm.sha256) || fail 'Helm checksum failed'
tar -xzf "$tmpdir/$helm_archive" -C "$tmpdir"
install -m 0755 "$tmpdir/linux-amd64/helm" /usr/local/bin/helm
step 'Download and verify k9s'
k9s_archive="k9s_Linux_amd64.tar.gz"
curl --fail --location --proto '=https' --tlsv1.2 -o "$tmpdir/$k9s_archive" "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/$k9s_archive"
curl --fail --location --proto '=https' --tlsv1.2 -o "$tmpdir/k9s.sha256" "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/checksums.sha256"
grep -E '[[:space:]]k9s_Linux_amd64\.tar\.gz$' "$tmpdir/k9s.sha256" > "$tmpdir/k9s.checksum" || fail 'official k9s checksum entry missing'
(cd "$tmpdir" && sha256sum --check k9s.checksum) || fail 'k9s checksum failed'
tar -xzf "$tmpdir/$k9s_archive" -C "$tmpdir"
install -m 0755 "$tmpdir/k9s" /usr/local/bin/k9s
step 'Validate tools'
helm version
k9s version --short || k9s version
printf '%s\n' 'Helm and k9s installed; kubectl remains the k3s-provided client.'

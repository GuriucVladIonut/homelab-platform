#!/usr/bin/env bash
set -Eeuo pipefail
# Install pinned SOPS, age, and Flux clients; no keys are generated.
# Rollback: remove the installed binaries from /usr/local/bin.
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../../../" && pwd)"
source "$ROOT_DIR/infra/versions/tools.env"
step() { printf '\n===== %s =====\n' "$1"; }
fail() { printf 'ERROR: %s\n' "$1" >&2; exit 1; }
[[ "$(id -u)" -eq 0 ]] || fail 'run with sudo'
for command_name in curl sha256sum tar install grep; do command -v "$command_name" >/dev/null || fail "missing $command_name"; done
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
step 'Install SOPS'
sops_asset="sops-${SOPS_VERSION}.linux.amd64"
curl --fail --location --proto '=https' --tlsv1.2 -o "$tmpdir/sops" "https://github.com/getsops/sops/releases/download/${SOPS_VERSION}/$sops_asset"
curl --fail --location --proto '=https' --tlsv1.2 -o "$tmpdir/sops.sha" "https://github.com/getsops/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.checksums.txt"
awk -v asset="$sops_asset" '$2 == asset {print $1 "  sops"}' "$tmpdir/sops.sha" > "$tmpdir/one.sha" || true
[[ -s "$tmpdir/one.sha" ]] || fail 'SOPS checksum entry missing'
(cd "$tmpdir" && sha256sum --check one.sha) || fail 'SOPS checksum failed'
install -m 0755 "$tmpdir/sops" /usr/local/bin/sops
step 'Install age'
age_archive="age-${AGE_VERSION}-linux-amd64.tar.gz"
curl --fail --location --proto '=https' --tlsv1.2 -o "$tmpdir/$age_archive" "https://github.com/FiloSottile/age/releases/download/${AGE_VERSION}/$age_archive"
curl --fail --location --proto '=https' --tlsv1.2 -o "$tmpdir/age.sha" "https://github.com/FiloSottile/age/releases/download/${AGE_VERSION}/SHA256SUMS"
grep -E "[[:space:]]${age_archive}$" "$tmpdir/age.sha" > "$tmpdir/one.sha" || fail 'age checksum entry missing'
(cd "$tmpdir" && sha256sum --check one.sha) || fail 'age checksum failed'
tar -xzf "$tmpdir/$age_archive" -C "$tmpdir"
install -m 0755 "$tmpdir/age/age" /usr/local/bin/age
install -m 0755 "$tmpdir/age/age-keygen" /usr/local/bin/age-keygen
step 'Install Flux'
flux_archive="flux_${FLUX_VERSION#v}_linux_amd64.tar.gz"
curl --fail --location --proto '=https' --tlsv1.2 -o "$tmpdir/$flux_archive" "https://github.com/fluxcd/flux2/releases/download/${FLUX_VERSION}/$flux_archive"
curl --fail --location --proto '=https' --tlsv1.2 -o "$tmpdir/flux.sha" "https://github.com/fluxcd/flux2/releases/download/${FLUX_VERSION}/flux_${FLUX_VERSION#v}_checksums.txt"
grep -E "[[:space:]]${flux_archive}$" "$tmpdir/flux.sha" > "$tmpdir/one.sha" || fail 'Flux checksum entry missing'
(cd "$tmpdir" && sha256sum --check one.sha) || fail 'Flux checksum failed'
tar -xzf "$tmpdir/$flux_archive" -C "$tmpdir"
install -m 0755 "$tmpdir/flux" /usr/local/bin/flux
step 'Validate tools'
sops --version
age --version
flux --version

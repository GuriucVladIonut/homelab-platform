#!/usr/bin/env bash
set -Eeuo pipefail

fail() { printf 'ERROR: %s\n' "$1" >&2; exit 1; }
[[ $EUID -eq 0 ]] || fail 'run with sudo'
repo_root=${1:-$(pwd)}
[[ -f "$repo_root/.sops.yaml" ]] || fail 'run from the repository or pass its path'
command -v sops >/dev/null || fail 'sops is required'
command -v openssl >/dev/null || fail 'openssl is required'
operator_home=$(getent passwd "${SUDO_USER:-}" | cut -d: -f6 || true)
operator_home=${operator_home:-$HOME}
operator_uid=${SUDO_UID:-$(id -u)}
operator_gid=${SUDO_GID:-$(id -g)}
key_file=${SOPS_AGE_KEY_FILE:-$operator_home/.config/sops/age/keys.txt}
[[ -r $key_file ]] || fail "age key is not readable: $key_file"
secret_dir="$repo_root/infra/infrastructure/postgresql"
secret_file="$secret_dir/postgresql-credentials.sops.yaml"
catalog_secret_dir="$repo_root/infra/infrastructure/catalog"
catalog_secret_file="$catalog_secret_dir/postgresql-credentials.sops.yaml"
if [[ -e $secret_file || -e $catalog_secret_file ]]; then
  [[ -s $secret_file && -s $catalog_secret_file ]] || {
    [[ ! -e $secret_file || -s $secret_file ]] || rm -f -- "$secret_file"
    [[ ! -e $catalog_secret_file || -s $catalog_secret_file ]] || rm -f -- "$catalog_secret_file"
    [[ ! -e $secret_file && ! -e $catalog_secret_file ]] || fail 'an incomplete encrypted Secret remains; remove only the exact incomplete file and retry'
  }
  if [[ -s $secret_file && -s $catalog_secret_file ]]; then
    printf '%s\n' 'Encrypted PostgreSQL and catalog credentials already exist; refusing to replace them.'
    exit 0
  fi
fi
tmp=$(mktemp); trap 'rm -f "$tmp"' EXIT
password=$(openssl rand -hex 32)
cat >"$tmp" <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: postgresql-credentials
  namespace: database
type: Opaque
stringData:
  username: catalog
  password: $password
  database-url: postgres://catalog:$password@postgresql.database.svc.cluster.local:5432/homelab?sslmode=disable
EOF
encrypted_tmp=$(mktemp); catalog_tmp=$(mktemp); trap 'rm -f "$tmp" "$encrypted_tmp" "$catalog_tmp"' EXIT
SOPS_AGE_KEY_FILE="$key_file" sops --encrypt --filename-override "$secret_file" "$tmp" >"$encrypted_tmp"
sed 's/namespace: database/namespace: catalog/' "$tmp" >"$tmp.catalog"
SOPS_AGE_KEY_FILE="$key_file" sops --encrypt --filename-override "$catalog_secret_file" "$tmp.catalog" >"$catalog_tmp"
install -m 0600 "$encrypted_tmp" "$secret_file"
install -m 0600 "$catalog_tmp" "$catalog_secret_file"
chown "$operator_uid:$operator_gid" "$secret_file" "$catalog_secret_file"
rm -f "$tmp.catalog"
printf '%s\n' 'Created encrypted PostgreSQL and catalog credentials; plaintext was not displayed.'
printf '%s\n' 'Next: add each encrypted file to its local Kustomization, copy phase-j.yaml.example to phase-j.yaml, add it to infra/gitops/kustomization.yaml, and commit.'

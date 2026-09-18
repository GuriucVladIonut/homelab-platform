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
key_file=${SOPS_AGE_KEY_FILE:-$operator_home/.config/sops/age/keys.txt}
[[ -r $key_file ]] || fail "age key is not readable: $key_file"
secret_dir="$repo_root/infra/infrastructure/postgresql"
secret_file="$secret_dir/postgresql-credentials.sops.yaml"
[[ ! -e $secret_file ]] || fail 'encrypted PostgreSQL Secret already exists; refusing to replace it'
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
---
apiVersion: v1
kind: Secret
metadata:
  name: postgresql-credentials
  namespace: catalog
type: Opaque
stringData:
  username: catalog
  password: $password
  database-url: postgres://catalog:$password@postgresql.database.svc.cluster.local:5432/homelab?sslmode=disable
EOF
SOPS_AGE_KEY_FILE="$key_file" sops --encrypt "$tmp" >"$secret_file"
chmod 0600 "$secret_file"; printf '%s\n' 'Created encrypted PostgreSQL credentials; plaintext was not displayed.'
printf '%s\n' 'Next: add the encrypted file to postgresql/kustomization.yaml, copy phase-j.yaml.example to phase-j.yaml, add it to infra/gitops/kustomization.yaml, and commit.'

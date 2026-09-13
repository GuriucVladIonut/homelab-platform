#!/usr/bin/env bash
set -Eeuo pipefail

# Aggregate non-destructive repository checks. Root-only/live-cluster checks
# are reported as REQUIRES_ROOT or REQUIRES_CLUSTER rather than obscured.
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd)"
failures=0
pass() { printf 'PASS %s\n' "$1"; }
warn() { printf 'REQUIRES_%s %s\n' "$1" "$2"; }
fail() { printf 'FAIL %s\n' "$1"; failures=$((failures + 1)); }
cd "$ROOT_DIR"
git diff --check || fail 'git diff --check'
bash infra/scripts/validation/validate-markdown.sh . || fail 'Markdown validation'
bash infra/scripts/validation/scan-secrets.sh . || fail 'secret scan'
while IFS= read -r -d '' file; do bash -n "$file" || fail "shell syntax: $file"; done < <(find infra apps -type f -name '*.sh' -print0)
pass 'shell syntax'
[[ -f infra/config/endpoints.yaml ]] && pass 'endpoint registry' || fail 'endpoint registry missing'
[[ -f infra/config/components.yaml ]] && pass 'component catalog' || fail 'component catalog missing'
[[ -f .sops.yaml ]] && pass 'SOPS policy' || fail 'SOPS policy missing'
if command -v yamllint >/dev/null; then yamllint infra/config infra/cluster infra/infrastructure || fail 'yamllint'; else warn TOOL 'yamllint unavailable'; fi
if command -v kustomize >/dev/null; then kustomize build infra/cluster >/dev/null || fail 'kustomize render'; else warn TOOL 'kustomize unavailable'; fi
if command -v helm >/dev/null; then pass 'Helm executable available'; else warn TOOL 'helm unavailable'; fi
if command -v kubeconform >/dev/null; then kubeconform -strict infra/cluster/**/*.yaml || fail 'kubeconform'; else warn TOOL 'kubeconform unavailable'; fi
if command -v shellcheck >/dev/null; then find infra apps -type f -name '*.sh' -print0 | xargs -0 shellcheck || fail 'shellcheck'; else warn TOOL 'shellcheck unavailable'; fi
if command -v kubectl >/dev/null; then kubectl version --client >/dev/null || fail 'kubectl client'; else warn CLUSTER 'kubectl unavailable'; fi
warn ROOT 'host firewall, SMART, systemd, sockets, zram, and sysctl validation belongs to the manual batch scripts'
if (( failures )); then printf 'PLATFORM VALIDATION: FAIL (%s)\n' "$failures"; exit 1; fi
printf '%s\n' 'PLATFORM VALIDATION: PASS (repository checks; unavailable tools/root checks explicitly reported)'

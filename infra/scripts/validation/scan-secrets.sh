#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "${SCRIPT_DIR}" rev-parse --show-toplevel 2>/dev/null)"
ROOT="${1:-${REPO_ROOT}}"
PATTERN='BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]+|github_pat_[A-Za-z0-9_]+|xox[baprs]-|tskey-[A-Za-z0-9_-]+'
found=0

if command -v rg >/dev/null 2>&1; then
  if rg --hidden --glob '!.git/**' -l -e "${PATTERN}" "${ROOT}"; then
    found=1
  fi
else
  if grep -RIlE --exclude-dir=.git "${PATTERN}" "${ROOT}"; then
    found=1
  fi
fi

if (( found == 1 )); then
  echo "WARNING: potential secret-like content found. Review listed files."
  exit 2
fi

echo "PASS: no obvious secret patterns detected."

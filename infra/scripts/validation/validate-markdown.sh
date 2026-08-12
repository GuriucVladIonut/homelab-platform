#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "${SCRIPT_DIR}" rev-parse --show-toplevel 2>/dev/null)"
ROOT="${1:-${REPO_ROOT}}"
errors=0
files=0

while IFS= read -r -d '' file; do
  files=$((files + 1))
  result="$(awk '
    BEGIN { in_fence=0; fence_char=""; fence_len=0; h1=0 }
    {
      line=$0
      sub(/\r$/, "", line)
      if (match(line, /^[ \t]*(```+|~~~+)/)) {
        marker=substr(line,RSTART,RLENGTH)
        gsub(/^[ \t]*/,"",marker)
        c=substr(marker,1,1)
        l=length(marker)
        if (!in_fence) { in_fence=1; fence_char=c; fence_len=l }
        else if (c==fence_char && l>=fence_len) { in_fence=0; fence_char=""; fence_len=0 }
        next
      }
      if (in_fence) next
      if (line ~ /^#[[:space:]]+/) h1++
    }
    END {
      if (in_fence) print "unclosed fenced code block"
      if (h1 != 1) print "expected exactly one H1 outside code blocks, found " h1
    }
  ' "${file}")"

  if [[ -n "${result}" ]]; then
    while IFS= read -r msg; do
      [[ -z "${msg}" ]] && continue
      echo "[FAIL] ${file}: ${msg}"
      errors=$((errors + 1))
    done <<< "${result}"
  fi
done < <(find "${ROOT}" -type f -name '*.md' -not -path '*/.git/*' -print0 | sort -z)

echo "Markdown files checked: ${files}"
if (( errors > 0 )); then
  echo "Markdown validation failed with ${errors} issue(s)."
  exit 1
fi

echo "PASS: Markdown structure checks passed."

#!/usr/bin/env bash
# Shared pre-commit guard. Install: git config core.hooksPath .githooks
# Blocks obvious secret leaks and accidental large files before they enter history.
set -euo pipefail

fail() { echo "pre-commit: $1" >&2; exit 1; }

staged=$(git diff --cached --name-only --diff-filter=ACM)
[ -z "$staged" ] && exit 0

# 1. Never commit these paths
while IFS= read -r f; do
  case "$f" in
    .env|.env.*|*.pem|*.key|*.p12|*.pfx|*id_rsa|secrets.*|credentials.*)
      [ "$f" = ".env.example" ] || fail "refusing to commit sensitive file: $f" ;;
  esac
done <<< "$staged"

# 2. High-signal secret patterns in staged content
pattern='(AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|xox[baprs]-[0-9A-Za-z-]+|ghp_[0-9A-Za-z]{36}|AIza[0-9A-Za-z_-]{35}|sk-[A-Za-z0-9]{20,})'
if git diff --cached -U0 | grep -nE "^\+" | grep -Eq "$pattern"; then
  fail "possible secret detected in staged changes (see pattern match above); remove it or use .env"
fi

# 3. Large files (>5 MB) probably belong in Git LFS or nowhere
while IFS= read -r f; do
  [ -f "$f" ] || continue
  size=$(wc -c < "$f")
  [ "$size" -gt 5242880 ] && fail "large file ($((size/1024/1024)) MB): $f — use Git LFS or ignore it"
done <<< "$staged"

exit 0

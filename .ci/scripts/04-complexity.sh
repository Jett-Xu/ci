#!/usr/bin/env bash
# Item: 複雜度限制 (Cyclomatic Complexity)
# Strict: any function with cyclomatic complexity > 10 fails the build.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/lib/common.sh"
cd "$TARGET_DIR"

THRESHOLD=10

if [ -f package.json ] && { [ -f .eslintrc.js ] || [ -f .eslintrc.json ] || [ -f eslint.config.js ]; }; then
  require_cmd_or_skip npx "npx not available, cannot run eslint"
  require_dep_or_skip eslint
  if ! npx --no-install eslint . --rule "{\"complexity\":[\"error\",${THRESHOLD}]}" --max-warnings 0; then
    fail_check "Function(s) exceed cyclomatic complexity > ${THRESHOLD}"
  fi
  pass_check "All functions within complexity threshold (<= ${THRESHOLD})"
elif { [ -f pyproject.toml ] || [ -f requirements.txt ]; } && has_cmd radon; then
  OUT="$(radon cc -nc -s . | awk -v t="$THRESHOLD" '$NF+0 > t')"
  if [ -n "$OUT" ]; then
    fail_check "radon found functions exceeding complexity ${THRESHOLD}"
  fi
  pass_check "All Python functions within complexity threshold"
else
  skip_check "No complexity-checking tool available for this project type"
fi

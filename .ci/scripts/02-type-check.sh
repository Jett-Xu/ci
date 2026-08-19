#!/usr/bin/env bash
# Item: 靜態型別檢查 (Type Check)
# Strict: no 'any', no implicit errors. tsc --noEmit --strict / mypy --strict.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/lib/common.sh"
cd "$TARGET_DIR"

if [ -f tsconfig.json ]; then
  require_cmd_or_skip npx "npx not available, cannot run tsc"
  require_dep_or_skip typescript
  if ! npx --no-install tsc --noEmit --strict; then
    fail_check "tsc --noEmit --strict reported type errors"
  fi
  pass_check "TypeScript strict type check clean"
elif [ -f pyproject.toml ] || [ -f requirements.txt ] || [ -f setup.py ]; then
  if has_cmd mypy; then
    if ! mypy --strict .; then
      fail_check "mypy --strict reported type errors"
    fi
    pass_check "mypy strict type check clean"
  else
    skip_check "mypy not installed"
  fi
else
  skip_check "No typed language config found"
fi

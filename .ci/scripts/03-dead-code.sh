#!/usr/bin/env bash
# Item: 死程式碼與重複 (Dead Code)
# Strict: unused vars/imports and duplicated blocks both fail the build.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/lib/common.sh"
cd "$TARGET_DIR"

FAILED=0

if [ -f package.json ]; then
  RAN_ANY=0
  if [ -f knip.json ] || [ -f knip.jsonc ] || has_dep knip; then
    if has_dep knip; then
      require_cmd_or_skip npx "npx not available, cannot run knip"
      npx --no-install knip --fail-on-unknown || FAILED=1
      RAN_ANY=1
    else
      ci_skip "缺少套件 \"knip\"(尚未安裝於 node_modules),略過 dead-code 檢查"
    fi
  fi
  if has_dep jscpd; then
    npx --no-install jscpd . --threshold 0 || FAILED=1
    RAN_ANY=1
  fi
  if [ "$RAN_ANY" -eq 0 ] && [ "$FAILED" -eq 0 ]; then
    skip_check "Neither knip nor jscpd is installed"
  fi
elif [ -f pyproject.toml ] || [ -f requirements.txt ]; then
  if has_cmd vulture; then
    vulture . || FAILED=1
  else
    skip_check "vulture not installed"
  fi
else
  skip_check "No dead-code tool configured for this project type"
fi

[ "$FAILED" -eq 1 ] && fail_check "Dead code / duplication detected"
pass_check "No dead code or duplication detected"

#!/usr/bin/env bash
# Item: 危險 API 與語法禁用
# Strict: eval(), innerHTML, console.log, os.system, pickle.loads, etc. all fail the build.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/lib/common.sh"
cd "$TARGET_DIR"

FAILED=0

if [ -f package.json ] && { [ -f .eslintrc.js ] || [ -f .eslintrc.json ] || [ -f eslint.config.js ]; }; then
  require_cmd_or_skip npx "npx not available, cannot run eslint"
  if has_dep eslint; then
    if ! npx --no-install eslint . --rule '{"no-console":"error","no-eval":"error"}' --max-warnings 0; then
      FAILED=1
    fi
  else
    ci_skip "缺少套件 \"eslint\"(尚未安裝於 node_modules),略過 no-console/no-eval 檢查"
  fi
  MATCH=$(grep -rlnE '\.innerHTML\s*=' --include='*.ts' --include='*.tsx' --include='*.js' --include='*.jsx' \
    --exclude-dir=node_modules --exclude-dir=.git . || true)
  if [ -n "$MATCH" ]; then
    FAILED=1
    ci_fail "Direct innerHTML assignment found (XSS risk): $MATCH"
  fi
fi

if [ -f pyproject.toml ] || [ -f requirements.txt ] || [ -f setup.py ]; then
  MATCH=$(grep -rlnE '\beval\(|\bexec\(|os\.system\(|pickle\.loads\(' --include='*.py' . || true)
  if [ -n "$MATCH" ]; then
    FAILED=1
    ci_fail "Dangerous Python API found (eval/exec/os.system/pickle.loads): $MATCH"
  fi
fi

[ "$FAILED" -eq 1 ] && fail_check "Dangerous/debug API usage detected"
pass_check "No dangerous or debug API usage detected"

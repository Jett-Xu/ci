#!/usr/bin/env bash
# Item: Coding Style & Formatting
# Strict: any lint warning fails the build (--max-warnings 0). No auto-fix.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/lib/common.sh"
cd "$TARGET_DIR"

if [ -f package.json ]; then
  if [ -f .eslintrc.js ] || [ -f .eslintrc.json ] || [ -f .eslintrc.cjs ] || [ -f eslint.config.js ] || [ -f eslint.config.mjs ]; then
    require_cmd_or_skip npx "npx not available, cannot run eslint"
    require_dep_or_skip eslint
    if ! npx --no-install eslint . --max-warnings 0; then
      fail_check "ESLint found errors or warnings (--max-warnings 0)"
    fi
    if [ -f .prettierrc ] || [ -f .prettierrc.json ] || [ -f prettier.config.js ]; then
      if has_dep prettier; then
        if ! npx --no-install prettier --check .; then
          fail_check "Prettier formatting check failed"
        fi
      else
        ci_skip "缺少套件 \"prettier\"(尚未安裝於 node_modules),略過 Prettier 格式檢查"
      fi
    fi
    pass_check "ESLint/Prettier clean"
  else
    skip_check "No ESLint config found in Node project"
  fi
elif [ -f pyproject.toml ] || [ -f requirements.txt ] || [ -f setup.py ]; then
  if has_cmd black; then
    if ! black --check .; then
      fail_check "black formatting check failed"
    fi
  else
    skip_check "black not installed, cannot check Python formatting"
  fi
  pass_check "Python formatting clean"
else
  skip_check "No recognized project type for coding style check"
fi

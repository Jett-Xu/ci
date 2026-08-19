#!/usr/bin/env bash
# Item: 單元與整合測試
# Strict: all unit and integration tests must pass 100%. Any failure fails the build.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/lib/common.sh"
cd "$TARGET_DIR"

if [ -f package.json ]; then
  require_cmd_or_skip npm "npm not installed"
  require_npm_script_or_skip test
  if ! CI=true npm run test; then
    fail_check "Test suite reported failures"
  fi
  pass_check "All tests passed"
elif [ -f requirements.txt ] || [ -f pyproject.toml ] || [ -f setup.py ]; then
  if has_cmd pytest; then
    if ! pytest; then
      fail_check "pytest reported failures"
    fi
    pass_check "All Python tests passed"
  else
    skip_check "pytest not installed"
  fi
else
  skip_check "No recognized test runner for this project type"
fi

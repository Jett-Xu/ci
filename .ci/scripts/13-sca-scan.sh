#!/usr/bin/env bash
# Item: 套件漏洞掃描 (SCA - Software Composition Analysis)
# Strict: any high/critical known vulnerability in dependencies fails the build.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/lib/common.sh"
cd "$TARGET_DIR"

if [ -f package.json ]; then
  require_cmd_or_skip npm "npm not installed"
  if [ ! -f package-lock.json ] && [ ! -f npm-shrinkwrap.json ]; then
    skip_check "缺少 package-lock.json(npm audit 需要 lockfile 才能執行),略過此項檢查"
  fi
  if ! npm audit --audit-level=high; then
    fail_check "npm audit found high/critical vulnerabilities"
  fi
  pass_check "npm audit clean at high severity threshold"
elif [ -f requirements.txt ] || [ -f pyproject.toml ]; then
  if has_cmd pip-audit; then
    if ! pip-audit; then
      fail_check "pip-audit found known vulnerabilities"
    fi
    pass_check "pip-audit clean"
  else
    skip_check "pip-audit not installed"
  fi
else
  skip_check "No recognized dependency manifest found"
fi

#!/usr/bin/env bash
# Item: 靜態資安分析 (SAST)
# Strict: any SQL Injection / XSS / injection-class finding fails the build.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/lib/common.sh"
cd "$TARGET_DIR"

require_cmd_or_skip semgrep "semgrep not installed"

if ! semgrep --config p/ci --error .; then
  fail_check "semgrep p/ci ruleset found security findings"
fi
pass_check "semgrep found no security issues"

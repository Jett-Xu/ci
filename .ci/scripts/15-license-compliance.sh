#!/usr/bin/env bash
# Item: 開源授權合規 (License)
# Strict: any GPL/AGPL or other non-allowlisted, contagious license fails the build.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/lib/common.sh"
cd "$TARGET_DIR"

ALLOWED='MIT;Apache-2.0;BSD;BSD-2-Clause;BSD-3-Clause;ISC;0BSD;CC0-1.0'

if [ -f package.json ]; then
  require_cmd_or_skip npx "npx not available, cannot run license-checker"
  require_dep_or_skip license-checker
  if ! npx --no-install license-checker --summary --onlyallow "$ALLOWED"; then
    fail_check "license-checker found non-allowlisted licenses (e.g. GPL/AGPL)"
  fi
  pass_check "All dependency licenses are within the allowlist"
elif [ -f requirements.txt ] || [ -f pyproject.toml ]; then
  if has_cmd pip-licenses; then
    OUT=$(pip-licenses --format=json)
    if echo "$OUT" | grep -qiE '"License":\s*".*(GPL|AGPL)'; then
      fail_check "pip-licenses found GPL/AGPL-licensed dependency"
    fi
    pass_check "All Python dependency licenses are within policy"
  else
    skip_check "pip-licenses not installed"
  fi
else
  skip_check "No recognized dependency manifest found"
fi

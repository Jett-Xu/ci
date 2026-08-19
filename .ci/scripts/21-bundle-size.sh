#!/usr/bin/env bash
# Item: 前端 Bundle 體積限制
# Strict: any packaged JS/CSS file over the configured size limit fails the build.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/lib/common.sh"
cd "$TARGET_DIR"

if [ ! -f package.json ]; then
  skip_check "Not a Node/frontend project"
fi

if has_dep size-limit && [ -f .size-limit.json ]; then
  require_cmd_or_skip npx "npx not available, cannot run size-limit"
  if ! npx --no-install size-limit; then
    fail_check "size-limit reported bundle over budget"
  fi
  pass_check "Bundle size within configured budget"
elif has_dep bundlesize; then
  require_cmd_or_skip npx "npx not available, cannot run bundlesize"
  if ! npx --no-install bundlesize; then
    fail_check "bundlesize reported bundle over budget"
  fi
  pass_check "Bundle size within configured budget"
else
  skip_check "Neither size-limit nor bundlesize configured"
fi

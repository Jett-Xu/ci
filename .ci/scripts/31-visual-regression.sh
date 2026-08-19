#!/usr/bin/env bash
# Item: Visual Regression Testing
# Strict: any pixel-diff (headless screenshot comparison) fails the build.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/lib/common.sh"
cd "$TARGET_DIR"

if [ ! -f package.json ]; then
  skip_check "Not a Node/frontend project"
fi

if has_dep '@playwright/test' && find . -maxdepth 3 -iname '*.visual.spec.*' -not -path '*/node_modules/*' | grep -q .; then
  require_cmd_or_skip npx "npx not available, cannot run playwright"
  if ! npx --no-install playwright test --grep visual; then
    fail_check "Playwright visual regression tests found pixel differences"
  fi
  pass_check "No visual regressions detected (Playwright)"
elif has_dep '@percy/cli' || has_dep 'chromatic'; then
  skip_check "Percy/Chromatic require an external service token; run their CLI directly in your pipeline"
else
  skip_check "No visual regression tooling configured"
fi

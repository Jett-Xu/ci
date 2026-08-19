#!/usr/bin/env bash
# Item: 測試覆蓋率門檻 (Coverage)
# Strict: overall coverage must be >= 80%. Below threshold fails the build.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/lib/common.sh"
cd "$TARGET_DIR"

THRESHOLD=80

is_vitest_project() {
  has_dep vitest || [ -f vitest.config.ts ] || [ -f vitest.config.js ] || [ -f vitest.config.mts ] || [ -f vitest.config.mjs ]
}

is_jest_project() {
  has_dep jest || [ -f jest.config.js ] || [ -f jest.config.ts ] || [ -f jest.config.cjs ] || [ -f jest.config.mjs ] || \
    node -e "process.exit(require('./package.json').jest ? 0 : 1)" 2>/dev/null
}

if [ -f package.json ] && is_vitest_project; then
  require_cmd_or_skip npx "npx not available, cannot run coverage"
  require_dep_or_skip vitest
  # Vitest doesn't bundle a coverage engine — it needs a separate provider
  # package. Without one, `vitest --coverage` prompts interactively to
  # install it, which would hang here instead of skipping cleanly.
  if ! has_dep '@vitest/coverage-v8' && ! has_dep '@vitest/coverage-istanbul'; then
    skip_check "缺少套件 \"@vitest/coverage-v8\"(或 @vitest/coverage-istanbul)(尚未安裝於 node_modules),略過覆蓋率檢查"
  fi
  if ! npx --no-install vitest run --coverage \
      --coverage.thresholds.lines="${THRESHOLD}" \
      --coverage.thresholds.functions="${THRESHOLD}" \
      --coverage.thresholds.branches="${THRESHOLD}" \
      --coverage.thresholds.statements="${THRESHOLD}"; then
    fail_check "Vitest coverage below ${THRESHOLD}% threshold"
  fi
  pass_check "Vitest coverage meets ${THRESHOLD}% threshold"
elif [ -f package.json ] && is_jest_project; then
  require_cmd_or_skip npx "npx not available, cannot run coverage"
  require_dep_or_skip jest
  if ! npx --no-install jest --coverage --coverageThreshold="{\"global\":{\"branches\":${THRESHOLD},\"functions\":${THRESHOLD},\"lines\":${THRESHOLD},\"statements\":${THRESHOLD}}}"; then
    fail_check "Jest coverage below ${THRESHOLD}% threshold"
  fi
  pass_check "Jest coverage meets ${THRESHOLD}% threshold"
elif [ -f package.json ]; then
  skip_check "package.json found but neither Jest nor Vitest is configured"
elif [ -f requirements.txt ] || [ -f pyproject.toml ]; then
  if has_cmd pytest; then
    if ! pytest --cov=. --cov-fail-under="$THRESHOLD"; then
      fail_check "Python coverage below ${THRESHOLD}% threshold"
    fi
    pass_check "Python coverage meets ${THRESHOLD}% threshold"
  else
    skip_check "pytest/pytest-cov not installed"
  fi
else
  skip_check "No recognized coverage tool for this project type"
fi

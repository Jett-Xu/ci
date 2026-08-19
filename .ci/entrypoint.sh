#!/usr/bin/env bash
# .ci/entrypoint.sh
#
# Main CI entry point. Detects whether the target project is frontend
# (Node.js/Vue/React) or backend (Go/Python/Node.js), then runs every
# applicable check script under .ci/scripts/ in the strictest possible mode:
# any warning, or any check below its threshold, fails the whole run
# immediately (exit code 1) and stops the pipeline.
#
# Usage:
#   .ci/entrypoint.sh [target-project-dir]
#
# Env:
#   TARGET_DIR     - project to check (overrides the positional arg)
#   CI_FAIL_FAST   - "false" to run every check and report all failures at
#                    the end instead of stopping at the first one (default: true)
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${SCRIPT_DIR}/scripts"
export TARGET_DIR="${TARGET_DIR:-${1:-$(pwd)}}"
FAIL_FAST="${CI_FAIL_FAST:-true}"

source "${SCRIPTS_DIR}/lib/common.sh"

if [ ! -d "$TARGET_DIR" ]; then
  ci_fail "Target project directory does not exist: $TARGET_DIR"
  exit 1
fi
cd "$TARGET_DIR"

# ---------------------------------------------------------------------------
# 1. Detect project type
# ---------------------------------------------------------------------------
PROJECT_TYPE=""   # frontend | backend | fullstack
FRONTEND_FRAMEWORK=""
BACKEND_LANGUAGE=""

is_frontend_pkg() {
  [ -f package.json ] || return 1
  node -e "
    const p = require('./package.json');
    const all = Object.assign({}, p.dependencies, p.devDependencies);
    const markers = ['react','vue','@angular/core','svelte','next','nuxt','vite'];
    process.exit(markers.some(m => Object.prototype.hasOwnProperty.call(all, m)) ? 0 : 1);
  " 2>/dev/null
}

is_backend_node_pkg() {
  [ -f package.json ] || return 1
  node -e "
    const p = require('./package.json');
    const all = Object.assign({}, p.dependencies, p.devDependencies);
    const markers = ['express','koa','fastify','@nestjs/core','hapi'];
    process.exit(markers.some(m => Object.prototype.hasOwnProperty.call(all, m)) ? 0 : 1);
  " 2>/dev/null
}

HAS_FRONTEND=0
HAS_BACKEND=0

if is_frontend_pkg; then
  HAS_FRONTEND=1
  FRONTEND_FRAMEWORK="node"
fi
if is_backend_node_pkg; then
  HAS_BACKEND=1
  BACKEND_LANGUAGE="node"
fi
if [ -f requirements.txt ] || [ -f pyproject.toml ] || [ -f setup.py ] || [ -f Pipfile ]; then
  HAS_BACKEND=1
  BACKEND_LANGUAGE="${BACKEND_LANGUAGE:+$BACKEND_LANGUAGE,}python"
fi
# A package.json with no frontend/backend framework markers is still Node —
# treat it as backend Node unless it clearly looks like a frontend app.
if [ -f package.json ] && [ "$HAS_FRONTEND" -eq 0 ] && [ "$HAS_BACKEND" -eq 0 ]; then
  HAS_BACKEND=1
  BACKEND_LANGUAGE="node"
fi

if [ "$HAS_FRONTEND" -eq 1 ] && [ "$HAS_BACKEND" -eq 1 ]; then
  PROJECT_TYPE="fullstack"
elif [ "$HAS_FRONTEND" -eq 1 ]; then
  PROJECT_TYPE="frontend"
elif [ "$HAS_BACKEND" -eq 1 ]; then
  PROJECT_TYPE="backend"
else
  ci_fail "Could not detect project type in $TARGET_DIR (no package.json/requirements.txt/pyproject.toml found)"
  exit 1
fi

ci_info "Target project : $TARGET_DIR"
ci_info "Project type   : $PROJECT_TYPE (frontend=${FRONTEND_FRAMEWORK:-none}, backend=${BACKEND_LANGUAGE:-none})"
ci_info "Fail-fast mode : $FAIL_FAST"

# ---------------------------------------------------------------------------
# 2. Build the list of checks to run
# ---------------------------------------------------------------------------
COMMON_CHECKS=(
  05-secrets-scan.sh
  06-spelling.sh
  08-markdown-lint.sh
  16-pii-check.js
  25-commit-message.sh
  26-pr-template.js
  27-supply-chain.sh
  28-license-header.js
  29-git-history.sh
  30-env-version.sh
)

# Checks that make sense for any codebase, frontend or backend (tooling
# self-detects the language inside the script).
SHARED_CODE_CHECKS=(
  01-coding-style.sh
  02-type-check.sh
  03-dead-code.sh
  04-complexity.sh
  11-dangerous-api.sh
  13-sca-scan.sh
  14-sast-scan.sh
  15-license-compliance.sh
  17-unit-test.sh
  18-test-coverage.sh
)

FRONTEND_ONLY_CHECKS=(
  07-i18n-check.js
  12-design-token.sh
  21-bundle-size.sh
  22-image-size.js
  31-visual-regression.sh
)

BACKEND_ONLY_CHECKS=(
  19-api-contract.sh
  20-db-migration.sh
  23-api-performance.sh
  24-dockerfile-lint.sh
)

CHECKS=("${COMMON_CHECKS[@]}" "${SHARED_CODE_CHECKS[@]}")
case "$PROJECT_TYPE" in
  frontend)  CHECKS+=("${FRONTEND_ONLY_CHECKS[@]}") ;;
  backend)   CHECKS+=("${BACKEND_ONLY_CHECKS[@]}") ;;
  fullstack) CHECKS+=("${FRONTEND_ONLY_CHECKS[@]}" "${BACKEND_ONLY_CHECKS[@]}") ;;
esac

# ---------------------------------------------------------------------------
# 3. Run checks — strict: first failure aborts the pipeline (fail-fast default)
# ---------------------------------------------------------------------------
FAILURES=()
TOTAL=${#CHECKS[@]}
COUNT=0

for check in "${CHECKS[@]}"; do
  COUNT=$((COUNT + 1))
  SCRIPT_PATH="${SCRIPTS_DIR}/${check}"
  if [ ! -f "$SCRIPT_PATH" ]; then
    ci_fail "Check script not found: $SCRIPT_PATH"
    FAILURES+=("$check")
    [ "$FAIL_FAST" = "true" ] && break
    continue
  fi

  ci_info "-------------------------------------------------------------"
  ci_info "[$COUNT/$TOTAL] Running $check"

  case "$check" in
    *.js) RUNNER=(node "$SCRIPT_PATH") ;;
    *)    RUNNER=(bash "$SCRIPT_PATH") ;;
  esac

  if TARGET_DIR="$TARGET_DIR" "${RUNNER[@]}"; then
    ci_pass "$check"
  else
    ci_fail "$check"
    FAILURES+=("$check")
    if [ "$FAIL_FAST" = "true" ]; then
      ci_fail "Stopping pipeline immediately (fail-fast, zero tolerance for warnings/failures)."
      break
    fi
  fi
done

ci_info "-------------------------------------------------------------"
if [ "${#FAILURES[@]}" -gt 0 ]; then
  ci_fail "CI FAILED. ${#FAILURES[@]} check(s) failed: ${FAILURES[*]}"
  exit 1
fi

ci_pass "CI PASSED. All ${TOTAL} applicable checks succeeded (strict mode, zero warnings)."
exit 0

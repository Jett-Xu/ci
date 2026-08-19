#!/usr/bin/env bash
# Item: API 契約測試 (Contract)
# Strict: any breaking change between the base and PR OpenAPI spec fails the build.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/lib/common.sh"
cd "$TARGET_DIR"

BASE_SPEC="${CI_OPENAPI_BASE:-openapi-base.yaml}"
PR_SPEC="${CI_OPENAPI_PR:-openapi-pr.yaml}"

if [ ! -f "$BASE_SPEC" ] || [ ! -f "$PR_SPEC" ]; then
  skip_check "No OpenAPI base/PR spec pair found ($BASE_SPEC, $PR_SPEC)"
fi

require_cmd_or_skip oasdiff "oasdiff not installed"

if ! oasdiff breaking "$BASE_SPEC" "$PR_SPEC" --fail-on ERR; then
  fail_check "oasdiff detected breaking API contract changes"
fi
pass_check "No breaking API contract changes detected"

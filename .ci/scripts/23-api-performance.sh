#!/usr/bin/env bash
# Item: API 效能基準測試
# Strict: p95/threshold response time over 200ms fails the build.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/lib/common.sh"
cd "$TARGET_DIR"

K6_SCRIPT="${CI_K6_SCRIPT:-.ci/perf/script.js}"

if [ ! -f "$K6_SCRIPT" ]; then
  skip_check "No k6 performance script found at $K6_SCRIPT"
fi
require_cmd_or_skip k6 "k6 not installed"

if ! k6 run --thresholds 'http_req_duration<200' "$K6_SCRIPT"; then
  fail_check "k6 reported API response time exceeding 200ms threshold"
fi
pass_check "API performance within 200ms threshold"

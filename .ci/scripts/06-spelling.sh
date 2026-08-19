#!/usr/bin/env bash
# Item: 錯別字檢查 (Spelling)
# Strict: any misspelling in comments/identifiers/UI text fails the build.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/lib/common.sh"
cd "$TARGET_DIR"

if has_cmd cspell; then
  if ! cspell "**/*.{ts,tsx,js,jsx,md,json,go,py}" --no-progress --no-summary; then
    fail_check "cspell found spelling issues"
  fi
  pass_check "cspell found no spelling issues"
elif has_cmd codespell; then
  if ! codespell .; then
    fail_check "codespell found spelling issues"
  fi
  pass_check "codespell found no spelling issues"
else
  skip_check "Neither cspell nor codespell is installed"
fi

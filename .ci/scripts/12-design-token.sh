#!/usr/bin/env bash
# Item: 設計系統 Token 規範
# Strict: hard-coded hex colors in CSS/Tailwind must use design tokens instead.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/lib/common.sh"
cd "$TARGET_DIR"

CSS_FILES=$(find . \( -name '*.css' -o -name '*.scss' \) \
  -not -path './node_modules/*' -not -path './.git/*' \
  -not -path './coverage/*' -not -path './dist/*' -not -path './build/*' -not -path './.next/*')
if [ -z "$CSS_FILES" ]; then
  skip_check "No CSS/SCSS files found"
fi

if has_cmd stylelint && { [ -f .stylelintrc ] || [ -f .stylelintrc.json ] || [ -f .stylelintrc.js ]; }; then
  if ! stylelint "**/*.{css,scss}"; then
    fail_check "stylelint reported violations (see color-no-hex rule)"
  fi
  pass_check "stylelint clean, design tokens respected"
fi

# Fallback: raw grep for hex colors, excluding token-definition files.
MATCH=$(grep -rlnE '#[0-9a-fA-F]{3,8}\b' $CSS_FILES 2>/dev/null | grep -vE 'tokens?\.(css|scss)$|variables\.(css|scss)$' || true)
if [ -n "$MATCH" ]; then
  fail_check "Hard-coded hex colors found outside design-token files: $MATCH"
fi
pass_check "No hard-coded hex colors found"

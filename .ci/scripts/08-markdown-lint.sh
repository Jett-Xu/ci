#!/usr/bin/env bash
# Item: Markdown 排版規範
# Strict: heading hierarchy, broken links, and spacing issues all fail the build.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/lib/common.sh"
cd "$TARGET_DIR"

MD_FILES=$(find . -name '*.md' -not -path './node_modules/*' -not -path './.git/*')
if [ -z "$MD_FILES" ]; then
  skip_check "No Markdown files found"
fi

FAILED=0
if has_cmd markdownlint; then
  markdownlint "**/*.md" --ignore node_modules || FAILED=1
elif has_cmd npx && has_dep markdownlint-cli; then
  npx --no-install markdownlint-cli "**/*.md" --ignore node_modules || FAILED=1
else
  skip_check "markdownlint not installed (globally or as a devDependency)"
fi

if has_cmd markdown-link-check; then
  while IFS= read -r f; do
    markdown-link-check "$f" -q || FAILED=1
  done <<< "$MD_FILES"
fi

[ "$FAILED" -eq 1 ] && fail_check "Markdown lint or link-check violations found"
pass_check "Markdown formatting and links are valid"

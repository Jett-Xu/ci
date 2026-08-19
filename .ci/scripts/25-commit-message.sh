#!/usr/bin/env bash
# Item: Commit Message 規範
# Strict: must follow Conventional Commits and include a JIRA-style ticket ID.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/lib/common.sh"
cd "$TARGET_DIR"

if [ ! -d .git ]; then
  skip_check "Not a git repository"
fi

if has_cmd commitlint && { [ -f .commitlintrc.js ] || [ -f .commitlintrc.json ] || [ -f commitlint.config.js ]; }; then
  if ! commitlint --from=HEAD~1; then
    fail_check "commitlint rejected the last commit message"
  fi
  pass_check "Commit message passes commitlint"
fi

MSG=$(git log -1 --pretty=%s)
CONVENTIONAL_RE='^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([a-z0-9-]+\))?: .+'
JIRA_RE='[A-Z]{2,}-[0-9]+'

if ! echo "$MSG" | grep -qE "$CONVENTIONAL_RE"; then
  fail_check "Commit message does not follow Conventional Commits format: \"$MSG\""
fi
if ! echo "$MSG" | grep -qE "$JIRA_RE"; then
  fail_check "Commit message is missing a JIRA ticket reference (e.g. ABC-123): \"$MSG\""
fi
pass_check "Commit message follows Conventional Commits and includes a JIRA reference"

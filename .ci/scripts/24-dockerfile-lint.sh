#!/usr/bin/env bash
# Item: Dockerfile 最佳實踐
# Strict: root user execution or unpinned (latest) base image tags fail the build.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/lib/common.sh"
cd "$TARGET_DIR"

DOCKERFILES=$(find . -iname 'Dockerfile*' -not -path './node_modules/*' -not -path './.git/*')
if [ -z "$DOCKERFILES" ]; then
  skip_check "No Dockerfile found"
fi

require_cmd_or_skip hadolint "hadolint not installed"

FAILED=0
while IFS= read -r f; do
  [ -z "$f" ] && continue
  hadolint "$f" || FAILED=1
  grep -qE '^\s*FROM\s+\S+:latest' "$f" && { ci_fail "$f uses an unpinned 'latest' tag"; FAILED=1; }
  grep -qE '^\s*USER\s+root' "$f" && { ci_fail "$f explicitly runs as root"; FAILED=1; }
  grep -qE '^\s*USER\s' "$f" || { ci_fail "$f never switches away from the default root user"; FAILED=1; }
done <<< "$DOCKERFILES"

[ "$FAILED" -eq 1 ] && fail_check "Dockerfile best-practice violations found"
pass_check "All Dockerfiles follow best practices"

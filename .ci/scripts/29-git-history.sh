#!/usr/bin/env bash
# Item: Git History Hygiene
# Strict: any file over 5MB in history, or unresolved merge-conflict markers, fails the build.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/lib/common.sh"
cd "$TARGET_DIR"

if [ ! -d .git ]; then
  skip_check "Not a git repository"
fi

FAILED=0
LIMIT=$((5 * 1024 * 1024))

if has_cmd git-sizer; then
  git-sizer --threshold 5MiB || FAILED=1
else
  BIG=$(git rev-list --objects --all 2>/dev/null | \
    git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' 2>/dev/null | \
    awk -v limit="$LIMIT" '$1=="blob" && $3+0>limit {print $3, $4}')
  if [ -n "$BIG" ]; then
    FAILED=1
    ci_fail $'Files >5MB found in git history:\n'"$BIG"
  fi
fi

CONFLICT_MARKERS=$(grep -rlE '^(<<<<<<<|=======|>>>>>>>)( |$)' --exclude-dir=.git --exclude-dir=node_modules . || true)
if [ -n "$CONFLICT_MARKERS" ]; then
  FAILED=1
  ci_fail "Unresolved merge conflict markers found: $CONFLICT_MARKERS"
fi

[ "$FAILED" -eq 1 ] && fail_check "Git history hygiene violations found"
pass_check "Git history is clean (no oversized blobs, no conflict markers)"

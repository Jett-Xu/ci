#!/usr/bin/env bash
# Item: Supply Chain / Typosquatting
# Strict: dependency names that look like a misspelled clone of a popular package fail the build.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/lib/common.sh"
cd "$TARGET_DIR"

if has_cmd socket; then
  if ! socket scan --report; then
    fail_check "socket.dev flagged suspicious/typosquatted dependencies"
  fi
  pass_check "socket.dev scan clean"
fi

if [ ! -f package.json ]; then
  skip_check "No package.json found for typosquat heuristic check"
fi
require_cmd_or_skip node "node not installed"

node "$DIR/lib/typosquat-check.js"

#!/usr/bin/env bash
# Item: Environment / Node Version
# Strict: local/CI runtime version must exactly match .nvmrc / .python-version.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/lib/common.sh"
cd "$TARGET_DIR"

CHECKED=0

if [ -f .nvmrc ]; then
  CHECKED=1
  EXPECTED=$(tr -d '[:space:]v' < .nvmrc)
  require_cmd_or_skip node "node not installed"
  ACTUAL=$(node -v | tr -d 'v')
  if [[ "$ACTUAL" != "$EXPECTED"* ]]; then
    fail_check "Node version mismatch: .nvmrc wants ${EXPECTED}, environment has ${ACTUAL}"
  fi
fi

if [ -f .python-version ]; then
  CHECKED=1
  EXPECTED=$(tr -d '[:space:]' < .python-version)
  require_cmd_or_skip python3 "python3 not installed"
  ACTUAL=$(python3 -V 2>&1 | awk '{print $2}')
  if [[ "$ACTUAL" != "$EXPECTED"* ]]; then
    fail_check "Python version mismatch: .python-version wants ${EXPECTED}, environment has ${ACTUAL}"
  fi
fi

if [ "$CHECKED" -eq 0 ]; then
  skip_check "No .nvmrc / .python-version found to pin a runtime version"
fi
pass_check "Local runtime version(s) match pinned environment spec"

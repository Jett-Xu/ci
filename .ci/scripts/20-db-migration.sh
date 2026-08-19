#!/usr/bin/env bash
# Item: 資料庫 Migration 可逆性
# Strict: migrate:up must succeed and migrate:down must fully revert. Either failing fails the build.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/lib/common.sh"
cd "$TARGET_DIR"

COMPOSE_FILE="${CI_DB_COMPOSE:-.ci/db.yml}"

if [ ! -f "$COMPOSE_FILE" ]; then
  skip_check "No DB docker-compose file found at $COMPOSE_FILE"
fi
require_cmd_or_skip docker-compose "docker-compose not installed"
require_npm_script_or_skip migrate:up
require_npm_script_or_skip migrate:down

if ! docker-compose -f "$COMPOSE_FILE" up -d; then
  fail_check "Failed to start migration test DB"
fi
trap 'docker-compose -f "$COMPOSE_FILE" down -v >/dev/null 2>&1' EXIT

if ! npm run migrate:up; then
  fail_check "migrate:up failed"
fi
if ! npm run migrate:down; then
  fail_check "migrate:down failed to revert cleanly"
fi

pass_check "DB migrations are reversible (up and down both succeeded)"

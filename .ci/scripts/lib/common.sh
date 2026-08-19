#!/usr/bin/env bash
# Shared helpers for all .ci/scripts/*.sh checks.
# Contract: every check script must exit 0 on PASS or SKIP, and exit 1 on FAIL.
# Zero-tolerance: any warning found by an underlying tool counts as FAIL, not just errors.

set -uo pipefail

CI_RED=$'\033[31m'
CI_GREEN=$'\033[32m'
CI_YELLOW=$'\033[33m'
CI_BLUE=$'\033[34m'
CI_RESET=$'\033[0m'

# Windows/Git-Bash's `pwd` and path args come out as MSYS-style paths
# (/c/Users/...). Native Windows binaries (node.exe, and anything invoked via
# npx) cannot resolve those — they need a drive-letter form (C:/Users/...).
# Normalize once here so every script and every subprocess sees a path that
# both bash and Windows binaries understand.
_ci_normalize_path() {
  local p="$1"
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -m "$p" 2>/dev/null || printf '%s' "$p"
  elif [[ "$p" =~ ^/([a-zA-Z])(/.*)?$ ]]; then
    printf '%s:%s' "${BASH_REMATCH[1]^^}" "${BASH_REMATCH[2]:-/}"
  else
    printf '%s' "$p"
  fi
}

TARGET_DIR="${TARGET_DIR:-$(pwd)}"
TARGET_DIR="$(_ci_normalize_path "$TARGET_DIR")"
export TARGET_DIR

ci_log()  { printf '%s\n' "$*" >&2; }
ci_pass() { ci_log "${CI_GREEN}[PASS]${CI_RESET} $*"; }
ci_fail() { ci_log "${CI_RED}[FAIL]${CI_RESET} $*"; }
ci_skip() { ci_log "${CI_YELLOW}[SKIP]${CI_RESET} $*"; }
ci_info() { ci_log "${CI_BLUE}[INFO]${CI_RESET} $*"; }

# skip_check <reason> — not applicable to this project, exits 0.
skip_check() {
  ci_skip "$*"
  exit 0
}

# fail_check <reason> — violation found, exits 1. Strict mode: no exceptions.
fail_check() {
  ci_fail "$*"
  exit 1
}

# pass_check <reason> — check ran and found nothing wrong, exits 0.
pass_check() {
  ci_pass "$*"
  exit 0
}

# has_cmd <bin> — true if a CLI tool is installed.
has_cmd() { command -v "$1" >/dev/null 2>&1; }

# has_file <relative-path> — true if file exists under TARGET_DIR.
has_file() { [ -f "${TARGET_DIR}/$1" ]; }

# has_dir <relative-path> — true if dir exists under TARGET_DIR.
has_dir() { [ -d "${TARGET_DIR}/$1" ]; }

# has_dep <package-name> — true if the package is physically installed under
# TARGET_DIR/node_modules. This is what actually determines whether `npx
# <tool>` will work — a package merely *declared* in package.json but never
# `npm install`-ed would still make npx fail.
has_dep() {
  [ -e "${TARGET_DIR}/node_modules/$1" ]
}

# require_cmd_or_skip <bin> <reason> — skip the whole check if a CLI tool
# (not an npm package — a standalone binary like gitleaks/semgrep/hadolint)
# is missing from PATH. A missing tool means "not verified", not "failed".
require_cmd_or_skip() {
  local bin="$1" reason="$2"
  has_cmd "$bin" || skip_check "$reason"
}

# require_dep_or_skip <npm-package-name> — skip the whole check if a required
# devDependency isn't physically installed in node_modules. Call this before
# any `npx <tool>` invocation so a missing tool reads as "not verified /
# missing dependency", never as a lint/test failure.
require_dep_or_skip() {
  local pkg="$1"
  has_dep "$pkg" || skip_check "缺少套件 \"${pkg}\"(尚未安裝於 node_modules),略過此項檢查"
}

# has_npm_script <script-name> — true if package.json declares that script.
has_npm_script() {
  [ -f "${TARGET_DIR}/package.json" ] || return 1
  node -e "
    const s = (require('${TARGET_DIR}/package.json').scripts) || {};
    process.exit(Object.prototype.hasOwnProperty.call(s, '$1') ? 0 : 1);
  " 2>/dev/null
}

# require_npm_script_or_skip <script-name> — skip the whole check if
# package.json doesn't declare the script this check needs to run.
require_npm_script_or_skip() {
  local script="$1"
  has_npm_script "$script" || skip_check "package.json 未定義 \"${script}\" script,略過此項檢查"
}

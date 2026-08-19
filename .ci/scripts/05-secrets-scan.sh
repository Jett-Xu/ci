#!/usr/bin/env bash
# Item: 機密資訊掃描 (Secrets)
# Strict: any detected secret (API key, private key, JWT, token) fails the build.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/lib/common.sh"
cd "$TARGET_DIR"

if has_cmd gitleaks; then
  if ! gitleaks detect --source . -v --no-git; then
    fail_check "gitleaks detected secrets in source"
  fi
  pass_check "gitleaks found no secrets"
elif has_cmd trufflehog; then
  if ! trufflehog filesystem . --fail; then
    fail_check "trufflehog detected secrets in source"
  fi
  pass_check "trufflehog found no secrets"
else
  skip_check "Neither gitleaks nor trufflehog is installed"
fi

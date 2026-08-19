#!/usr/bin/env node
// npx entry point: `npx github:Jett-Xu/ci [target-dir]`
// This is a thin wrapper — the real logic lives in .ci/entrypoint.sh (bash).
// It exists only because `npx`'s bin mechanism needs a Node-executable entry
// point to work cross-platform (Windows can't directly exec a .sh file).
'use strict';
const { spawnSync } = require('child_process');
const path = require('path');

const REPO_ROOT = path.resolve(__dirname, '..');
const ENTRYPOINT = path.join(REPO_ROOT, '.ci', 'entrypoint.sh');

const targetDir = process.argv[2] || process.cwd();

const result = spawnSync('bash', [ENTRYPOINT, targetDir], {
  stdio: 'inherit',
  env: process.env,
});

if (result.error) {
  console.error(`[ci-check] Could not launch bash: ${result.error.message}`);
  console.error('[ci-check] This tool requires bash in PATH (Git Bash on Windows, native on macOS/Linux).');
  process.exit(1);
}

process.exit(result.status === null ? 1 : result.status);

#!/usr/bin/env node
// npx entry point: `npx github:Jett-Xu/ci [target-dir]`
// This is a thin wrapper — the real logic lives in .ci/entrypoint.sh (bash).
// It exists only because `npx`'s bin mechanism needs a Node-executable entry
// point to work cross-platform (Windows can't directly exec a .sh file).
'use strict';
const { spawnSync, execFileSync } = require('child_process');
const path = require('path');

const REPO_ROOT = path.resolve(__dirname, '..');
const ENTRYPOINT = path.join(REPO_ROOT, '.ci', 'entrypoint.sh');

const targetDir = process.argv[2] || process.cwd();

// On Windows, `bash` can resolve to more than one thing in PATH:
// Git Bash's real bash.exe, or C:\Windows\System32\bash.exe — which is a WSL
// launcher stub, not a usable bash, and fails if no WSL distro is installed.
// PATH order varies per machine, so we can't just call `bash` and hope.
// Explicitly find a candidate outside System32 and prefer that.
function resolveBash() {
  if (process.platform !== 'win32') return 'bash';
  try {
    const out = execFileSync('where', ['bash'], { encoding: 'utf8' });
    const candidates = out.split(/\r?\n/).map((s) => s.trim()).filter(Boolean);
    const usable = candidates.find((p) => !/\\Windows\\System32\\/i.test(p));
    return usable || candidates[0] || 'bash';
  } catch {
    return 'bash';
  }
}

const bashCmd = resolveBash();

const result = spawnSync(bashCmd, [ENTRYPOINT, targetDir], {
  stdio: 'inherit',
  env: process.env,
});

if (result.error) {
  console.error(`[ci-check] Could not launch bash: ${result.error.message}`);
  console.error('[ci-check] This tool requires bash in PATH (Git Bash on Windows, native on macOS/Linux).');
  process.exit(1);
}

process.exit(result.status === null ? 1 : result.status);

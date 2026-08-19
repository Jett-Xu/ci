#!/usr/bin/env node
// npx entry point: `npx github:Jett-Xu/ci [target-dir]`
// This is a thin wrapper — the real logic lives in .ci/entrypoint.sh (bash).
// It exists only because `npx`'s bin mechanism needs a Node-executable entry
// point to work cross-platform (Windows can't directly exec a .sh file).
'use strict';
const { spawnSync, execFileSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const REPO_ROOT = path.resolve(__dirname, '..');
const ENTRYPOINT = path.join(REPO_ROOT, '.ci', 'entrypoint.sh');

const targetDir = process.argv[2] || process.cwd();

// Windows can have several things named "bash" that are NOT a real shell:
// C:\Windows\System32\bash.exe and the WindowsApps app-execution-alias stub
// are both WSL launchers, and fail if no WSL distro is installed/working.
// Git for Windows also frequently does NOT put its real bash.exe on the
// system PATH at all — its default install option only adjusts PATH inside
// a launched Git Bash window, so `where bash` from a plain PowerShell/cmd
// session often finds nothing usable even when Git Bash is installed.
// Strategy: search PATH first (skipping known WSL stubs), then fall back to
// deriving bash.exe's location from wherever git.exe lives (git.exe is far
// more reliably on PATH), then a few well-known default install paths.
const KNOWN_BAD_BASH = [/\\Windows\\System32\\/i, /\\AppData\\Local\\Microsoft\\WindowsApps\\/i];

function isRealBash(p) {
  return typeof p === 'string' && p && fs.existsSync(p) && !KNOWN_BAD_BASH.some((re) => re.test(p));
}

function whereAll(cmd) {
  try {
    const out = execFileSync('where', [cmd], { encoding: 'utf8' });
    return out.split(/\r?\n/).map((s) => s.trim()).filter(Boolean);
  } catch {
    return [];
  }
}

function resolveBash() {
  if (process.platform !== 'win32') return 'bash';

  const onPath = whereAll('bash').find(isRealBash);
  if (onPath) return onPath;

  for (const gitExe of whereAll('git')) {
    const gitRoot = path.dirname(path.dirname(gitExe)); // e.g. .../Git/cmd/git.exe -> .../Git
    for (const rel of ['bin/bash.exe', 'usr/bin/bash.exe']) {
      const candidate = path.join(gitRoot, rel);
      if (isRealBash(candidate)) return candidate;
    }
  }

  for (const fixed of [
    'C:\\Program Files\\Git\\bin\\bash.exe',
    'C:\\Program Files\\Git\\usr\\bin\\bash.exe',
    'C:\\Program Files (x86)\\Git\\bin\\bash.exe',
  ]) {
    if (isRealBash(fixed)) return fixed;
  }

  return 'bash'; // nothing found — let spawnSync surface the real error
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

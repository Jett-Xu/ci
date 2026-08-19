#!/usr/bin/env node
// Item: Header License Notice
// Strict: every .ts/.go/.py source file must start with the company copyright header.
'use strict';
const fs = require('fs');
const path = require('path');

const TARGET_DIR = process.env.TARGET_DIR || process.cwd();
const EXTS = new Set(['.ts', '.tsx', '.go', '.py']);
const IGNORE_DIRS = new Set(['node_modules', '.git', 'dist', 'build', '.ci', 'vendor']);

// Override via CI_COPYRIGHT_NOTICE env var. Matched as a substring near the top of the file.
const NOTICE = process.env.CI_COPYRIGHT_NOTICE || 'Copyright';

function skip(reason) {
  console.error(`[SKIP] ${reason}`);
  process.exit(0);
}
function fail(reason) {
  console.error(`[FAIL] ${reason}`);
  process.exit(1);
}
function pass(reason) {
  console.error(`[PASS] ${reason}`);
  process.exit(0);
}

if (!fs.existsSync(TARGET_DIR)) {
  skip(`target dir ${TARGET_DIR} does not exist`);
}

let missing = [];

function walk(dir) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    if (IGNORE_DIRS.has(entry.name)) continue;
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      walk(full);
    } else if (EXTS.has(path.extname(entry.name))) {
      const head = fs.readFileSync(full, 'utf8').slice(0, 500);
      if (!head.includes(NOTICE)) {
        missing.push(full);
      }
    }
  }
}

walk(TARGET_DIR);

if (missing.length > 0) {
  fail(`${missing.length} file(s) missing the required copyright header:\n${missing.join('\n')}`);
}
pass('All source files carry the required copyright header');

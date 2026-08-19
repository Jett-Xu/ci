#!/usr/bin/env node
// Item: PII 個資洩漏防禦
// Strict: log statements that print PII fields verbatim fail the build.
'use strict';
const fs = require('fs');
const path = require('path');

const TARGET_DIR = process.env.TARGET_DIR || process.cwd();
const EXTS = new Set(['.ts', '.tsx', '.js', '.jsx', '.go', '.py']);
const IGNORE_DIRS = new Set(['node_modules', '.git', 'dist', 'build', '.ci']);

const PATTERNS = [
  { name: 'log of PII field', re: /(console\.log|log\.(info|debug)|print|fmt\.Print\w*)\([^)]*\b(email|phone|ssn)\b/gi },
];

let violations = [];

function walk(dir) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    if (IGNORE_DIRS.has(entry.name)) continue;
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      walk(full);
    } else if (EXTS.has(path.extname(entry.name))) {
      const content = fs.readFileSync(full, 'utf8');
      for (const { name, re } of PATTERNS) {
        const matches = content.match(re);
        if (matches) {
          violations.push(`${full}: ${name} (${matches.length} match(es))`);
        }
      }
    }
  }
}

if (!fs.existsSync(TARGET_DIR)) {
  console.error(`[SKIP] target dir ${TARGET_DIR} does not exist`);
  process.exit(0);
}

walk(TARGET_DIR);

if (violations.length > 0) {
  console.error('[FAIL] PII logging found:');
  violations.forEach((v) => console.error('  - ' + v));
  process.exit(1);
}
console.error('[PASS] No PII logging found');
process.exit(0);

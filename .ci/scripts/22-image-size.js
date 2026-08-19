#!/usr/bin/env node
// Item: 圖片與媒體資源壓縮
// Strict: any image committed to the repo over 300KB fails the build.
'use strict';
const fs = require('fs');
const path = require('path');

const TARGET_DIR = process.env.TARGET_DIR || process.cwd();
const LIMIT_BYTES = Number(process.env.CI_IMAGE_LIMIT_BYTES || 300 * 1024);
const EXTS = new Set(['.png', '.jpg', '.jpeg', '.gif', '.bmp']);
const IGNORE_DIRS = new Set(['node_modules', '.git', 'dist', 'build']);

let offenders = [];

function walk(dir) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    if (IGNORE_DIRS.has(entry.name)) continue;
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      walk(full);
    } else if (EXTS.has(path.extname(entry.name).toLowerCase())) {
      const size = fs.statSync(full).size;
      if (size > LIMIT_BYTES) {
        offenders.push(`${full}: ${(size / 1024).toFixed(1)}KB (limit ${(LIMIT_BYTES / 1024).toFixed(0)}KB)`);
      }
    }
  }
}

if (!fs.existsSync(TARGET_DIR)) {
  console.error(`[SKIP] target dir ${TARGET_DIR} does not exist`);
  process.exit(0);
}

walk(TARGET_DIR);

if (offenders.length > 0) {
  console.error('[FAIL] Oversized images found (compress to WebP or similar):');
  offenders.forEach((o) => console.error('  - ' + o));
  process.exit(1);
}
console.error('[PASS] No oversized images found');
process.exit(0);

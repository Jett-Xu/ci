#!/usr/bin/env node
// Item: i18n 多國語言完整性
// Strict: every key in the primary locale file must exist in every other locale file.
'use strict';
const fs = require('fs');
const path = require('path');

const TARGET_DIR = process.env.TARGET_DIR || process.cwd();
const LOCALES_DIR = process.env.CI_LOCALES_DIR || 'locales';
const PRIMARY_LOCALE = process.env.CI_PRIMARY_LOCALE || 'en';

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

const localesPath = path.join(TARGET_DIR, LOCALES_DIR);
if (!fs.existsSync(localesPath)) {
  skip(`No locales directory found at ${LOCALES_DIR}`);
}

function flattenKeys(obj, prefix = '') {
  let keys = [];
  for (const [k, v] of Object.entries(obj)) {
    const full = prefix ? `${prefix}.${k}` : k;
    if (v && typeof v === 'object' && !Array.isArray(v)) {
      keys = keys.concat(flattenKeys(v, full));
    } else {
      keys.push(full);
    }
  }
  return keys;
}

const files = fs.readdirSync(localesPath).filter((f) => f.endsWith('.json'));
if (files.length === 0) {
  skip(`No JSON locale files found under ${LOCALES_DIR}`);
}

const primaryFile = files.find((f) => f.startsWith(PRIMARY_LOCALE));
if (!primaryFile) {
  skip(`Primary locale "${PRIMARY_LOCALE}" not found among locale files`);
}

const primaryKeys = new Set(
  flattenKeys(JSON.parse(fs.readFileSync(path.join(localesPath, primaryFile), 'utf8')))
);

let mismatched = false;
for (const file of files) {
  if (file === primaryFile) continue;
  const keys = new Set(
    flattenKeys(JSON.parse(fs.readFileSync(path.join(localesPath, file), 'utf8')))
  );
  const missing = [...primaryKeys].filter((k) => !keys.has(k));
  const extra = [...keys].filter((k) => !primaryKeys.has(k));
  if (missing.length || extra.length) {
    mismatched = true;
    console.error(`[FAIL] ${file}: missing=${JSON.stringify(missing)} extra=${JSON.stringify(extra)}`);
  }
}

if (mismatched) fail('i18n key sets are not 100% in sync across locales');
pass('All locale files are 100% key-synchronized with primary locale');

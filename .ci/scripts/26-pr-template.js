#!/usr/bin/env node
// Item: PR Template 檢查
// Strict: PR description must exceed a minimum length and every checklist item
// must be checked. Reads the PR body from $CI_PR_BODY_FILE or $PR_BODY.
'use strict';
const fs = require('fs');

const MIN_LENGTH = Number(process.env.CI_PR_MIN_LENGTH || 50);

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

let body = process.env.PR_BODY || '';
if (!body && process.env.CI_PR_BODY_FILE && fs.existsSync(process.env.CI_PR_BODY_FILE)) {
  body = fs.readFileSync(process.env.CI_PR_BODY_FILE, 'utf8');
}

if (!body) {
  skip('No PR body available (set PR_BODY or CI_PR_BODY_FILE) — not running inside a PR context');
}

if (body.trim().length < MIN_LENGTH) {
  fail(`PR description is only ${body.trim().length} chars, below the ${MIN_LENGTH}-char minimum`);
}

const checklistItems = body.match(/^- \[[ xX]\].*/gm) || [];
if (checklistItems.length === 0) {
  fail('PR description contains no checklist items');
}
const unchecked = checklistItems.filter((line) => /^- \[ \]/.test(line));
if (unchecked.length > 0) {
  fail(`PR checklist has ${unchecked.length} unchecked item(s):\n${unchecked.join('\n')}`);
}

pass('PR description meets length requirement and checklist is fully checked');

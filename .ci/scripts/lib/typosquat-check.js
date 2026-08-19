#!/usr/bin/env node
// Heuristic typosquat detector: flags a dependency whose name is a Levenshtein
// distance of 1 away from a well-known popular package (but isn't that package).
'use strict';
const fs = require('fs');
const path = require('path');

const TARGET_DIR = process.env.TARGET_DIR || process.cwd();
const pkgPath = path.join(TARGET_DIR, 'package.json');

const POPULAR = [
  'react', 'react-dom', 'lodash', 'express', 'axios', 'chalk', 'commander',
  'request', 'moment', 'underscore', 'jquery', 'webpack', 'babel', 'eslint',
  'typescript', 'vue', 'next', 'jest', 'mocha', 'chai', 'dotenv', 'uuid',
  'colors', 'debug', 'semver', 'yargs', 'glob', 'async', 'bluebird', 'rxjs',
];

function levenshtein(a, b) {
  const m = a.length, n = b.length;
  const dp = Array.from({ length: m + 1 }, () => new Array(n + 1).fill(0));
  for (let i = 0; i <= m; i++) dp[i][0] = i;
  for (let j = 0; j <= n; j++) dp[0][j] = j;
  for (let i = 1; i <= m; i++) {
    for (let j = 1; j <= n; j++) {
      dp[i][j] = a[i - 1] === b[j - 1]
        ? dp[i - 1][j - 1]
        : 1 + Math.min(dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]);
    }
  }
  return dp[m][n];
}

if (!fs.existsSync(pkgPath)) {
  console.error('[SKIP] No package.json found');
  process.exit(0);
}

const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
const deps = Object.keys(Object.assign({}, pkg.dependencies, pkg.devDependencies));

const suspects = [];
for (const dep of deps) {
  if (POPULAR.includes(dep)) continue;
  for (const popular of POPULAR) {
    if (levenshtein(dep, popular) === 1) {
      suspects.push(`${dep} (looks like typosquat of "${popular}")`);
      break;
    }
  }
}

if (suspects.length > 0) {
  console.error('[FAIL] Possible typosquatted dependencies found:');
  suspects.forEach((s) => console.error('  - ' + s));
  process.exit(1);
}
console.error('[PASS] No typosquat-suspicious dependency names found');
process.exit(0);

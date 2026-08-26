#!/usr/bin/env node
import { readdirSync, readFileSync, existsSync } from 'node:fs';
import { join, relative, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('..', import.meta.url));
const tokens = JSON.parse(readFileSync(join(root, 'design', 'tokens.json'), 'utf8'));
const tokensDart = join(root, 'lib', 'theme', 'tokens.dart');
const hits = [];

if (!existsSync(tokensDart)) {
  hits.push('lib/theme/tokens.dart: missing — every color token lives there');
} else {
  const dart = readFileSync(tokensDart, 'utf8').toUpperCase();
  for (const [name, value] of Object.entries(tokens)) {
    const needle = value.startsWith('#')
      ? `0XFF${value.slice(1).toUpperCase()}`
      : value.toUpperCase();
    if (!dart.includes(needle)) {
      hits.push(`design/tokens.json: token "${name}" value ${value} not found in lib/theme/tokens.dart`);
    }
  }
}

const SKIP = new Set(['.git', '.dart_tool', 'build', 'android', 'ios', 'windows', 'linux', 'macos', 'web']);
function* walk(dir) {
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    if (entry.isDirectory()) {
      if (SKIP.has(entry.name)) continue;
      yield* walk(join(dir, entry.name));
    } else {
      yield join(dir, entry.name);
    }
  }
}
const rel = (path) => relative(root, path).split(sep).join('/');
for (const file of walk(join(root, 'lib'))) {
  if (!file.endsWith('.dart') || file === tokensDart) continue;
  const lines = readFileSync(file, 'utf8').split(/\r?\n/);
  lines.forEach((text, index) => {
    if (/\bColor\(0x/.test(text)) {
      hits.push(`${rel(file)}:${index + 1}: raw color literal — use a Tokens value from lib/theme/tokens.dart`);
    }
    if (/\bColors\.(?!transparent\b)/.test(text)) {
      hits.push(`${rel(file)}:${index + 1}: Material Colors palette reach — use a Tokens value from lib/theme/tokens.dart`);
    }
  });
}

if (hits.length > 0) {
  console.error('check:design FAILED — design-system rules violated\n');
  for (const hit of hits) console.error(hit);
  process.exit(1);
}
console.log('check:design OK — tokens match design/tokens.json and no raw colors outside lib/theme/tokens.dart');

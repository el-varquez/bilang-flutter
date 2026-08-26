#!/usr/bin/env node
import { readdirSync, readFileSync, existsSync } from 'node:fs';
import { join, relative, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('..', import.meta.url));
const lock = JSON.parse(readFileSync(join(root, 'architecture', 'dependencies.json'), 'utf8'));
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
const hits = [];

const pubspec = readFileSync(join(root, 'pubspec.yaml'), 'utf8').split(/\r?\n/);
const sections = { dependencies: [], dev_dependencies: [] };
let current = null;
for (const line of pubspec) {
  const top = line.match(/^([a-z_]+):\s*$/);
  if (top) {
    current = top[1] in sections ? top[1] : null;
    continue;
  }
  if (/^\S/.test(line) && line.trim() !== '') current = null;
  if (!current) continue;
  const dep = line.match(/^ {2}([a-z0-9_]+):/);
  if (dep) sections[current].push(dep[1]);
}
for (const [kind, wanted] of Object.entries(lock['pubspec.yaml'])) {
  const actual = sections[kind] ?? [];
  for (const name of wanted) {
    if (!actual.includes(name)) {
      hits.push(`pubspec.yaml: R1 missing ${kind} entry "${name}" (in the lock, not the pubspec)`);
    }
  }
  for (const name of actual) {
    if (!wanted.includes(name)) {
      hits.push(`pubspec.yaml: R1 extra ${kind} entry "${name}" — if deliberate, add it to architecture/dependencies.json in the same PR`);
    }
  }
}

const features = join(root, 'lib', 'features');
const LAYERS = new Set(['screens', 'components', 'services']);
if (existsSync(features)) {
  for (const file of walk(features)) {
    const parts = relative(features, file).split(sep);
    if (parts.length < 3 || !LAYERS.has(parts[1])) {
      hits.push(`${rel(file)}: R2 breaks the slice shape — lib/features/<feature>/{screens|components|services}/<file>`);
    }
  }
  for (const file of walk(features)) {
    if (!file.endsWith('.dart')) continue;
    const own = relative(features, file).split(sep)[0];
    const lines = readFileSync(file, 'utf8').split(/\r?\n/);
    lines.forEach((text, index) => {
      const imp = text.match(/^import\s+'[^']*features\/(\w+)\//);
      if (imp && imp[1] !== own) {
        hits.push(`${rel(file)}:${index + 1}: R4 reaches into features/${imp[1]} from features/${own}`);
      }
    });
  }
}

const STATE_ALLOWLIST = new Set([
  'flutter',
  'bilang',
  'flutter_bloc',
  'bloc',
  'equatable',
]);

for (const file of walk(join(root, 'lib'))) {
  if (!file.endsWith('.dart')) continue;
  if (rel(file).split('/').includes('services')) continue;
  const lines = readFileSync(file, 'utf8').split(/\r?\n/);
  lines.forEach((text, index) => {
    const imp = text.match(/^import\s+'package:([a-z0-9_]+)\//);
    if (imp && !STATE_ALLOWLIST.has(imp[1])) {
      hits.push(`${rel(file)}:${index + 1}: R3 imports package:${imp[1]} outside a services/ folder`);
    }
  });
}

if (hits.length > 0) {
  console.error('check:architecture FAILED — bilang architecture rules violated\n');
  for (const hit of hits) console.error(hit);
  process.exit(1);
}
console.log('check:architecture OK — dependency lock, slice shape, plugin containment, feature isolation all hold');

// Merges backend/package.additions.json into backend/package.json
import fs from 'node:fs';
import path from 'node:path';

const pkgPath = path.resolve('backend/package.json');
const addPath = path.resolve('backend/package.additions.json');

if (!fs.existsSync(pkgPath) || !fs.existsSync(addPath)) {
  console.error('Missing package.json or package.additions.json in backend/');
  process.exit(1);
}

const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
const add = JSON.parse(fs.readFileSync(addPath, 'utf8'));

function mergeSection(target, src) {
  if (!src) return target;
  target = target || {};
  for (const [k, v] of Object.entries(src)) {
    target[k] = v;
  }
  return target;
}

pkg.dependencies = mergeSection(pkg.dependencies, add.dependencies);
pkg.devDependencies = mergeSection(pkg.devDependencies, add.devDependencies);
pkg.scripts = mergeSection(pkg.scripts, add.scripts);

fs.writeFileSync(pkgPath, JSON.stringify(pkg, null, 2) + '\n', 'utf8');
console.log('Merged additions into backend/package.json');

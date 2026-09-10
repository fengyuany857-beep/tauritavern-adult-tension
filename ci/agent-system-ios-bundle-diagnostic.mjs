import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';

const repoRoot = process.cwd();
const agentEntry = path.join(repoRoot, 'src', 'scripts', 'extensions', 'agent-system', 'src', 'index.js');
const bundlePath = path.join(repoRoot, 'src', 'scripts', 'extensions', 'agent-system', 'dist', 'index.bundle.js');
const readinessPath = path.join(repoRoot, 'src', 'scripts', 'extensions', 'agent-system', 'src', 'adult-tension-readiness.js');

function repoRelative(file) {
  return path.relative(repoRoot, file).replaceAll(path.sep, '/');
}

function resolveLocalImport(fromFile, specifier) {
  let candidate;
  if (specifier === '/script.js') candidate = path.join(repoRoot, 'src', 'script.js');
  else if (specifier === '/lib.js') candidate = path.join(repoRoot, 'src', 'lib.js');
  else if (specifier.startsWith('/scripts/')) candidate = path.join(repoRoot, 'src', specifier.slice(1));
  else if (specifier.startsWith('.')) candidate = path.resolve(path.dirname(fromFile), specifier);
  else return null;

  const candidates = [candidate, `${candidate}.js`, `${candidate}.mjs`, path.join(candidate, 'index.js')];
  return candidates.find((file) => fs.existsSync(file) && fs.statSync(file).isFile()) ?? null;
}

function importEdges(file) {
  const text = fs.readFileSync(file, 'utf8');
  const edges = [];
  const staticRe = /(?:import|export)\s+(?:[^'";]*?\s+from\s+)?['"]([^'"]+)['"]/g;
  const dynamicRe = /import\(\s*['"]([^'"]+)['"][^)]*\)/g;
  for (const match of text.matchAll(staticRe)) {
    const target = resolveLocalImport(file, match[1]);
    if (target) edges.push({ target, kind: 'static', specifier: match[1] });
  }
  for (const match of text.matchAll(dynamicRe)) {
    const target = resolveLocalImport(file, match[1]);
    if (!target) continue;
    const around = text.slice(Math.max(0, match.index - 80), Math.min(text.length, match.index + match[0].length + 80));
    edges.push({
      target,
      kind: around.includes('webpackIgnore: true') ? 'dynamic-webpackIgnore' : 'dynamic',
      specifier: match[1],
    });
  }
  return edges;
}

function findImportPath(targetRelative, allowedKinds = new Set(['static', 'dynamic'])) {
  const target = path.join(repoRoot, ...targetRelative.split('/'));
  const queue = [{ file: agentEntry, chain: [] }];
  const seen = new Set([agentEntry]);
  while (queue.length > 0) {
    const current = queue.shift();
    for (const edge of importEdges(current.file)) {
      if (!allowedKinds.has(edge.kind)) continue;
      const step = `${repoRelative(current.file)} --${edge.kind}:${edge.specifier}--> ${repoRelative(edge.target)}`;
      const chain = [...current.chain, step];
      if (edge.target === target) return chain;
      if (!seen.has(edge.target)) {
        seen.add(edge.target);
        queue.push({ file: edge.target, chain });
      }
    }
  }
  return null;
}

const forbiddenTargets = ['src/scripts/openai.js', 'src/scripts/extensions.js', 'src/script.js'];
for (const target of forbiddenTargets) {
  const chain = findImportPath(target);
  console.log(`[AGENT-IOS-SMOKE] forbidden-target=${target} path=${chain ? 'FOUND' : 'NOT_FOUND'}`);
  if (chain) {
    for (const step of chain) console.log(`[AGENT-IOS-SMOKE] ${step}`);
    throw new Error(`Agent System production entry pulls host runtime target ${target}`);
  }
}

const eventPath = findImportPath('src/scripts/events.js');
console.log(`[AGENT-IOS-SMOKE] events-module-path=${eventPath ? 'FOUND' : 'NOT_FOUND'}`);
if (!eventPath) throw new Error('Agent System lost its intentional thin events.js dependency');

if (!fs.existsSync(readinessPath)) throw new Error(`Adult Tension readiness source missing: ${readinessPath}`);
const readiness = fs.readFileSync(readinessPath, 'utf8');
if (/from\s+['"]\.\.\/\.\.\/\.\.\/openai\.js['"]/.test(readiness)) {
  throw new Error('Adult Tension readiness regressed to static openai.js import');
}
if (!/context\.getChatCompletionModel\(chatSettings\)/.test(readiness)) {
  throw new Error('Adult Tension readiness is not using the host context model resolver');
}

if (!fs.existsSync(bundlePath)) throw new Error(`Agent System production bundle missing: ${bundlePath}`);
const source = fs.readFileSync(bundlePath, 'utf8');
const bytes = Buffer.byteLength(source);
const sha256 = crypto.createHash('sha256').update(source).digest('hex');
const exactEqR = [...source.matchAll(/\beq\.r\b/g)].length;

console.log(`[AGENT-IOS-SMOKE] bundle-bytes=${bytes}`);
console.log(`[AGENT-IOS-SMOKE] bundle-sha256=${sha256}`);
console.log(`[AGENT-IOS-SMOKE] exact-eq-dot-r-count=${exactEqR}`);

if (bytes === 0) throw new Error('Agent System production bundle is empty');
if (exactEqR !== 0) {
  throw new Error(`Agent System production bundle contains ${exactEqR} exact eq.r sites; duplicated host-runtime regression suspected`);
}

console.log('[AGENT-IOS-SMOKE] PASS');

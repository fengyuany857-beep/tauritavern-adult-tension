import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';

const repoRoot = process.cwd();
const agentEntry = path.join(repoRoot, 'src', 'scripts', 'extensions', 'agent-system', 'src', 'index.js');
const bundlePath = path.join(repoRoot, 'src', 'scripts', 'extensions', 'agent-system', 'dist', 'index.bundle.js');

function repoRelative(file) {
  return path.relative(repoRoot, file).replaceAll(path.sep, '/');
}

function resolveLocalImport(fromFile, specifier) {
  let candidate;
  if (specifier === '/script.js') {
    candidate = path.join(repoRoot, 'src', 'script.js');
  } else if (specifier === '/lib.js') {
    candidate = path.join(repoRoot, 'src', 'lib.js');
  } else if (specifier.startsWith('/scripts/')) {
    candidate = path.join(repoRoot, 'src', specifier.slice(1));
  } else if (specifier.startsWith('.')) {
    candidate = path.resolve(path.dirname(fromFile), specifier);
  } else {
    return null;
  }

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
    if (target) {
      const around = text.slice(Math.max(0, match.index - 80), Math.min(text.length, match.index + match[0].length + 80));
      edges.push({
        target,
        kind: around.includes('webpackIgnore: true') ? 'dynamic-webpackIgnore' : 'dynamic',
        specifier: match[1],
      });
    }
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

for (const target of ['src/scripts/openai.js', 'src/scripts/extensions.js', 'src/script.js', 'src/scripts/events.js']) {
  const chain = findImportPath(target);
  console.log(`[AGENT-IOS-IMPORT] target=${target} path=${chain ? 'FOUND' : 'NOT_FOUND'}`);
  for (const step of chain ?? []) console.log(`[AGENT-IOS-IMPORT] ${step}`);
}

const readinessPath = path.join(repoRoot, 'src', 'scripts', 'extensions', 'agent-system', 'src', 'adult-tension-readiness.js');
if (fs.existsSync(readinessPath)) {
  const readiness = fs.readFileSync(readinessPath, 'utf8');
  console.log('[AGENT-IOS-IMPORT] adult-tension-readiness.js BEGIN');
  console.log(readiness);
  console.log('[AGENT-IOS-IMPORT] adult-tension-readiness.js END');
}

if (!fs.existsSync(bundlePath)) {
  throw new Error(`Agent System production bundle missing: ${bundlePath}`);
}

const source = fs.readFileSync(bundlePath, 'utf8');
const sha256 = crypto.createHash('sha256').update(source).digest('hex');
const bytes = Buffer.byteLength(source);

function compactContext(index, radius = 260) {
  const start = Math.max(0, index - radius);
  const end = Math.min(source.length, index + radius);
  return source
    .slice(start, end)
    .replaceAll('\r', '\\r')
    .replaceAll('\n', '\\n');
}

function indicesFor(re) {
  return [...source.matchAll(re)].map((match) => match.index).filter(Number.isInteger);
}

const exactEqR = indicesFor(/\beq\.r\b/g);
const eqTokens = indicesFor(/\beq\b/g);
const dotRTokens = indicesFor(/\.r\b/g);
const sourceMapMatch = source.match(/\/\/# sourceMappingURL=([^\s]+)/);

console.log(`[AGENT-IOS-DIAG] bundle=${bundlePath}`);
console.log(`[AGENT-IOS-DIAG] bytes=${bytes}`);
console.log(`[AGENT-IOS-DIAG] sha256=${sha256}`);
console.log(`[AGENT-IOS-DIAG] exact-eq-dot-r-count=${exactEqR.length}`);
console.log(`[AGENT-IOS-DIAG] eq-token-count=${eqTokens.length}`);
console.log(`[AGENT-IOS-DIAG] dot-r-count=${dotRTokens.length}`);
console.log(`[AGENT-IOS-DIAG] source-map=${sourceMapMatch?.[1] ?? 'NONE'}`);

for (const [ordinal, index] of exactEqR.slice(0, 32).entries()) {
  console.log(`[AGENT-IOS-DIAG] eq.r#${ordinal + 1} index=${index} context=${compactContext(index)}`);
}

if (exactEqR.length === 0) {
  for (const [ordinal, index] of eqTokens.slice(0, 24).entries()) {
    console.log(`[AGENT-IOS-DIAG] eq#${ordinal + 1} index=${index} context=${compactContext(index)}`);
  }
}

for (const [ordinal, index] of dotRTokens.slice(0, 12).entries()) {
  console.log(`[AGENT-IOS-DIAG] .r#${ordinal + 1} index=${index} context=${compactContext(index, 180)}`);
}

if (bytes === 0) {
  throw new Error('Agent System production bundle is empty');
}

console.log('[AGENT-IOS-DIAG] CAPTURE_COMPLETE');

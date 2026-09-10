import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';

const repoRoot = process.cwd();
const bundlePath = path.join(repoRoot, 'src', 'scripts', 'extensions', 'agent-system', 'dist', 'index.bundle.js');

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

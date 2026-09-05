import { mkdir, readFile, rm, writeFile } from 'node:fs/promises';
import { spawnSync } from 'node:child_process';

const root = new URL('../', import.meta.url).pathname;
const dist = new URL('../dist/', import.meta.url).pathname;
const candidates = [process.env.GODOT_BIN, 'godot4', 'godot'].filter(Boolean);
let executable;
for (const candidate of candidates) {
  const probe = spawnSync(candidate, ['--version'], { encoding: 'utf8' });
  if (probe.status === 0) {
    executable = candidate;
    break;
  }
}
if (!executable) throw new Error('Godot 4.3 is required. Set GODOT_BIN or install the godot executable.');
await rm(dist, { recursive: true, force: true });
await mkdir(dist, { recursive: true });
const result = spawnSync(executable, ['--headless', '--path', root, '--export-release', 'Web', `${dist}index.html`], { stdio: 'inherit' });
if (result.status !== 0) process.exit(result.status ?? 1);

const partSize = 16 * 1024 * 1024;
async function splitReleaseFile(filename) {
  const source = await readFile(`${dist}${filename}`);
  const parts = [];
  for (let offset = 0, part = 0; offset < source.length; offset += partSize, part += 1) {
    const partName = `${filename}.part${part}`;
    await writeFile(`${dist}${partName}`, source.subarray(offset, Math.min(offset + partSize, source.length)));
    parts.push(partName);
  }
  await rm(`${dist}${filename}`);
  return { parts, size: source.length };
}

// Static hosts commonly cap individual files at 25 MB. Reassemble Godot's
// runtime and data pack through a fetch shim while keeping every artifact
// comfortably below that limit.
const wasmRelease = await splitReleaseFile('index.wasm');
const packRelease = await splitReleaseFile('index.pck');

const htmlPath = `${dist}index.html`;
let html = await readFile(htmlPath, 'utf8');
const loaderTag = '\t\t<script src="index.js"></script>';
if (!html.includes(loaderTag)) throw new Error('Could not find the Godot loader tag in index.html.');
const fetchShim = `\t\t<script>\n` +
`const JELLY_CHUNKED_FILES = ${JSON.stringify({ 'index.wasm': wasmRelease.parts, 'index.pck': packRelease.parts })};\n` +
`const jellyNativeFetch = window.fetch.bind(window);\n` +
`window.fetch = async function (input, init) {\n` +
`  const requestUrl = typeof input === 'string' ? input : input.url;\n` +
`  const resolved = new URL(requestUrl, window.location.href);\n` +
`  const filename = resolved.pathname.split('/').pop();\n` +
`  const parts = JELLY_CHUNKED_FILES[filename];\n` +
`  if (!parts) return jellyNativeFetch(input, init);\n` +
`  const responses = await Promise.all(parts.map((part) => jellyNativeFetch(new URL(part, resolved), { credentials: 'same-origin' })));\n` +
`  const failed = responses.find((response) => !response.ok);\n` +
`  if (failed) return failed;\n` +
`  const buffers = await Promise.all(responses.map((response) => response.arrayBuffer()));\n` +
`  const total = buffers.reduce((size, buffer) => size + buffer.byteLength, 0);\n` +
`  const merged = new Uint8Array(total);\n` +
`  let cursor = 0;\n` +
`  for (const buffer of buffers) { merged.set(new Uint8Array(buffer), cursor); cursor += buffer.byteLength; }\n` +
`  const type = filename.endsWith('.wasm') ? 'application/wasm' : 'application/octet-stream';\n` +
`  return new Response(merged, { headers: { 'Content-Type': type, 'Content-Length': String(total) } });\n` +
`};\n` +
`\t\t</script>`;
html = html.replace(loaderTag, `${fetchShim}\n${loaderTag}`);
await writeFile(htmlPath, html);

const workerPath = `${dist}index.service.worker.js`;
let worker = await readFile(workerPath, 'utf8');
worker = worker.replace(
  /const CACHE_PREFIX = '(.*)';/,
  (_, prefix) => `const CACHE_PREFIX = ${JSON.stringify(prefix)};`,
);
worker = worker.replace(
  /const CACHABLE_FILES = .*;/,
  `const CACHABLE_FILES = ${JSON.stringify([...wasmRelease.parts, ...packRelease.parts])};`,
);
await writeFile(workerPath, worker);

console.log(`Exported Jelly's Journey with ${executable}.`);
console.log(`Split the ${wasmRelease.size}-byte WebAssembly runtime into ${wasmRelease.parts.length} host-safe parts.`);
console.log(`Split the ${packRelease.size}-byte game pack into ${packRelease.parts.length} host-safe parts.`);

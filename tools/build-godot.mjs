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

// Static hosts commonly cap individual files at 25 MiB, while Godot's Web
// runtime is larger. Ship it in 16 MiB pieces and reassemble it through a
// tiny fetch shim before Godot's loader requests index.wasm.
const wasmPath = `${dist}index.wasm`;
const wasm = await readFile(wasmPath);
const partSize = 16 * 1024 * 1024;
const wasmParts = [];
for (let offset = 0, part = 0; offset < wasm.length; offset += partSize, part += 1) {
  const filename = `index.wasm.part${part}`;
  await writeFile(`${dist}${filename}`, wasm.subarray(offset, Math.min(offset + partSize, wasm.length)));
  wasmParts.push(filename);
}
await rm(wasmPath);

const htmlPath = `${dist}index.html`;
let html = await readFile(htmlPath, 'utf8');
const loaderTag = '\t\t<script src="index.js"></script>';
if (!html.includes(loaderTag)) throw new Error('Could not find the Godot loader tag in index.html.');
const fetchShim = `\t\t<script>\n` +
`const JELLY_WASM_PARTS = ${JSON.stringify(wasmParts)};\n` +
`const jellyNativeFetch = window.fetch.bind(window);\n` +
`window.fetch = async function (input, init) {\n` +
`  const requestUrl = typeof input === 'string' ? input : input.url;\n` +
`  const resolved = new URL(requestUrl, window.location.href);\n` +
`  if (!resolved.pathname.endsWith('/index.wasm')) return jellyNativeFetch(input, init);\n` +
`  const responses = await Promise.all(JELLY_WASM_PARTS.map((part) => jellyNativeFetch(new URL(part, resolved), { credentials: 'same-origin' })));\n` +
`  const failed = responses.find((response) => !response.ok);\n` +
`  if (failed) return failed;\n` +
`  const buffers = await Promise.all(responses.map((response) => response.arrayBuffer()));\n` +
`  const total = buffers.reduce((size, buffer) => size + buffer.byteLength, 0);\n` +
`  const merged = new Uint8Array(total);\n` +
`  let cursor = 0;\n` +
`  for (const buffer of buffers) { merged.set(new Uint8Array(buffer), cursor); cursor += buffer.byteLength; }\n` +
`  return new Response(merged, { headers: { 'Content-Type': 'application/wasm', 'Content-Length': String(total) } });\n` +
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
  `const CACHABLE_FILES = ${JSON.stringify([...wasmParts, 'index.pck'])};`,
);
await writeFile(workerPath, worker);

console.log(`Exported Jelly's Journey with ${executable}.`);
console.log(`Split the ${wasm.length}-byte WebAssembly runtime into ${wasmParts.length} host-safe parts.`);

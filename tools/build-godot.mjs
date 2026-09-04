import { mkdir, rm } from 'node:fs/promises';
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
console.log(`Exported Jelly's Journey with ${executable}.`);


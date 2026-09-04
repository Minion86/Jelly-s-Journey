import { copyFile, cp, mkdir } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const projectRoot = dirname(dirname(fileURLToPath(import.meta.url)));
const sourceRoot = join(projectRoot, 'src');
const outputRoot = join(projectRoot, 'dist');
const sourceAssets = join(projectRoot, 'assets');
const outputAssets = join(outputRoot, 'assets');

const sourceFiles = [
  'index.html',
  'style.css',
  'level-data.js',
  'game-v2.js',
  'manifest.webmanifest',
  'sw.js'
];

await mkdir(outputRoot, { recursive: true });
await Promise.all(sourceFiles.map(file =>
  copyFile(join(sourceRoot, file), join(outputRoot, file))
));
await cp(sourceAssets, outputAssets, { recursive: true, force: true });

console.log(`Built ${sourceFiles.length} source files and copied game assets to dist/.`);

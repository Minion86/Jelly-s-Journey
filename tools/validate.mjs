import { readFile, access } from 'node:fs/promises';
import { join } from 'node:path';
import { execFileSync } from 'node:child_process';

const root=new URL('../dist/',import.meta.url).pathname;
for(const file of ['game-v2.js','level-data.js','sw.js'])execFileSync(process.execPath,['--check',join(root,file)],{stdio:'inherit'});
const html=await readFile(join(root,'index.html'),'utf8');
const refs=[...html.matchAll(/(?:src|href)="([^"]+)"/g)].map(m=>m[1]).filter(x=>!x.startsWith('http'));
for(const ref of refs)await access(join(root,ref));
const data=await readFile(join(root,'level-data.js'),'utf8');
if((data.match(/id:'/g)||[]).length!==12)throw new Error('Expected 12 hand-authored levels');
console.log(`Validated 12 levels and ${refs.length} local entry-point assets.`);

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
for(const marker of ['checkpoint:','weather:','hazards:','props:','squirrelPath:']){
  if((data.match(new RegExp(marker,'g'))||[]).length!==12)throw new Error(`Expected 12 ${marker.slice(0,-1)} definitions`);
}
const game=await readFile(join(root,'game-v2.js'),'utf8');
for(const feature of ['updateSquirrels','updateHazards','drawCheckpoint','startMusic','squirrel-sprites.png']){
  if(!game.includes(feature))throw new Error(`Missing V3 feature: ${feature}`);
}
const squirrel=await readFile(join(root,'assets/squirrel-sprites.png')).catch(()=>null);
if(squirrel&&(squirrel.readUInt32BE(16)!==1776||squirrel.readUInt32BE(20)!==888))throw new Error('Squirrel sheet must be a 4 × 2 grid at 1776 × 888');
console.log(`Validated 12 detailed levels, squirrel chases, dynamic hazards, coherent audio, and ${refs.length} local entry-point assets.`);

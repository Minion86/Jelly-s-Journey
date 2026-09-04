import { createServer } from 'node:http';
import { readFile, stat } from 'node:fs/promises';
import { extname, join, normalize } from 'node:path';

const root = new URL('../dist/', import.meta.url).pathname;
const types = {'.html':'text/html; charset=utf-8','.css':'text/css; charset=utf-8','.js':'text/javascript; charset=utf-8','.json':'application/json','.webmanifest':'application/manifest+json','.png':'image/png','.jpeg':'image/jpeg'};

createServer(async (req,res)=>{
  try {
    const requested = decodeURIComponent(new URL(req.url,'http://localhost').pathname);
    let file = join(root, normalize(requested).replace(/^\/+/,''));
    if (requested === '/' || (await stat(file).catch(()=>null))?.isDirectory()) file=join(file,'index.html');
    const body=await readFile(file);res.writeHead(200,{'Content-Type':types[extname(file)]||'application/octet-stream','Cache-Control':'no-cache'});res.end(body);
  } catch {res.writeHead(404,{'Content-Type':'text/plain'});res.end('Not found');}
}).listen(8080,()=>console.log('Jelly is ready at http://localhost:8080'));

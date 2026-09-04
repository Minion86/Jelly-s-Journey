const CACHE='jelly-journey-v3';
const FILES=['./','./index.html','./style.css','./level-data.js','./game-v2.js','./manifest.webmanifest','https://jellys-journey-home.nelsonmartinez86.chatgpt.site/assets/jelly-sprites.png','https://jellys-journey-home.nelsonmartinez86.chatgpt.site/assets/city-enemies.png','https://jellys-journey-home.nelsonmartinez86.chatgpt.site/assets/squirrel-sprites.png','https://jellys-journey-home.nelsonmartinez86.chatgpt.site/assets/jelly-icon.png','https://jellys-journey-home.nelsonmartinez86.chatgpt.site/assets/family.jpeg'];
self.addEventListener('install',e=>e.waitUntil(caches.open(CACHE).then(c=>c.addAll(FILES))));
self.addEventListener('activate',e=>e.waitUntil(caches.keys().then(k=>Promise.all(k.filter(x=>x!==CACHE).map(x=>caches.delete(x))))));
self.addEventListener('fetch',e=>e.respondWith(caches.match(e.request).then(r=>r||fetch(e.request))));

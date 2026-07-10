const CACHE = 'studyhub-v3';
const APPS = ['highlights','chess','poker','spanish','vaya','two-selves','poietism','doomsday',
  'animal-book','poietism-pamphlet','poietism-paper','koin','koin-pamphlet','koin-essential','koin-kids',
  'transformation-map','portfolio-planner','spacex-invest','spacex-pto','hex',
  'life','evolution','voronoi','math-neural','math-spreading','math-predictor','math-kuramoto',
  'math-reaction','math-sandpile','math-percolation','math-galton','math-globe','math-language-evolution','math-annealing'];
const ASSETS = [
  './', './index.html', './manifest.webmanifest', './routes.json',
  './icon-180.png', './icon-192.png', './icon-512.png'
].concat(APPS.map(a => './apps/' + a + '.html'));

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c =>
    Promise.allSettled(ASSETS.map(u => c.add(u)))   // don't fail install if one asset 404s
  ).then(() => self.skipWaiting()));
});
self.addEventListener('activate', e => {
  e.waitUntil(caches.keys().then(ks => Promise.all(ks.filter(k => k !== CACHE).map(k => caches.delete(k)))).then(() => self.clients.claim()));
});
self.addEventListener('fetch', e => {
  if (e.request.method !== 'GET') return;
  const url = new URL(e.request.url);
  if (url.origin !== location.origin) return;   // don't intercept PEP-server / external links
  e.respondWith(caches.match(e.request).then(hit => hit || fetch(e.request).catch(() => caches.match('./index.html'))));
});

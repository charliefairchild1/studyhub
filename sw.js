const CACHE = 'studyhub-v13';
const APPS = ['highlights','praxa','cartographer','journal','habits','terminal','chess','poker','spanish','vaya','action','polymath','mathematics','logic','two-selves','ethics','gauntlet','poietism','doomsday',
  'animal-book','animal-essay','poietism-pamphlet','poietism-paper','poietism-naming',
  'koin','koin-welcome','koin-pamphlet','koin-essential','koin-teaching','koin-kids',
  'transformation-map','portfolio-planner','spacex-invest','spacex-pto','hex',
  'life','evolution','voronoi','math-neural','math-spreading','math-predictor','math-kuramoto',
  'math-reaction','math-sandpile','math-percolation','math-galton','math-globe','math-language-evolution','math-annealing',
  'math-bayes','math-entropy','math-diffusion','math-network','math-gradient','math-fourier','math-epidemic',
  'math-pendulum','math-attractor','math-cycles','math-markov','math-mcmc','math-gp','math-novelty','math-haze','math-modulation'];
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
  // HTML (the hub shell + app pages) = NETWORK-FIRST so updates show immediately when online;
  // fall back to cache offline. Everything else = cache-first for speed.
  const isHTML = e.request.mode === 'navigate' || url.pathname.endsWith('.html') || url.pathname.endsWith('/');
  if (isHTML) {
    e.respondWith(
      fetch(e.request).then(r => { const cp = r.clone(); caches.open(CACHE).then(c => c.put(e.request, cp)); return r; })
        .catch(() => caches.match(e.request).then(h => h || caches.match('./index.html')))
    );
  } else {
    e.respondWith(caches.match(e.request).then(hit => hit || fetch(e.request)));
  }
});

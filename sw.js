/* SELF-DESTRUCT service worker.
   Older versions of this SW cached a broken app shell and got stuck on some phones,
   showing a black screen. This version takes over, deletes ALL caches, unregisters
   itself, and reloads every open tab to the live network site. After this runs once,
   the app is a plain, reliable website with no service worker. */
self.addEventListener('install', function(e){ self.skipWaiting(); });
self.addEventListener('activate', function(e){
  e.waitUntil((async function(){
    try{
      const keys = await caches.keys();
      await Promise.all(keys.map(function(k){ return caches.delete(k); }));
    }catch(err){}
    try{ await self.registration.unregister(); }catch(err){}
    try{
      const clients = await self.clients.matchAll({ type:'window' });
      clients.forEach(function(c){ try{ c.navigate(c.url); }catch(err){} });
    }catch(err){}
  })());
});
/* No fetch handler on purpose: every request goes straight to the network. */

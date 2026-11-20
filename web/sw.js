'use strict';

// Makes the app open fast and work offline.
//
// Cache first: every open is served from this device's copy of the current
// release, without waiting on the network. Each release has its own cache,
// named after the build number that the deploy writes over __RELEASE__.
// When a release is deployed, sw.js changes, so the browser installs this
// worker again in the background: it downloads the new release of every file
// the old cache held, then replaces the old cache. The open after that
// shows the new release.
const CACHE = 'roll-the-dice-__RELEASE__';

self.addEventListener('install', (event) => {
  event.waitUntil(
    (async () => {
      const urls = new Set(['./', 'index.html']);
      for (const key of await caches.keys()) {
        if (key === CACHE) continue;
        const old = await caches.open(key);
        for (const request of await old.keys()) {
          if (request.url.startsWith(self.location.origin)) urls.add(request.url);
        }
      }
      const cache = await caches.open(CACHE);
      // Bypass the HTTP cache so the new release isn't mixed with old files.
      // If a download fails (offline, flaky network), the install fails, the
      // old release stays, and the browser tries again on a later open.
      // A file the new release no longer has (404) is just left out.
      await Promise.all(
        [...urls].map(async (url) => {
          const response = await fetch(new Request(url, { cache: 'reload' }));
          if (response.ok) await cache.put(url, response);
          else if (response.status !== 404) throw new Error(`${url}: ${response.status}`);
        }),
      );
      await self.skipWaiting();
    })(),
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      const keys = await caches.keys();
      await Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k)));
      await self.clients.claim();
    })(),
  );
});

// The page sends the files it loaded before this worker took control,
// so the first visit is cached too.
self.addEventListener('message', (event) => {
  if (event.data?.type !== 'cache') return;
  event.waitUntil(
    (async () => {
      const cache = await caches.open(CACHE);
      for (const url of event.data.urls) {
        if (!url.startsWith(self.location.origin) || (await cache.match(url))) continue;
        try {
          const response = await fetch(url);
          if (response.ok) await cache.put(url, response);
        } catch (e) {
          // Offline or gone: it is cached on a later visit.
        }
      }
    })(),
  );
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET' || !request.url.startsWith(self.location.origin)) return;
  event.respondWith(
    (async () => {
      const cache = await caches.open(CACHE);
      const cached = await cache.match(request, { ignoreSearch: true });
      if (cached) return cached;
      try {
        const response = await fetch(request);
        if (response.ok) cache.put(request, response.clone());
        return response;
      } catch (e) {
        if (request.mode === 'navigate') {
          const shell = await cache.match('index.html');
          if (shell) return shell;
        }
        throw e;
      }
    })(),
  );
});

{{flutter_js}}
{{flutter_build_config}}

// Load without Flutter's deprecated service worker: it unregisters itself,
// which would also remove ours (sw.js, registered in index.html).
_flutter.loader.load();

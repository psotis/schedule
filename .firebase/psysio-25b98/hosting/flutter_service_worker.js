'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter_bootstrap.js": "134269c46138eeff6bb2355f29113229",
"version.json": "d2390afa22d4944ddf0daf977e23e0ea",
"index.html": "4c4d2509b9570b9619830fee44011f9e",
"/": "4c4d2509b9570b9619830fee44011f9e",
"main.dart.js": "fb9018a6b9f8814992ce66d6eb9caacf",
"flutter.js": "83d881c1dbb6d6bcd6b42e274605b69c",
"favicon.png": "ab5528423b6aefa326270574e98cc50f",
"icons/Icon-192.png": "270242b187ab240034624f55e2b618c1",
"icons/Icon-maskable-192.png": "270242b187ab240034624f55e2b618c1",
"icons/Icon-maskable-512.png": "7ccc4ecf5c1c7edd836bebc8d72ef959",
"icons/Icon-512.png": "7ccc4ecf5c1c7edd836bebc8d72ef959",
"manifest.json": "9a8a13163489defdd9df38af65dc5520",
"assets/AssetManifest.json": "019860552d9385f1d71cca960039c0e9",
"assets/NOTICES": "90a03cf9f3dc79a019fcc3caa6f0d75d",
"assets/FontManifest.json": "6a84e6c28a318c1ef29352d8cf66d39c",
"assets/AssetManifest.bin.json": "c66e8a191e02982949cdb60941f8b88f",
"assets/packages/material_design_icons_flutter/lib/fonts/materialdesignicons-webfont.ttf": "d10ac4ee5ebe8c8fff90505150ba2a76",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "b93248a553f9e8bc17f1065929d5934b",
"assets/packages/timezone/data/latest_all.tzf": "df0e82dd729bbaca78b2aa3fd4efd50d",
"assets/packages/font_awesome_flutter/lib/fonts/fa-solid-900.ttf": "a2eb084b706ab40c90610942d98886ec",
"assets/packages/font_awesome_flutter/lib/fonts/fa-regular-400.ttf": "3ca5dc7621921b901d513cc1ce23788c",
"assets/packages/font_awesome_flutter/lib/fonts/fa-brands-400.ttf": "4769f3245a24c1fa9965f113ea85ec2a",
"assets/packages/sign_in_button/assets/logos/google_dark.png": "d18b748c2edbc5c4e3bc221a1ec64438",
"assets/packages/sign_in_button/assets/logos/google_light.png": "f71e2d0b0a2bc7d1d8ab757194a02cac",
"assets/packages/sign_in_button/assets/logos/2.0x/google_dark.png": "68d675bc88e8b2a9079fdfb632a974aa",
"assets/packages/sign_in_button/assets/logos/2.0x/google_light.png": "1f00e2bbc0c16b9e956bafeddebe7bf2",
"assets/packages/sign_in_button/assets/logos/2.0x/facebook_new.png": "dd8e500c6d946b0f7c24eb8b94b1ea8c",
"assets/packages/sign_in_button/assets/logos/3.0x/google_dark.png": "c75b35db06cb33eb7c52af696026d299",
"assets/packages/sign_in_button/assets/logos/3.0x/google_light.png": "3aeb09c8261211cfc16ac080a555c43c",
"assets/packages/sign_in_button/assets/logos/3.0x/facebook_new.png": "689ce8e0056bb542425547325ce690ba",
"assets/packages/sign_in_button/assets/logos/facebook_new.png": "93cb650d10a738a579b093556d4341be",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin": "cd9973c70cc292537721af07c078c412",
"assets/fonts/MaterialIcons-Regular.otf": "e7069dfd19b331be16bed984668fe080",
"assets/assets/schedule.gif": "a2755a42d2448eb95937fcf8c0f8513f",
"assets/assets/add_customer.png": "823b7434ea7c4bf0d25691e867e614bd",
"assets/assets/add_appointment.png": "321ec2ea5e0fd4e110205cdaae813468",
"assets/assets/back1.jpeg": "1000f3b532f6487ac31ba578c71b5638",
"assets/assets/back2.jpeg": "566907418d49e2c789fe7bd90d167dc6",
"assets/assets/logo_web.png": "8461ccb9a7c19150183fe3cc59958960",
"assets/assets/back3.jpeg": "538e18fd21af418afa139401538e410f",
"assets/assets/google_fonts/ibm_plex_sans/IBMPlexSans-SemiBoldItalic.ttf": "c7e16f251b21174781a036ecc37fb301",
"assets/assets/google_fonts/ibm_plex_sans/IBMPlexSans-Medium.ttf": "361336a2ed1908c5cd8dec2e10aa71a2",
"assets/assets/google_fonts/ibm_plex_sans/IBMPlexSans-SemiBold.ttf": "3ea7eea66304ac5e02a95265505300fd",
"assets/assets/google_fonts/ibm_plex_sans/IBMPlexSans-MediumItalic.ttf": "77fbc569f8e2c0cecd7d1317eba8cce8",
"assets/assets/google_fonts/ibm_plex_sans/OFL.txt": "9309839bb3892d6e429009cb8c29fb75",
"assets/assets/google_fonts/ibm_plex_sans/IBMPlexSans-LightItalic.ttf": "f059e141654e87fe1ec2180873970da7",
"assets/assets/google_fonts/ibm_plex_sans/IBMPlexSans-ExtraLight.ttf": "4362bbf9009288efcbd3130c5ac8f671",
"assets/assets/google_fonts/ibm_plex_sans/IBMPlexSans-Thin.ttf": "6dcbea439f36a796c36e5197a527c8a1",
"assets/assets/google_fonts/ibm_plex_sans/IBMPlexSans-ThinItalic.ttf": "9823c5872a073bda1d37e35b8d518912",
"assets/assets/google_fonts/ibm_plex_sans/IBMPlexSans-BoldItalic.ttf": "5c7054fd77f5371213e6bd40ba413007",
"assets/assets/google_fonts/ibm_plex_sans/IBMPlexSans-Light.ttf": "abcc0987be49b417483f65063f144e4a",
"assets/assets/google_fonts/ibm_plex_sans/IBMPlexSans-Italic.ttf": "291a8d32d7596f69509713e0d31e1eb7",
"assets/assets/google_fonts/ibm_plex_sans/IBMPlexSans-Regular.ttf": "1286abb632c5a409a0a997d11c994e34",
"assets/assets/google_fonts/ibm_plex_sans/IBMPlexSans-ExtraLightItalic.ttf": "d09511dbf61a5625e6296f7e536b7dd3",
"assets/assets/google_fonts/ibm_plex_sans/IBMPlexSans-Bold.ttf": "1ae7d0a8e83337da66631aeca59fbb02",
"canvaskit/skwasm.js": "ea559890a088fe28b4ddf70e17e60052",
"canvaskit/skwasm.js.symbols": "e72c79950c8a8483d826a7f0560573a1",
"canvaskit/canvaskit.js.symbols": "bdcd3835edf8586b6d6edfce8749fb77",
"canvaskit/skwasm.wasm": "39dd80367a4e71582d234948adc521c0",
"canvaskit/chromium/canvaskit.js.symbols": "b61b5f4673c9698029fa0a746a9ad581",
"canvaskit/chromium/canvaskit.js": "8191e843020c832c9cf8852a4b909d4c",
"canvaskit/chromium/canvaskit.wasm": "f504de372e31c8031018a9ec0a9ef5f0",
"canvaskit/canvaskit.js": "728b2d477d9b8c14593d4f9b82b484f3",
"canvaskit/canvaskit.wasm": "7a3f4ae7d65fc1de6a6e7ddd3224bc93"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}

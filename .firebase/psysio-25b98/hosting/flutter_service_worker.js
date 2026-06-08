'use strict';

const RESOURCES = {"flutter_bootstrap.js": "20a91cb0204c6ed42d6500c0b7ea5a2d",
"version.json": "d2390afa22d4944ddf0daf977e23e0ea",
"index.html": "76a0672b37abfb76f5deee984cbc06b1",
"/": "76a0672b37abfb76f5deee984cbc06b1",
"main.dart.js": "7e3db24d7ccf92d82ec4d4cbb6550d6c",
"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"favicon.png": "ab5528423b6aefa326270574e98cc50f",
"icons/Icon-192.png": "270242b187ab240034624f55e2b618c1",
"icons/Icon-maskable-192.png": "270242b187ab240034624f55e2b618c1",
"icons/Icon-maskable-512.png": "7ccc4ecf5c1c7edd836bebc8d72ef959",
"icons/Icon-512.png": "7ccc4ecf5c1c7edd836bebc8d72ef959",
"manifest.json": "9a8a13163489defdd9df38af65dc5520",
"assets/AssetManifest.json": "019860552d9385f1d71cca960039c0e9",
"assets/NOTICES": "7255f442ff91ccd4b132808be5e8a415",
"assets/FontManifest.json": "d4ac2da48b0bb932dd1ca579aa8e0aab",
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
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
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
"canvaskit/skwasm.js": "8060d46e9a4901ca9991edd3a26be4f0",
"canvaskit/skwasm_heavy.js": "740d43a6b8240ef9e23eed8c48840da4",
"canvaskit/skwasm.js.symbols": "3a4aadf4e8141f284bd524976b1d6bdc",
"canvaskit/canvaskit.js.symbols": "a3c9f77715b642d0437d9c275caba91e",
"canvaskit/skwasm_heavy.js.symbols": "0755b4fb399918388d71b59ad390b055",
"canvaskit/skwasm.wasm": "7e5f3afdd3b0747a1fd4517cea239898",
"canvaskit/chromium/canvaskit.js.symbols": "e2d09f0e434bc118bf67dae526737d07",
"canvaskit/chromium/canvaskit.js": "a80c765aaa8af8645c9fb1aae53f9abf",
"canvaskit/chromium/canvaskit.wasm": "a726e3f75a84fcdf495a15817c63a35d",
"canvaskit/canvaskit.js": "8331fe38e66b3a898c4f37648aaf7ee2",
"canvaskit/canvaskit.wasm": "9b6a7830bf26959b200594729d73538e",
"canvaskit/skwasm_heavy.wasm": "b0be7910760d205ea4e011458df6ee01"};
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
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      try {
        await self.registration.unregister();
      } catch (e) {
        console.warn('Failed to unregister the service worker:', e);
      }

      try {
        const clients = await self.clients.matchAll({
          type: 'window',
        });
        // Reload clients to ensure they are not using the old service worker.
        clients.forEach((client) => {
          if (client.url && 'navigate' in client) {
            client.navigate(client.url);
          }
        });
      } catch (e) {
        console.warn('Failed to navigate some service worker clients:', e);
      }
    })()
  );
});

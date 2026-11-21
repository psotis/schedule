(() => {
  'use strict';

  async function startApp() {
    try {
      // Retire only Flutter's legacy offline cache; preserve authentication storage.
      if ('serviceWorker' in navigator) {
        const registrations = await navigator.serviceWorker.getRegistrations();
        await Promise.all(registrations.filter((registration) =>
          [registration.active, registration.waiting, registration.installing].some((worker) =>
            worker && new URL(worker.scriptURL).pathname.endsWith('/flutter_service_worker.js'))
        ).map((registration) => registration.unregister()));
      }
      if ('caches' in window) {
        await Promise.all(['flutter-app-cache', 'flutter-temp-cache', 'flutter-app-manifest']
          .map((name) => caches.delete(name)));
      }
    } catch (_) {
      // Cache cleanup must not prevent the app from opening.
    }
    const bootstrap = document.createElement('script');
    bootstrap.src = 'flutter_bootstrap.js';
    bootstrap.async = true;
    bootstrap.onerror = () => {
      const loading = document.getElementById('app-loading');
      loading?.classList.add('app-load-error');
      document.getElementById('app-status').textContent = 'Η εφαρμογή δεν φορτώθηκε. Ελέγξτε τη σύνδεσή σας και δοκιμάστε ξανά.';
      const retry = document.createElement('button');
      retry.type = 'button';
      retry.textContent = 'Δοκιμή ξανά';
      retry.addEventListener('click', () => location.reload());
      loading?.firstElementChild.append(retry);
    };
    document.body.append(bootstrap);
  }

  if (document.documentElement.classList.contains('app-mode')) {
    startApp();
    return;
  }

  const nav = document.getElementById('main-nav');
  const toggle = document.querySelector('.menu-toggle');
  function closeMenu() {
    nav.classList.remove('menu-open');
    toggle.setAttribute('aria-expanded', 'false');
    toggle.setAttribute('aria-label', 'Άνοιγμα μενού');
  }
  toggle.addEventListener('click', () => {
    const open = toggle.getAttribute('aria-expanded') !== 'true';
    nav.classList.toggle('menu-open', open);
    toggle.setAttribute('aria-expanded', String(open));
    toggle.setAttribute('aria-label', open ? 'Κλείσιμο μενού' : 'Άνοιγμα μενού');
  });
  nav.addEventListener('click', (event) => {
    if (event.target.closest('a')) closeMenu();
  });
  document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape' && toggle.getAttribute('aria-expanded') === 'true') {
      closeMenu();
      toggle.focus();
    }
  });
  document.addEventListener('click', (event) => {
    if (!event.target.closest('.site-header')) closeMenu();
  });
  document.getElementById('copyright-year').textContent = String(new Date().getFullYear());
})();

{{flutter_js}}
{{flutter_build_config}}

// Кастомный загрузчик с поддержкой офлайн-режима.
//
// Проблема по умолчанию: Flutter PWA использует стратегию onlineFirst —
// при каждом открытии пытается получить свежую версию service worker из сети.
// Если сеть недоступна и браузер считает кеш устаревшим — приложение не загружается.
//
// Решение: timeoutMillis — максимальное время ожидания сети.
// Если за 3 секунды сеть не ответила, загрузчик использует кешированную версию.
// Это гарантирует работу PWA в офлайне после первой установки.

_flutter.loader.load({
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}},
    timeoutMillis: 3000,
  },
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
  },
});

# 🌤 Погода

Кросс-платформенное приложение погоды на Flutter. Работает на Android, iOS, Web (PWA), Windows, macOS и Linux без регистрации и API-ключей.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.4+-0175C2?logo=dart)
![License](https://img.shields.io/badge/License-MIT-green)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Windows%20%7C%20macOS%20%7C%20Linux-lightgrey)

---

## Скриншоты

> *(добавьте скриншоты приложения)*

---

## Возможности

- 🌡 **Текущая погода** — температура, ощущаемая, влажность, ветер, давление, УФ-индекс, осадки
- 🕐 **Почасовой прогноз** — 25 слотов от текущего момента
- 📅 **7-дневный прогноз** — мин/макс температура с визуальной шкалой диапазона
- 🔍 **Поиск города** — любой город мира с дебаунсом
- 📍 **GPS-геолокация** — определение текущего местоположения
- 🗂 **Офлайн-режим** — кэш последних данных при отсутствии сети
- 🖼 **Нативные виджеты** — 3 размера для Android и iOS (Small / Medium / Large)
- 🔄 **Фоновое обновление** — WorkManager (Android) и BGTaskScheduler (iOS)
- ⚡ **Кнопка обновления на виджете** — без открытия приложения
- ⚙️ **Настройки единиц** — °C / °F, м/с / км/ч / mph, мм рт.ст. / гПа
- 🌙 **Темы** — светлая, тёмная, системная (Material 3)
- 📱 **PWA** — устанавливается как приложение из браузера

---

## Платформы

| Платформа | Погода | Геолокация | Виджеты | Фоновый рефреш |
|-----------|--------|------------|---------|----------------|
| Android   | ✅     | ✅         | ✅ (3)  | ✅ WorkManager |
| iOS       | ✅     | ✅         | ✅ (3)  | ✅ BGTask      |
| Web (PWA) | ✅     | ✅         | —       | —              |
| Windows   | ✅     | ✅         | —       | —              |
| macOS     | ✅     | ✅         | —       | —              |
| Linux     | ✅     | —          | —       | —              |

---

## Стек технологий

| Слой | Технология |
|------|------------|
| Фреймворк | Flutter 3.x, Dart 3.4+ |
| State management | Provider + ChangeNotifier |
| API погоды | [Open-Meteo](https://open-meteo.com) (бесплатно, без ключа) |
| Геокодинг | [Open-Meteo Geocoding](https://geocoding-api.open-meteo.com) + [Nominatim](https://nominatim.org) |
| Нативные виджеты | home_widget 0.7.0 |
| Фоновые задачи | workmanager 0.5.x |
| Геолокация | geolocator 13.x |
| Android workers | Kotlin + WorkManager |
| iOS widgets | Swift + WidgetKit + AppIntent |

---

## Установка и запуск

### Требования

- Flutter SDK 3.x ([установка](https://docs.flutter.dev/get-started/install))
- Dart 3.4+
- Android SDK (для Android)
- Xcode 15+ (для iOS / macOS)

### Клонирование и запуск

```bash
git clone https://github.com/ВАШ_НИК/weather_app.git
cd weather_app
flutter pub get
flutter run
```

### Сборка под конкретную платформу

```bash
# Android
flutter build apk --release
# или AAB для Google Play:
flutter build appbundle --release

# iOS
flutter build ipa --release

# Web (PWA)
flutter build web --release --web-renderer auto --base-href "/"

# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release
```

---

## Настройка iOS (обязательно перед сборкой)

1. Открыть проект в Xcode: `open ios/Runner.xcworkspace`
2. Для обоих таргетов **Runner** и **WeatherWidgetExtension**:
   - Signing & Capabilities → **+** → App Groups
   - Добавить: `group.ru.matveyb9.test.weatherapp`
3. Убедиться что в `Info.plist` есть:
   ```xml
   <key>BGTaskSchedulerPermittedIdentifiers</key>
   <array>
       <string>ru.matveyb9.test.weatherapp.weatherRefresh</string>
   </array>
   ```

---

## Настройка Android (перед публикацией в Google Play)

Текущая конфигурация использует debug-подпись. Перед публикацией:

1. Создать keystore:
   ```bash
   keytool -genkey -v -keystore release.jks -keyalg RSA -keysize 2048 -validity 10000
   ```
2. Создать `android/key.properties`:
   ```properties
   storePassword=ВАШ_ПАРОЛЬ
   keyPassword=ВАШ_ПАРОЛЬ
   keyAlias=ВАШ_ALIAS
   storeFile=../release.jks
   ```
3. Обновить `android/app/build.gradle.kts` — заменить `signingConfig = signingConfigs.getByName("debug")` на `release`.

---

## Структура проекта

```
lib/
├── main.dart                    # Точка входа, MultiProvider
├── models/                      # LocationModel, WeatherModel, SettingsModel
├── providers/                   # WeatherProvider, SettingsProvider
├── screens/                     # HomeScreen, SettingsScreen
├── widgets/                     # UI-компоненты
├── services/                    # Weather, Geocoding, Widget, Cache, Location, Background
└── utils/                       # WeatherUtils, UnitsUtils

android/app/src/main/kotlin/…/
├── BaseWeatherWidget.kt         # Базовый AppWidgetProvider
├── WeatherWidget{S,M,L}.kt     # Три размера виджета
├── WeatherSyncWorker.kt         # Фоновый HTTP-запрос
├── BootReceiver.kt              # Перерегистрация задачи после reboot
└── MainActivity.kt

ios/
├── Runner/AppDelegate.swift              # BGTaskScheduler
└── WeatherWidgetExtension/
    ├── WeatherWidget.swift               # WidgetKit (3 размера)
    └── WeatherWidgetBundle.swift
```

---

## API

Приложение использует только открытые API без ключей:

| API | Назначение | Лицензия |
|-----|------------|----------|
| [Open-Meteo Forecast](https://api.open-meteo.com) | Данные погоды | CC BY 4.0 |
| [Open-Meteo Geocoding](https://geocoding-api.open-meteo.com) | Поиск городов | CC BY 4.0 |
| [Nominatim / OSM](https://nominatim.openstreetmap.org) | Обратное геокодирование | ODbL |

---

## PWA / GitHub Pages

Приложение автоматически собирается и деплоится в GitHub Pages при каждом push в `main`.

🌐 **[Открыть PWA](https://ВАШ_НИК.github.io/weather_app/)**

---

## Лицензия

MIT © 2026

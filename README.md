# 🌤️ Weather App — Flutter  
### с виджетами главного экрана (Android + iOS)

Кроссплатформенное приложение погоды на Flutter с тремя размерами нативных
виджетов лаунчера — **Мини (2×1)**, **Почасовой (4×2)**, **Расширенный (4×4)**.

---

## ✨ Возможности

| Функция | Описание |
|---|---|
| 🌍 Поиск города | Автодополнение через Open-Meteo Geocoding API |
| 💾 Последний регион | Сохраняется в SharedPreferences |
| 🌡️ Текущая погода | Темп., ощущается, влажность, ветер, UV, давление |
| ⏱️ Почасовой прогноз | 24 часа с эмодзи и осадками |
| 📅 7-дневный прогноз | Мин/макс с цветной полосой диапазона |
| 🌗 Системная тема | Автоматически светлая / тёмная |
| 📱 **Виджеты лаунчера** | Android (3 размера) + iOS WidgetKit (3 размера) |

---

## 📱 Виджеты главного экрана

### Android

| Виджет | Размер | Содержание |
|--------|--------|-----------|
| **Мини** | 2×1 | Эмодзи · темп · город · описание |
| **Почасовой** | 4×2 | Текущая погода + 5-часовая полоса |
| **Расширенный** | 4×4 | Текущая + 5-часовая + 5-дневная |

**Добавить:** удерживайте рабочий стол → Виджеты → «Погода».

### iOS (WidgetKit)

| Виджет | Семейство | Содержание |
|--------|-----------|-----------|
| **Погода — Мини** | systemSmall | Эмодзи · темп · город |
| **Погода — Почасовой** | systemMedium | Текущая + 5-часовая полоса |
| **Погода — Расширенный** | systemLarge | Текущая + часовая + 5-дневная |

**Добавить:** удерживайте рабочий стол → «+» → «Погода».

---

## 🚀 Быстрый старт

```bash
flutter pub get
flutter run                 # Android / iOS
flutter run -d chrome       # Web
flutter run -d windows      # Windows
flutter run -d macos        # macOS
flutter run -d linux        # Linux
```

---

## 🛠 Настройка виджетов

### Android — автоматически ✅

Все файлы уже в проекте. При `flutter build apk` виджеты собираются автоматически.

**Если используете другой package name:**  
Замените `com.example.weather_app` в файлах Kotlin и в `lib/services/widget_service.dart`:

```dart
static const _androidSmall  = 'your.package.WeatherWidgetSmall';
static const _androidMedium = 'your.package.WeatherWidgetMedium';
static const _androidLarge  = 'your.package.WeatherWidgetLarge';
```

---

### iOS — ручная настройка в Xcode

**Шаг 1 — Добавить Widget Extension target:**
```
File ▸ New ▸ Target ▸ Widget Extension
  Name: WeatherWidgetExtension
  Include Configuration Intent: NO
```

**Шаг 2 — Скопировать Swift файлы в target:**
- `ios/WeatherWidgetExtension/WeatherWidget.swift`
- `ios/WeatherWidgetExtension/WeatherWidgetBundle.swift`

Удалите шаблонный файл, который создал Xcode.

**Шаг 3 — Настроить App Group (общее хранилище):**
```
Runner target              ▸ Signing & Capabilities ▸ + ▸ App Groups
WeatherWidgetExtension     ▸ Signing & Capabilities ▸ + ▸ App Groups
  Идентификатор:  group.com.example.weather_app   (одинаковый в обоих!)
```

**Шаг 4 — Передать App Group в home_widget plugin:**  
В `ios/Runner/AppDelegate.swift` добавьте в `didFinishLaunchingWithOptions`:
```swift
import home_widget
// ...
HomeWidgetPlugin.setAppGroupId("group.com.example.weather_app")
```

**Шаг 5 — Собрать:**
```bash
flutter build ios
```

---

## 🏗️ Архитектура потока данных

```
Открытие приложения / pull-to-refresh
          │
          ▼
  WeatherProvider.fetchWeather()
    [вызывает Open-Meteo API]
          │
          ▼
  WidgetService.updateWidgets()
    HomeWidget.saveWidgetData('wg_city', ...)
    HomeWidget.saveWidgetData('wg_temp', ...)
    HomeWidget.saveWidgetData('wg_h1_*', ...)  ← 5 часов
    HomeWidget.saveWidgetData('wg_d1_*', ...)  ← 5 дней
    HomeWidget.updateWidget(android, iOS)
          │
    ┌─────┴──────┐
    ▼            ▼
Android         iOS
SharedPrefs     UserDefaults (App Group)
    │            │
WeatherWidget   WeatherProvider (SwiftUI)
(RemoteViews)   читает данные → WidgetKit рендерит
```

---

## 📦 Зависимости

| Пакет | Версия | Назначение |
|-------|--------|-----------|
| `http` | ^1.2.2 | HTTP к Open-Meteo |
| `shared_preferences` | ^2.3.2 | Сохранение города |
| `provider` | ^6.1.2 | State management |
| `intl` | ^0.19.0 | Русская локаль дат |
| `flutter_animate` | ^4.5.0 | Анимации |
| `home_widget` | ^0.7.0 | Bridge Flutter ↔ нативные виджеты |

---

## 🌐 API

**Open-Meteo** — бесплатный API без ключа, точность ECMWF/ERA5:
- Погода: `https://api.open-meteo.com/v1/forecast`
- Геокодирование: `https://geocoding-api.open-meteo.com/v1/search`

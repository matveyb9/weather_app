// lib/services/background_service.dart
//
// Background weather refresh — fetches fresh data even when the app is closed
// and pushes it to home-screen widgets.
//
// Platform support:
//   Android  ✅  WorkManager via workmanager package (API 23+)
//   iOS      ✅  BGAppRefreshTask via workmanager package (iOS 13+)
//   Web      ❌  silently skipped
//   Windows  ❌  silently skipped
//   macOS    ❌  silently skipped
//   Linux    ❌  silently skipped

import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../models/location_model.dart';
import '../models/settings_model.dart';
import '../models/weather_model.dart';
import 'cache_service.dart';
import 'weather_service.dart';
import '../utils/units_utils.dart';
import '../utils/weather_utils.dart';

const _taskName   = 'weather_background_sync';
const _taskUnique = 'ru.matveyb9.test.weatherapp.sync';

bool get _bgSupported =>
    !kIsWeb && (Platform.isAndroid || Platform.isIOS);

// ── Isolate entry point (top-level, required by workmanager) ──────────────────

@pragma('vm:entry-point')
void backgroundCallback() {
  Workmanager().executeTask((task, _) async {
    debugPrint('BackgroundService[$task]: started');
    try {
      await _syncWeather();
      return true;
    } catch (e) {
      debugPrint('BackgroundService[$task] error: $e');
      return false;
    }
  });
}

// ── Core sync logic ───────────────────────────────────────────────────────────

Future<void> _syncWeather() async {
  final prefs   = await SharedPreferences.getInstance();
  final locJson = prefs.getString('last_location');
  if (locJson == null) return;

  final location = LocationModel.fromJson(
      jsonDecode(locJson) as Map<String, dynamic>);

  // Fetch raw JSON
  final rawJson = await WeatherService()
      .getWeatherRaw(location.latitude, location.longitude);

  // Save to cache (works in isolate — pure SharedPreferences)
  await CacheService.saveWeather(rawJson: rawJson, location: location);

  // Read unit settings once (reuse prefs already loaded above)
  final tempUnit  = TempUnit.fromKey(prefs.getString('settings_temp_unit'));
  final windUnit  = WindUnit.fromKey(prefs.getString('settings_wind_unit'));
  final pressUnit = PressureUnit.fromKey(prefs.getString('settings_pressure_unit'));

  // Update home-screen widgets
  await HomeWidget.setAppGroupId('group.ru.matveyb9.test.weatherapp');
  await _pushToWidgets(rawJson, location.name,
      tempUnit: tempUnit, windUnit: windUnit, pressUnit: pressUnit);
}

/// Writes weather data into home_widget SharedPreferences.
/// Unit values are passed in from _syncWeather to avoid a second prefs load.
Future<void> _pushToWidgets(
  String rawJson,
  String cityName, {
  required TempUnit tempUnit,
  required WindUnit windUnit,
  required PressureUnit pressUnit,
}) async {
  final data = WeatherData.fromJson(
      jsonDecode(rawJson) as Map<String, dynamic>);
  final c = data.current;

  Future<void> save(String key, Object? val) =>
      HomeWidget.saveWidgetData(key, val);

  await save('wg_city',    cityName);
  await save('wg_temp',    UnitsUtils.formatTemp(c.temperature, tempUnit));
  await save('wg_feels',   UnitsUtils.formatFeelsLike(c.apparentTemperature, tempUnit));
  await save('wg_desc',    WeatherUtils.getWeatherDescription(c.weatherCode));
  await save('wg_code',    c.weatherCode.toString());
  await save('wg_isday',   c.isDay ? '1' : '0');
  await save('wg_humidity','${c.humidity}%');
  await save('wg_wind',
      '${UnitsUtils.formatWind(c.windSpeed, windUnit)} '
      '${WeatherUtils.getWindDirection(c.windDirection)}');
  await save('wg_pressure', UnitsUtils.formatPressure(c.pressureMsl, pressUnit));
  await save('wg_updated',  DateFormat('HH:mm').format(DateTime.now()));

  final hourly = data.hourly.take(5).toList();
  for (int i = 0; i < 5; i++) {
    final pfx = 'wg_h${i + 1}';
    if (i < hourly.length) {
      final h = hourly[i];
      await save('${pfx}_time',  i == 0 ? 'Сейчас' : DateFormat('HH:mm').format(h.time));
      await save('${pfx}_temp',  UnitsUtils.formatTempShort(h.temperature, tempUnit));
      await save('${pfx}_code',  h.weatherCode.toString());
      await save('${pfx}_isday', h.isDay ? '1' : '0');
    } else {
      await save('${pfx}_time', ''); await save('${pfx}_temp', '');
      await save('${pfx}_code', '0'); await save('${pfx}_isday', '1');
    }
  }

  final daily = data.daily.take(5).toList();
  for (int i = 0; i < 5; i++) {
    final pfx = 'wg_d${i + 1}';
    if (i < daily.length) {
      final d = daily[i];
      await save('${pfx}_day',   i == 0 ? 'Сег.' : WeatherUtils.capitalize(DateFormat('EEE', 'ru').format(d.date)));
      await save('${pfx}_code', d.weatherCode.toString());
      await save('${pfx}_max',   UnitsUtils.formatTempShort(d.maxTemperature, tempUnit));
      await save('${pfx}_min',   UnitsUtils.formatTempShort(d.minTemperature, tempUnit));
    } else {
      await save('${pfx}_day', ''); await save('${pfx}_code', '0');
      await save('${pfx}_max', ''); await save('${pfx}_min',  '');
    }
  }

  const pkg = 'ru.matveyb9.test.weatherapp';
  await HomeWidget.updateWidget(qualifiedAndroidName: '$pkg.WeatherWidgetSmall',  iOSName: 'WeatherWidgetSmall');
  await HomeWidget.updateWidget(qualifiedAndroidName: '$pkg.WeatherWidgetMedium', iOSName: 'WeatherWidgetMedium');
  await HomeWidget.updateWidget(qualifiedAndroidName: '$pkg.WeatherWidgetLarge',  iOSName: 'WeatherWidgetLarge');
}

// ── Public API ────────────────────────────────────────────────────────────────

class BackgroundService {
  static Future<void> initialize() async {
    if (!_bgSupported) return;
    await Workmanager().initialize(
      backgroundCallback,
      isInDebugMode: kDebugMode,
    );
    debugPrint('BackgroundService: initialized');
  }

  /// Register periodic sync. Safe to call on every launch (KEEP policy).
  static Future<void> registerPeriodicSync() async {
    if (!_bgSupported) return;
    try {
      await Workmanager().registerPeriodicTask(
        _taskUnique,
        _taskName,
        // 15 минут — минимальный интервал WorkManager, наиболее надёжный.
        // 30 минут Android может откладывать на часы из-за Doze-режима.
        frequency: const Duration(minutes: 15),
        existingWorkPolicy: ExistingWorkPolicy.keep,
        constraints: Constraints(
          networkType: NetworkType.connected,
          // requiresBatteryNotLow убран: он блокировал обновление при 20-30%
          // и препятствовал работе ночью на зарядке в Doze-режиме.
        ),
        backoffPolicy:      BackoffPolicy.linear,
        backoffPolicyDelay: const Duration(minutes: 5),
      );
      debugPrint('BackgroundService: periodic sync registered (30 min)');
    } catch (e) {
      debugPrint('BackgroundService.register error: $e');
    }
  }

  /// Trigger an immediate one-off sync (e.g. when app goes to background).
  static Future<void> syncNow() async {
    if (!_bgSupported) return;
    try {
      await Workmanager().registerOneOffTask(
        '${_taskUnique}_now_${DateTime.now().millisecondsSinceEpoch}',
        _taskName,
        initialDelay: const Duration(seconds: 3),
        constraints: Constraints(networkType: NetworkType.connected),
      );
    } catch (e) {
      debugPrint('BackgroundService.syncNow error: $e');
    }
  }

}

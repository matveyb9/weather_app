// lib/services/widget_service.dart
//
// Saves weather data to home_widget SharedPreferences so Android/iOS
// home-screen widgets can read and display it.
//
// Units are read from SettingsProvider and saved alongside the data so that
// the native widget shows exactly what the user configured in Settings.

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../models/settings_model.dart';
import '../models/weather_model.dart';
import '../utils/units_utils.dart';
import '../utils/weather_utils.dart';

class WidgetService {
  static const _pkg = 'ru.matveyb9.test.weatherapp';

  static const _androidSmall  = '$_pkg.WeatherWidgetSmall';
  static const _androidMedium = '$_pkg.WeatherWidgetMedium';
  static const _androidLarge  = '$_pkg.WeatherWidgetLarge';

  static const _iosSmall  = 'WeatherWidgetSmall';
  static const _iosMedium = 'WeatherWidgetMedium';
  static const _iosLarge  = 'WeatherWidgetLarge';

  static bool get _supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static Future<void> updateWidgets({
    required WeatherData data,
    required String cityName,
    required TempUnit tempUnit,
    required WindUnit windUnit,
    required PressureUnit pressureUnit,
    double? latitude,
    double? longitude,
  }) async {
    if (!_supported) return;
    try {
      final c = data.current;

      // ── Current ─────────────────────────────────────────────────────────
      await HomeWidget.saveWidgetData('wg_city',     cityName);
      await HomeWidget.saveWidgetData('wg_temp',
          UnitsUtils.formatTemp(c.temperature, tempUnit));
      await HomeWidget.saveWidgetData('wg_feels',
          UnitsUtils.formatFeelsLike(c.apparentTemperature, tempUnit));
      await HomeWidget.saveWidgetData('wg_desc',
          WeatherUtils.getWeatherDescription(c.weatherCode));
      await HomeWidget.saveWidgetData('wg_code',    c.weatherCode.toString());
      await HomeWidget.saveWidgetData('wg_isday',   c.isDay ? '1' : '0');
      await HomeWidget.saveWidgetData('wg_humidity','${c.humidity}%');
      await HomeWidget.saveWidgetData('wg_wind',
          '${UnitsUtils.formatWind(c.windSpeed, windUnit)} '
          '${WeatherUtils.getWindDirection(c.windDirection)}');
      await HomeWidget.saveWidgetData('wg_pressure',
          UnitsUtils.formatPressure(c.pressureMsl, pressureUnit));
      await HomeWidget.saveWidgetData('wg_updated',
          DateFormat('HH:mm').format(DateTime.now()));

      // ── Hourly (5 slots) ────────────────────────────────────────────────
      final hourly = data.hourly.take(5).toList();
      for (int i = 0; i < 5; i++) {
        final pfx = 'wg_h${i + 1}';
        if (i < hourly.length) {
          final h = hourly[i];
          await HomeWidget.saveWidgetData('${pfx}_time',
              i == 0 ? 'Сейчас' : DateFormat('HH:mm').format(h.time));
          await HomeWidget.saveWidgetData('${pfx}_temp',
              UnitsUtils.formatTempShort(h.temperature, tempUnit));
          await HomeWidget.saveWidgetData('${pfx}_code',  h.weatherCode.toString());
          await HomeWidget.saveWidgetData('${pfx}_isday', h.isDay ? '1' : '0');
        } else {
          await HomeWidget.saveWidgetData('${pfx}_time',  '');
          await HomeWidget.saveWidgetData('${pfx}_temp',  '');
          await HomeWidget.saveWidgetData('${pfx}_code',  '0');
          await HomeWidget.saveWidgetData('${pfx}_isday', '1');
        }
      }

      // ── Daily (5 days) ──────────────────────────────────────────────────
      final daily = data.daily.take(5).toList();
      for (int i = 0; i < 5; i++) {
        final pfx = 'wg_d${i + 1}';
        if (i < daily.length) {
          final d = daily[i];
          await HomeWidget.saveWidgetData('${pfx}_day',
              i == 0 ? 'Сег.' : WeatherUtils.capitalize(
                  DateFormat('EEE', 'ru').format(d.date)));
          await HomeWidget.saveWidgetData('${pfx}_code', d.weatherCode.toString());
          await HomeWidget.saveWidgetData('${pfx}_max',
              UnitsUtils.formatTempShort(d.maxTemperature, tempUnit));
          await HomeWidget.saveWidgetData('${pfx}_min',
              UnitsUtils.formatTempShort(d.minTemperature, tempUnit));
        } else {
          await HomeWidget.saveWidgetData('${pfx}_day',  '');
          await HomeWidget.saveWidgetData('${pfx}_code', '0');
          await HomeWidget.saveWidgetData('${pfx}_max',  '');
          await HomeWidget.saveWidgetData('${pfx}_min',  '');
        }
      }

      // ── Kotlin/Swift fallback worker ────────────────────────────────────
      await HomeWidget.saveWidgetData('bg_city', cityName);
      if (latitude  != null) await HomeWidget.saveWidgetData('bg_lat', latitude.toString());
      if (longitude != null) await HomeWidget.saveWidgetData('bg_lon', longitude.toString());
      // Pass unit keys so the native worker can format the same way
      await HomeWidget.saveWidgetData('settings_temp_unit',     tempUnit.key);
      await HomeWidget.saveWidgetData('settings_wind_unit',     windUnit.key);
      await HomeWidget.saveWidgetData('settings_pressure_unit', pressureUnit.key);

      // ── Trigger redraws ─────────────────────────────────────────────────
      await HomeWidget.updateWidget(
          qualifiedAndroidName: _androidSmall,  iOSName: _iosSmall);
      await HomeWidget.updateWidget(
          qualifiedAndroidName: _androidMedium, iOSName: _iosMedium);
      await HomeWidget.updateWidget(
          qualifiedAndroidName: _androidLarge,  iOSName: _iosLarge);

      debugPrint('WidgetService: updated for "$cityName" '
          '(${tempUnit.symbol}, ${windUnit.symbol}, ${pressureUnit.symbol})');
    } catch (e) {
      debugPrint('WidgetService.updateWidgets error: $e');
    }
  }
}

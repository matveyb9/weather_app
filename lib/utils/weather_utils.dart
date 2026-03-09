// lib/utils/weather_utils.dart
//
// Static helpers for WMO weather codes → icons, colours, descriptions, etc.
// All switch expressions use valid Dart 3 relational patterns (single bounds
// only; compound ranges use `when` guards or if-else chains).

import 'package:flutter/material.dart';

abstract class WeatherUtils {

  // ── Weather icon (IconData) ────────────────────────────────────────────────

  static IconData getWeatherIcon(int code, {bool isDay = true}) {
    if (code == 0 || code == 1) {
      return isDay ? Icons.wb_sunny_rounded : Icons.nightlight_round;
    }
    if (code == 2) return isDay ? Icons.wb_cloudy_rounded : Icons.cloud_rounded;
    if (code == 3) return Icons.cloud_rounded;
    if (code == 45 || code == 48) return Icons.foggy;
    if (code >= 51 && code <= 57) return Icons.grain;
    if (code >= 61 && code <= 67) return Icons.umbrella_rounded;
    if (code >= 71 && code <= 77) return Icons.ac_unit_rounded;
    if (code >= 80 && code <= 82) return Icons.water_drop_rounded;
    if (code == 85 || code == 86) return Icons.ac_unit_rounded;
    if (code >= 95)               return Icons.thunderstorm_rounded;
    return Icons.thermostat_rounded;
  }

  static Color getWeatherIconColor(int code, {bool isDay = true}) {
    if (code == 0 || code == 1) {
      return isDay
          ? const Color(0xFFFFB300)   // amber sun
          : const Color(0xFF7986CB);  // indigo moon
    }
    if (code == 2)                       return const Color(0xFF78909C);
    if (code == 3)                       return const Color(0xFF90A4AE);
    if (code == 45 || code == 48)        return const Color(0xFFB0BEC5);
    if (code >= 51 && code <= 57)        return const Color(0xFF42A5F5);
    if (code >= 61 && code <= 67)        return const Color(0xFF1E88E5);
    if (code >= 71 && code <= 77)        return const Color(0xFF80DEEA);
    if (code >= 80 && code <= 82)        return const Color(0xFF29B6F6);
    if (code == 85 || code == 86)        return const Color(0xFF80CBC4);
    if (code >= 95)                      return const Color(0xFF7E57C2);
    return const Color(0xFF78909C);
  }

  // ── Weather description ────────────────────────────────────────────────────

  static String getWeatherDescription(int code) {
    return switch (code) {
      0  => 'Ясно',
      1  => 'Преимущественно ясно',
      2  => 'Переменная облачность',
      3  => 'Пасмурно',
      45 => 'Туман',
      48 => 'Изморозный туман',
      51 => 'Слабая морось',
      53 => 'Умеренная морось',
      55 => 'Сильная морось',
      56 => 'Ледяная морось (слабая)',
      57 => 'Ледяная морось (сильная)',
      61 => 'Слабый дождь',
      63 => 'Умеренный дождь',
      65 => 'Сильный дождь',
      66 => 'Ледяной дождь (слабый)',
      67 => 'Ледяной дождь (сильный)',
      71 => 'Слабый снег',
      73 => 'Умеренный снег',
      75 => 'Сильный снег',
      77 => 'Снежная крупа',
      80 => 'Небольшой ливень',
      81 => 'Умеренный ливень',
      82 => 'Сильный ливень',
      85 => 'Небольшой снегопад',
      86 => 'Сильный снегопад',
      95 => 'Гроза',
      96 => 'Гроза с небольшим градом',
      99 => 'Гроза с сильным градом',
      _  => 'Переменная облачность',
    };
  }

  // ── Wind direction ─────────────────────────────────────────────────────────

  static String getWindDirection(int degrees) {
    const dirs = ['С', 'СВ', 'В', 'ЮВ', 'Ю', 'ЮЗ', 'З', 'СЗ'];
    return dirs[((degrees + 22.5) / 45).floor() % 8];
  }

  // ── UV index ───────────────────────────────────────────────────────────────

  static String getUvLabel(int index) {
    if (index <= 2)  return 'Низкий';
    if (index <= 5)  return 'Средний';
    if (index <= 7)  return 'Высокий';
    if (index <= 10) return 'Очень высокий';
    return 'Экстремальный';
  }

  static Color getUvColor(int index) {
    if (index <= 2)  return Colors.green;
    if (index <= 5)  return Colors.yellow.shade700;
    if (index <= 7)  return Colors.orange;
    if (index <= 10) return Colors.red;
    return Colors.purple;
  }

  // ── Background gradient ────────────────────────────────────────────────────

  static List<Color> getBackgroundGradient(int code, bool isDay, bool isDarkMode) {
    if (isDarkMode) {
      if (code == 0 && isDay)              return [const Color(0xFF0D1B2A), const Color(0xFF1A3A5C)];
      if (code == 0)                       return [const Color(0xFF0A0E1A), const Color(0xFF0D1B35)];
      if (code == 1 || code == 2)          return [const Color(0xFF1A1A2E), const Color(0xFF16213E)];
      if (code == 3)                       return [const Color(0xFF1C1C2E), const Color(0xFF2C2C3E)];
      if (code >= 51 && code <= 67)        return [const Color(0xFF1A1A2E), const Color(0xFF243B55)];
      if (code >= 71 && code <= 77)        return [const Color(0xFF1C2331), const Color(0xFF2C3E50)];
      if (code >= 80 && code <= 86)        return [const Color(0xFF1A1A2E), const Color(0xFF243B55)];
      if (code >= 95)                      return [const Color(0xFF0D0D1A), const Color(0xFF1A1A2E)];
      return [const Color(0xFF1A1A2E), const Color(0xFF2C2C3E)];
    }

    if (code == 0 && isDay)                return [const Color(0xFF1565C0), const Color(0xFF42A5F5)];
    if (code == 0)                         return [const Color(0xFF0D1B35), const Color(0xFF1A3A6C)];
    if (code == 1 || code == 2)            return [const Color(0xFF1976D2), const Color(0xFF64B5F6)];
    if (code == 3)                         return [const Color(0xFF546E7A), const Color(0xFF90A4AE)];
    if (code == 45 || code == 48)          return [const Color(0xFF607D8B), const Color(0xFFB0BEC5)];
    if (code >= 51 && code <= 67)          return [const Color(0xFF37474F), const Color(0xFF607D8B)];
    if (code >= 71 && code <= 77)          return [const Color(0xFF546E7A), const Color(0xFFB0BEC5)];
    if (code >= 80 && code <= 86)          return [const Color(0xFF37474F), const Color(0xFF546E7A)];
    if (code >= 95)                        return [const Color(0xFF212121), const Color(0xFF37474F)];
    return [const Color(0xFF1565C0), const Color(0xFF42A5F5)];
  }

  // ── String helper ──────────────────────────────────────────────────────────

  static String capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

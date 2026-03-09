// lib/utils/units_utils.dart
//
// Unit conversion and formatting helpers.
// All source values come from Open-Meteo API:
//   • Temperature  — °C
//   • Wind speed   — km/h (wind_speed_unit=kmh)
//   • Pressure     — hPa  (pressure_msl field)

import '../models/settings_model.dart';

abstract class UnitsUtils {

  // ── Temperature ────────────────────────────────────────────────────────────

  /// Convert °C → target unit.
  static double convertTemp(double celsius, TempUnit unit) {
    return switch (unit) {
      TempUnit.celsius    => celsius,
      TempUnit.fahrenheit => celsius * 9 / 5 + 32,
    };
  }

  /// Format temperature with unit symbol, e.g. «22°C» or «72°F».
  static String formatTemp(double celsius, TempUnit unit, {bool showUnit = true}) {
    final converted = convertTemp(celsius, unit).round();
    return showUnit ? '$converted${unit.symbol}' : '$converted°';
  }

  /// Format temperature without unit symbol, for hourly/daily tiles.
  static String formatTempShort(double celsius, TempUnit unit) =>
      '${convertTemp(celsius, unit).round()}°';

  /// «Ощущается как 20°C» / «Feels like 68°F»
  static String formatFeelsLike(double celsius, TempUnit unit) =>
      'Ощущается как ${formatTemp(celsius, unit)}';

  // ── Wind speed ─────────────────────────────────────────────────────────────

  /// Convert km/h → target unit.
  static double convertWind(double kmh, WindUnit unit) {
    return switch (unit) {
      WindUnit.kmh => kmh,
      WindUnit.ms  => kmh / 3.6,
      WindUnit.mph => kmh / 1.60934,
    };
  }

  /// Format wind speed with symbol, e.g. «5 м/с» or «18 км/ч».
  static String formatWind(double kmh, WindUnit unit) {
    final v = convertWind(kmh, unit);
    // m/s shows one decimal if < 10, otherwise round
    final formatted = (unit == WindUnit.ms && v < 10)
        ? v.toStringAsFixed(1)
        : v.round().toString();
    return '$formatted ${unit.symbol}';
  }

  // ── Pressure ───────────────────────────────────────────────────────────────

  /// Convert hPa → target unit.
  static double convertPressure(double hpa, PressureUnit unit) {
    return switch (unit) {
      PressureUnit.hpa   => hpa,
      PressureUnit.mmhg  => hpa * 0.750062,
    };
  }

  /// Format pressure with symbol, e.g. «755 мм рт.ст.» or «1013 гПа».
  static String formatPressure(double hpa, PressureUnit unit) =>
      '${convertPressure(hpa, unit).round()} ${unit.symbol}';

  /// Short form for detail tiles (e.g. «755 мм» / «1013 гПа»).
  static String formatPressureShort(double hpa, PressureUnit unit) {
    final value = convertPressure(hpa, unit).round();
    return switch (unit) {
      PressureUnit.mmhg => '$value мм',
      PressureUnit.hpa  => '$value гПа',
    };
  }

  /// Subtitle for pressure detail tile.
  static String pressureSubtitle(PressureUnit unit) {
    return switch (unit) {
      PressureUnit.mmhg => 'рт. ст.',
      PressureUnit.hpa  => 'гектопаскаль',
    };
  }
}

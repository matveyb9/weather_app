// lib/models/settings_model.dart
//
// Enums for user-configurable units and theme.
// Defaults: Celsius, m/s, mmHg, system theme.

enum TempUnit {
  celsius('celsius', '°C'),
  fahrenheit('fahrenheit', '°F');

  final String key;
  final String symbol;
  const TempUnit(this.key, this.symbol);

  static TempUnit fromKey(String? key) =>
      values.firstWhere((e) => e.key == key, orElse: () => celsius);
}

enum WindUnit {
  ms('ms', 'м/с'),
  kmh('kmh', 'км/ч'),
  mph('mph', 'mph');

  final String key;
  final String symbol;
  const WindUnit(this.key, this.symbol);

  static WindUnit fromKey(String? key) =>
      values.firstWhere((e) => e.key == key, orElse: () => ms);
}

enum PressureUnit {
  mmhg('mmhg', 'мм рт.ст.'),
  hpa('hpa', 'гПа');

  final String key;
  final String symbol;
  const PressureUnit(this.key, this.symbol);

  static PressureUnit fromKey(String? key) =>
      values.firstWhere((e) => e.key == key, orElse: () => mmhg);
}

enum AppTheme {
  system('system', 'Как в системе'),
  light('light', 'Светлая'),
  dark('dark', 'Тёмная');

  final String key;
  final String label;
  const AppTheme(this.key, this.label);

  static AppTheme fromKey(String? key) =>
      values.firstWhere((e) => e.key == key, orElse: () => system);
}

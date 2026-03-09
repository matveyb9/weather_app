// lib/providers/settings_provider.dart
//
// Persists and exposes user-configurable settings.
// Defaults: Celsius, m/s, mmHg, system theme.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/settings_model.dart';

class SettingsProvider extends ChangeNotifier {
  // SharedPreferences keys
  static const _kTempUnit     = 'settings_temp_unit';
  static const _kWindUnit     = 'settings_wind_unit';
  static const _kPressureUnit = 'settings_pressure_unit';
  static const _kTheme        = 'settings_theme';

  // Current values (defaults declared here)
  TempUnit     _tempUnit     = TempUnit.celsius;
  WindUnit     _windUnit     = WindUnit.ms;
  PressureUnit _pressureUnit = PressureUnit.mmhg;
  AppTheme     _appTheme     = AppTheme.system;

  // ── Getters ──────────────────────────────────────────────────────────────

  TempUnit     get tempUnit     => _tempUnit;
  WindUnit     get windUnit     => _windUnit;
  PressureUnit get pressureUnit => _pressureUnit;
  AppTheme     get appTheme     => _appTheme;

  ThemeMode get themeMode => switch (_appTheme) {
    AppTheme.system => ThemeMode.system,
    AppTheme.light  => ThemeMode.light,
    AppTheme.dark   => ThemeMode.dark,
  };

  // ── Init ─────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _tempUnit     = TempUnit.fromKey(prefs.getString(_kTempUnit));
    _windUnit     = WindUnit.fromKey(prefs.getString(_kWindUnit));
    _pressureUnit = PressureUnit.fromKey(prefs.getString(_kPressureUnit));
    _appTheme     = AppTheme.fromKey(prefs.getString(_kTheme));
    notifyListeners();
  }

  // ── Setters ───────────────────────────────────────────────────────────────

  Future<void> setTempUnit(TempUnit unit) async {
    if (_tempUnit == unit) return;
    _tempUnit = unit;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTempUnit, unit.key);
  }

  Future<void> setWindUnit(WindUnit unit) async {
    if (_windUnit == unit) return;
    _windUnit = unit;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kWindUnit, unit.key);
  }

  Future<void> setPressureUnit(PressureUnit unit) async {
    if (_pressureUnit == unit) return;
    _pressureUnit = unit;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPressureUnit, unit.key);
  }

  Future<void> setAppTheme(AppTheme theme) async {
    if (_appTheme == theme) return;
    _appTheme = theme;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTheme, theme.key);
  }

  Future<void> resetToDefaults() async {
    _tempUnit     = TempUnit.celsius;
    _windUnit     = WindUnit.ms;
    _pressureUnit = PressureUnit.mmhg;
    _appTheme     = AppTheme.system;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTempUnit);
    await prefs.remove(_kWindUnit);
    await prefs.remove(_kPressureUnit);
    await prefs.remove(_kTheme);
  }
}

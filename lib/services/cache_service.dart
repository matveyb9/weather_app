// lib/services/cache_service.dart
//
// Offline cache for weather data.
// Stores the raw API JSON string + metadata in SharedPreferences.
// Works on ALL platforms (no platform restrictions).

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/location_model.dart';
import '../models/weather_model.dart';

class CacheService {
  static const _keyWeatherJson  = 'cache_weather_json';
  static const _keyFetchedAt    = 'cache_fetched_at_ms';
  static const _keyLocationJson = 'cache_location_json';

  // Data is considered fresh for 30 minutes.
  static const _freshDuration = Duration(minutes: 30);

  // ── Write ────────────────────────────────────────────────────────────────────

  static Future<void> saveWeather({
    required String rawJson,
    required LocationModel location,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyWeatherJson,  rawJson);
      await prefs.setString(_keyLocationJson, jsonEncode(location.toJson()));
      await prefs.setInt(   _keyFetchedAt,    DateTime.now().millisecondsSinceEpoch);
      debugPrint('CacheService: saved (${rawJson.length} bytes)');
    } catch (e) {
      debugPrint('CacheService.save error: $e');
    }
  }

  // ── Read ─────────────────────────────────────────────────────────────────────

  static Future<CachedWeather?> loadWeather() async {
    try {
      final prefs      = await SharedPreferences.getInstance();
      final rawJson    = prefs.getString(_keyWeatherJson);
      final locationJs = prefs.getString(_keyLocationJson);
      final fetchedMs  = prefs.getInt(_keyFetchedAt);

      if (rawJson == null || locationJs == null || fetchedMs == null) {
        return null;
      }

      final fetchedAt = DateTime.fromMillisecondsSinceEpoch(fetchedMs);
      final location  = LocationModel.fromJson(
          jsonDecode(locationJs) as Map<String, dynamic>);
      final data      = WeatherData.fromJson(
          jsonDecode(rawJson) as Map<String, dynamic>);

      debugPrint('CacheService: loaded (age ${DateTime.now().difference(fetchedAt).inMinutes} min)');
      return CachedWeather(data: data, location: location, fetchedAt: fetchedAt);
    } catch (e) {
      debugPrint('CacheService.load error: $e');
      return null;
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  static bool isFresh(DateTime fetchedAt) =>
      DateTime.now().difference(fetchedAt) < _freshDuration;

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyWeatherJson);
    await prefs.remove(_keyLocationJson);
    await prefs.remove(_keyFetchedAt);
  }
}

/// Container for data loaded from the cache.
class CachedWeather {
  final WeatherData    data;
  final LocationModel  location;
  final DateTime       fetchedAt;

  const CachedWeather({
    required this.data,
    required this.location,
    required this.fetchedAt,
  });

  bool get isFresh => CacheService.isFresh(fetchedAt);
}

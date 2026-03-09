// lib/services/location_service.dart
//
// Platform support matrix:
//   Android  ✅  fine + coarse GPS
//   iOS      ✅  CoreLocation
//   Web      ✅  browser Geolocation API
//   Windows  ✅  Windows Location API (Win 10+)
//   macOS    ✅  CoreLocation (requires entitlement)
//   Linux    ❌  geolocator does not support Linux — returns null gracefully

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/location_model.dart';
import 'geocoding_service.dart';

/// Possible outcomes of a location request.
enum LocationResult { success, permissionDenied, permissionPermanentlyDenied,
                      serviceDisabled, unsupportedPlatform, error }

class LocationService {
  /// Returns false only on Linux, where [geolocator] has no implementation.
  static bool get isSupported => kIsWeb || !Platform.isLinux;

  /// Requests the current device position and reverse-geocodes it into a
  /// [LocationModel].  Returns `null` on any failure; [result] gives the
  /// specific reason.
  static Future<({LocationModel? location, LocationResult result})>
      getCurrentLocation() async {
    // ── Platform guard ────────────────────────────────────────────────────────
    if (!isSupported) {
      return (location: null, result: LocationResult.unsupportedPlatform);
    }

    // ── Location services enabled? ────────────────────────────────────────────
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return (location: null, result: LocationResult.serviceDisabled);
    }

    // ── Permission ────────────────────────────────────────────────────────────
    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return (location: null, result: LocationResult.permissionDenied);
    }

    if (permission == LocationPermission.deniedForever) {
      return (location: null, result: LocationResult.permissionPermanentlyDenied);
    }

    // ── Get position ──────────────────────────────────────────────────────────
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,   // sufficient for weather, faster
          timeLimit: Duration(seconds: 12),
        ),
      );

      // ── Reverse geocode ───────────────────────────────────────────────────
      final location = await GeocodingService()
          .reverseGeocode(position.latitude, position.longitude);

      return (location: location, result: LocationResult.success);
    } catch (e) {
      debugPrint('LocationService error: $e');
      return (location: null, result: LocationResult.error);
    }
  }

  /// Human-readable error message for the UI.
  static String errorMessage(LocationResult result) => switch (result) {
    LocationResult.permissionDenied          => 'Нет разрешения на доступ к местоположению.',
    LocationResult.permissionPermanentlyDenied =>
        'Разрешение отклонено навсегда.\nОткройте Настройки → Приложения → Погода → Разрешения.',
    LocationResult.serviceDisabled           => 'Служба геолокации отключена на устройстве.',
    LocationResult.unsupportedPlatform       => 'Геолокация не поддерживается на этой платформе.',
    LocationResult.error                     => 'Не удалось определить местоположение.',
    LocationResult.success                   => '',
  };
}

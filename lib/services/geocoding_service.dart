// lib/services/geocoding_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/location_model.dart';

class GeocodingService {
  static const _searchUrl  = 'https://geocoding-api.open-meteo.com/v1/search';
  static const _reverseUrl = 'https://nominatim.openstreetmap.org/reverse';

  // ── Forward search ──────────────────────────────────────────────────────────

  Future<List<LocationModel>> searchLocations(String query) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.parse(_searchUrl).replace(queryParameters: {
      'name': query.trim(),
      'count': '10',
      'language': 'ru',
      'format': 'json',
    });

    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('Ошибка поиска: ${response.statusCode}');
    }

    final data    = jsonDecode(response.body) as Map<String, dynamic>;
    final results = data['results'] as List?;
    if (results == null) return [];

    return results
        .map((e) => LocationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Reverse geocode (Nominatim — free, no key) ──────────────────────────────

  /// Converts GPS coordinates into a [LocationModel] with a human-readable
  /// city name using the Nominatim / OpenStreetMap service.
  ///
  /// Falls back to a generic "Моё местоположение" model if the service
  /// is unreachable or returns no usable result.
  Future<LocationModel> reverseGeocode(double lat, double lon) async {
    try {
      final uri = Uri.parse(_reverseUrl).replace(queryParameters: {
        'lat': lat.toString(),
        'lon': lon.toString(),
        'format': 'json',
        'accept-language': 'ru',
        'zoom': '10', // city-level detail
      });

      final response = await http
          .get(uri, headers: {'User-Agent': 'WeatherApp/1.0 Flutter'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data    = jsonDecode(response.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;

        if (address != null) {
          final city = address['city']       as String?
                    ?? address['town']       as String?
                    ?? address['village']    as String?
                    ?? address['county']     as String?
                    ?? address['municipality'] as String?;

          if (city != null && city.isNotEmpty) {
            return LocationModel(
              name:      city,
              country:   address['country']  as String? ?? '',
              admin1:    address['state']    as String?,
              latitude:  lat,
              longitude: lon,
            );
          }
        }
      }
    } catch (_) {
      // Network error — fall through to generic model
    }

    // Fallback: generic name with rounded coordinates
    return LocationModel(
      name:      'Моё местоположение',
      country:   '',
      latitude:  lat,
      longitude: lon,
    );
  }
}

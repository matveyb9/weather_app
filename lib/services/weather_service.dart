// lib/services/weather_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

class WeatherService {
  static const _baseUrl = 'https://api.open-meteo.com/v1';

  static const _currentFields = [
    'temperature_2m', 'apparent_temperature', 'relative_humidity_2m',
    'precipitation', 'weather_code', 'pressure_msl',
    'wind_speed_10m', 'wind_direction_10m', 'uv_index', 'is_day',
  ];
  static const _hourlyFields = [
    'temperature_2m', 'relative_humidity_2m',
    'precipitation', 'weather_code', 'is_day',
  ];
  static const _dailyFields = [
    'weather_code', 'temperature_2m_max', 'temperature_2m_min',
    'precipitation_sum', 'wind_speed_10m_max', 'sunrise', 'sunset',
  ];

  Uri _buildUri(double latitude, double longitude) =>
      Uri.parse('$_baseUrl/forecast').replace(queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'current': _currentFields.join(','),
        'hourly': _hourlyFields.join(','),
        'daily': _dailyFields.join(','),
        'timezone': 'auto',
        'forecast_days': '7',
        'forecast_hours': '25',
        'wind_speed_unit': 'kmh',
      });

  /// Returns the raw JSON string from the API.
  /// Used for caching — the string is stored as-is and re-parsed on demand.
  Future<String> getWeatherRaw(double latitude, double longitude) async {
    final response = await http
        .get(_buildUri(latitude, longitude))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Ошибка API погоды: ${response.statusCode}');
    }
    return response.body;
  }

  /// Convenience wrapper: fetch + parse in one call.
  Future<WeatherData> getWeather(double latitude, double longitude) async {
    final raw = await getWeatherRaw(latitude, longitude);
    return WeatherData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}

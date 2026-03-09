// lib/widgets/weather_icon.dart
//
// Single reusable widget for all weather condition icons.
// Uses built-in Material Icons — no extra packages required.
//
// Usage:
//   WeatherIcon(code: 61, isDay: true, size: 72)           // coloured
//   WeatherIcon(code: 61, isDay: true, size: 32, color: Colors.white)  // forced white

import 'package:flutter/material.dart';
import '../utils/weather_utils.dart';

class WeatherIcon extends StatelessWidget {
  final int code;
  final bool isDay;
  final double size;

  /// Override the automatic theme colour (e.g. white for gradient cards).
  final Color? color;

  const WeatherIcon({
    super.key,
    required this.code,
    this.isDay = true,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      WeatherUtils.getWeatherIcon(code, isDay: isDay),
      size: size,
      color: color ?? WeatherUtils.getWeatherIconColor(code, isDay: isDay),
    );
  }
}

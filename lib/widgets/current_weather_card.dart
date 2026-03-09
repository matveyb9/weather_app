// lib/widgets/current_weather_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/weather_model.dart';
import '../providers/settings_provider.dart';
import '../utils/units_utils.dart';
import '../utils/weather_utils.dart';
import 'weather_icon.dart';

class CurrentWeatherCard extends StatelessWidget {
  final WeatherData data;
  final String locationName;

  const CurrentWeatherCard({
    super.key,
    required this.data,
    required this.locationName,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final current  = data.current;
    final theme    = Theme.of(context);
    final isDark   = theme.brightness == Brightness.dark;
    final gradient = WeatherUtils.getBackgroundGradient(
        current.weatherCode, current.isDay, isDark);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end:   Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color:      gradient.first.withValues(alpha: 0.4),
            blurRadius: 20,
            offset:     const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date
            Text(
              DateFormat('EEEE, d MMMM', 'ru').format(DateTime.now()),
              style: theme.textTheme.bodyMedium?.copyWith(
                color:       Colors.white70,
                letterSpacing: 0.5,
              ),
            ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.1, curve: Curves.easeOut),

            const SizedBox(height: 24),

            // Icon + temperature
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                WeatherIcon(
                  code:  current.weatherCode,
                  isDay: current.isDay,
                  size:  72,
                  color: Colors.white,
                )
                    .animate()
                    .scale(begin: const Offset(0.5, 0.5), duration: 600.ms, curve: Curves.elasticOut),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        UnitsUtils.formatTemp(current.temperature, settings.tempUnit),
                        style: const TextStyle(
                          color:      Colors.white,
                          fontSize:   64,
                          fontWeight: FontWeight.w200,
                          height:     1,
                        ),
                      ),
                      Text(
                        WeatherUtils.getWeatherDescription(current.weatherCode),
                        style: const TextStyle(
                          color:      Colors.white,
                          fontSize:   16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 100.ms, duration: 600.ms),

            const SizedBox(height: 8),

            Text(
              UnitsUtils.formatFeelsLike(current.apparentTemperature, settings.tempUnit),
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),

            const SizedBox(height: 24),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 20),

            // Quick stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _QuickStat(
                  icon:  Icons.water_drop_rounded,
                  value: '${current.humidity}%',
                  label: 'Влажность',
                ),
                _QuickStat(
                  icon:  Icons.air_rounded,
                  value: '${UnitsUtils.formatWind(current.windSpeed, settings.windUnit)}\n'
                         '${WeatherUtils.getWindDirection(current.windDirection)}',
                  label: 'Ветер',
                ),
                _QuickStat(
                  icon:  Icons.grain,
                  value: '${current.precipitation} мм',
                  label: 'Осадки',
                ),
                _QuickStat(
                  icon:  Icons.compress_rounded,
                  value: UnitsUtils.formatPressureShort(
                      current.pressureMsl, settings.pressureUnit),
                  label: 'Давление',
                ),
              ],
            ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
          ],
        ),
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _QuickStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 22, color: Colors.white70),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color:      Colors.white,
            fontWeight: FontWeight.bold,
            fontSize:   12,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 11),
        ),
      ],
    );
  }
}

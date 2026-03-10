// lib/widgets/daily_forecast.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/weather_model.dart';
import '../providers/settings_provider.dart';
import '../utils/units_utils.dart';
import '../utils/weather_utils.dart';
import 'weather_icon.dart';

class DailyForecast extends StatelessWidget {
  final List<DailyWeather> daily;

  const DailyForecast({super.key, required this.daily});

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final absMin = daily.map((d) => d.minTemperature).reduce((a, b) => a < b ? a : b);
    final absMax = daily.map((d) => d.maxTemperature).reduce((a, b) => a > b ? a : b);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  'Прогноз на 7 дней',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color:         theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...daily.asMap().entries.map((entry) {
              final i   = entry.key;
              final day = entry.value;
              return _DayRow(
                day:     day,
                isToday: i == 0,
                absMin:  absMin,
                absMax:  absMax,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  final DailyWeather day;
  final bool isToday;
  final double absMin;
  final double absMax;

  const _DayRow({
    required this.day,
    required this.isToday,
    required this.absMin,
    required this.absMax,
  });

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final settings = context.watch<SettingsProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          // Day label
          SizedBox(
            width: 90,
            child: Text(
              isToday
                  ? 'Сегодня'
                  : WeatherUtils.capitalize(
                      DateFormat('EEE, d MMM', 'ru').format(day.date)),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),

          // Weather icon (daily = always daytime)
          WeatherIcon(code: day.weatherCode, isDay: true, size: 22),

          const SizedBox(width: 6),

          // Min temp
          SizedBox(
            width: 36,
            child: Text(
              UnitsUtils.formatTempShort(day.minTemperature, settings.tempUnit),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
              textAlign: TextAlign.right,
            ),
          ),

          const SizedBox(width: 8),

          // Temperature bar (always in °C for relative scaling)
          Expanded(
            child: _TempRangeBar(
              min:    day.minTemperature,
              max:    day.maxTemperature,
              absMin: absMin,
              absMax: absMax,
            ),
          ),

          const SizedBox(width: 8),

          // Max temp
          SizedBox(
            width: 36,
            child: Text(
              UnitsUtils.formatTempShort(day.maxTemperature, settings.tempUnit),
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}

class _TempRangeBar extends StatelessWidget {
  final double min, max, absMin, absMax;

  const _TempRangeBar({
    required this.min,
    required this.max,
    required this.absMin,
    required this.absMax,
  });

  @override
  Widget build(BuildContext context) {
    final range = absMax - absMin;
    if (range == 0) return const SizedBox(height: 6);

    final startFraction = (min - absMin) / range;
    final endFraction   = (max - absMin) / range;

    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          height: 6,
          child: Stack(
            children: [
              Container(color: Theme.of(context).colorScheme.surfaceContainerHighest),
              Positioned(
                left:  startFraction * w,
                width: ((endFraction - startFraction) * w).clamp(6.0, w),
                top: 0, bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_tempColor(min), _tempColor(max)],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Color _tempColor(double t) {
    if (t <= -10) return const Color(0xFF00E5FF);
    if (t <= 0)   return const Color(0xFF4FC3F7);
    if (t <= 10)  return const Color(0xFF81C784);
    if (t <= 20)  return const Color(0xFFFFD54F);
    if (t <= 30)  return const Color(0xFFFF8A65);
    return const Color(0xFFEF5350);
  }
}

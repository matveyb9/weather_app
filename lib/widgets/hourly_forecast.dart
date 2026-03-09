// lib/widgets/hourly_forecast.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/weather_model.dart';
import '../providers/settings_provider.dart';
import '../utils/units_utils.dart';
import 'weather_icon.dart';

class HourlyForecast extends StatelessWidget {
  final List<HourlyWeather> hourly;

  const HourlyForecast({super.key, required this.hourly});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Почасовой прогноз',
      icon:  Icons.access_time_rounded,
      child: SizedBox(
        height: 112,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: hourly.length,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          itemBuilder: (context, index) {
            final item  = hourly[index];
            final isNow = index == 0;
            return _HourItem(item: item, isNow: isNow)
                .animate(delay: (index * 30).ms)
                .fadeIn(duration: 400.ms);
          },
        ),
      ),
    );
  }
}

class _HourItem extends StatelessWidget {
  final HourlyWeather item;
  final bool isNow;

  const _HourItem({required this.item, required this.isNow});

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final settings = context.watch<SettingsProvider>();

    return Container(
      width:  68,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: isNow
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: isNow
            ? Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
                width: 1.5,
              )
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text(
            isNow ? 'Сейчас' : DateFormat('HH:mm').format(item.time),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: isNow ? FontWeight.bold : FontWeight.normal,
              color: isNow
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          WeatherIcon(
            code:  item.weatherCode,
            isDay: item.isDay,
            size:  24,
          ),
          Text(
            UnitsUtils.formatTempShort(item.temperature, settings.tempUnit),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isNow ? theme.colorScheme.onPrimaryContainer : null,
            ),
          ),
          if (item.precipitation > 0)
            Text(
              '${item.precipitation}мм',
              style: theme.textTheme.labelSmall?.copyWith(
                color:    Colors.blue.shade400,
                fontSize: 10,
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color:         theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

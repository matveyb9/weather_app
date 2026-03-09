// lib/widgets/weather_details.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/weather_model.dart';
import '../providers/settings_provider.dart';
import '../utils/units_utils.dart';
import '../utils/weather_utils.dart';

class WeatherDetails extends StatelessWidget {
  final WeatherData data;

  const WeatherDetails({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final current  = data.current;
    final theme    = Theme.of(context);

    final sunrise = data.daily.isNotEmpty ? _formatTime(data.daily.first.sunrise) : '–';
    final sunset  = data.daily.isNotEmpty ? _formatTime(data.daily.first.sunset)  : '–';

    final details = [
      _DetailItem(
        icon:      Icons.water_drop_rounded,
        iconColor: const Color(0xFF42A5F5),
        label:     'Влажность',
        value:     '${current.humidity}%',
        subtitle:  _humidityLabel(current.humidity),
      ),
      _DetailItem(
        icon:      Icons.air_rounded,
        iconColor: const Color(0xFF78909C),
        label:     'Ветер',
        value:     UnitsUtils.formatWind(current.windSpeed, settings.windUnit),
        subtitle:  WeatherUtils.getWindDirection(current.windDirection),
      ),
      _DetailItem(
        icon:      Icons.compress_rounded,
        iconColor: const Color(0xFF8D6E63),
        label:     'Давление',
        value:     UnitsUtils.formatPressureShort(
            current.pressureMsl, settings.pressureUnit),
        subtitle:  UnitsUtils.pressureSubtitle(settings.pressureUnit),
      ),
      _DetailItem(
        icon:         Icons.light_mode_rounded,
        iconColor:    const Color(0xFFFFB300),
        label:        'УФ-индекс',
        value:        '${current.uvIndex}',
        subtitle:     WeatherUtils.getUvLabel(current.uvIndex),
        subtitleColor: WeatherUtils.getUvColor(current.uvIndex),
      ),
      _DetailItem(
        icon:      Icons.wb_twilight_rounded,
        iconColor: const Color(0xFFFF8F00),
        label:     'Восход',
        value:     sunrise,
        subtitle:  'рассвет',
      ),
      _DetailItem(
        icon:      Icons.bedtime_rounded,
        iconColor: const Color(0xFF5C6BC0),
        label:     'Закат',
        value:     sunset,
        subtitle:  'сумерки',
      ),
    ];

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
                Icon(Icons.info_outline_rounded,
                    size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  'Подробности',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color:         theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:   2,
                crossAxisSpacing: 10,
                mainAxisSpacing:  10,
                childAspectRatio: 2.1,
              ),
              itemCount: details.length,
              itemBuilder: (context, index) => details[index]
                  .animate(delay: (index * 60).ms)
                  .fadeIn(duration: 400.ms)
                  .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOut),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String isoTime) {
    try {
      final dt = DateTime.parse(isoTime);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoTime.length >= 16 ? isoTime.substring(11, 16) : isoTime;
    }
  }

  String _humidityLabel(int h) {
    if (h < 30) return 'Сухо';
    if (h < 60) return 'Комфортно';
    if (h < 80) return 'Влажно';
    return 'Очень влажно';
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String subtitle;
  final Color? subtitleColor;

  const _DetailItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subtitle,
    this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color:        theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 26, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment:  MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: subtitleColor ??
                        theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontWeight: subtitleColor != null ? FontWeight.w600 : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

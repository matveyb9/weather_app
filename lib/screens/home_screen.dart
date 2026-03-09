// lib/screens/home_screen.dart

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/weather_provider.dart';
import 'settings_screen.dart';
import '../widgets/current_weather_card.dart';
import '../widgets/daily_forecast.dart';
import '../widgets/hourly_forecast.dart';
import '../widgets/location_search.dart';
import '../widgets/weather_details.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<WeatherProvider>(
        builder: (context, provider, _) {
          return RefreshIndicator(
            onRefresh: provider.fetchWeather,
            color: Theme.of(context).colorScheme.primary,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                _WeatherAppBar(provider: provider),

                // ── Offline / cache banner ───────────────────────────────────
                if (provider.isOffline || provider.isShowingCache)
                  SliverToBoxAdapter(
                    child: _StatusBanner(provider: provider),
                  ),

                // ── Main content ─────────────────────────────────────────────
                if (provider.status == WeatherStatus.loading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (provider.status == WeatherStatus.error)
                  SliverFillRemaining(
                    child: _ErrorView(
                      message: provider.errorMessage ?? 'Неизвестная ошибка',
                      onRetry: provider.fetchWeather,
                    ),
                  )
                else if (provider.status == WeatherStatus.success &&
                    provider.weatherData != null)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        CurrentWeatherCard(
                          data: provider.weatherData!,
                          locationName: provider.selectedLocation?.name ?? '',
                        ),
                        const SizedBox(height: 16),
                        HourlyForecast(hourly: provider.weatherData!.hourly),
                        const SizedBox(height: 16),
                        DailyForecast(daily: provider.weatherData!.daily),
                        const SizedBox(height: 16),
                        WeatherDetails(data: provider.weatherData!),
                        const SizedBox(height: 16),
                        _UpdatedLabel(provider: provider),
                      ]),
                    ),
                  )
                else
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── App Bar ───────────────────────────────────────────────────────────────────

class _WeatherAppBar extends StatelessWidget {
  final WeatherProvider provider;
  const _WeatherAppBar({required this.provider});

  // Geolocation is supported on Android, iOS, Web, Windows, macOS.
  // geolocator does NOT support Linux.
  static bool get _locationSupported =>
      kIsWeb || !Platform.isLinux;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SliverAppBar(
      floating: true,
      snap: true,
      centerTitle: false,
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      title: InkWell(
        onTap: () => _openSearch(context),
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on_rounded, size: 18,
                  color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  provider.selectedLocation?.name ?? 'Выберите город',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              if (provider.selectedLocation?.country.isNotEmpty == true)
                Text(
                  provider.selectedLocation!.country,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded, size: 20,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
      actions: [
        // GPS button
        if (_locationSupported)
          provider.isLocating
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  onPressed: () => _onLocate(context),
                  icon: const Icon(Icons.my_location_rounded),
                  tooltip: 'Моё местоположение',
                ),

        // Refresh button
        if (provider.status == WeatherStatus.loading && !provider.isLocating)
          const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (!provider.isLocating)
          IconButton(
            onPressed: provider.fetchWeather,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Обновить',
          ),
        IconButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
          icon: const Icon(Icons.settings_rounded),
          tooltip: 'Настройки',
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  void _openSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LocationSearchSheet(),
    );
  }

  void _onLocate(BuildContext context) {
    context.read<WeatherProvider>().detectCurrentLocation().then((_) {
      final err = context.read<WeatherProvider>().locationError;
      if (err != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            ),
          ),
        );
      }
    });
  }
}

// ── Status banner (offline / cache) ──────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final WeatherProvider provider;
  const _StatusBanner({required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final offline = provider.isOffline;
    final cachedAt = provider.cachedAt;

    String label;
    if (offline) {
      label = 'Нет подключения';
      if (cachedAt != null) {
        final h = cachedAt.hour.toString().padLeft(2, '0');
        final m = cachedAt.minute.toString().padLeft(2, '0');
        label += ' — данные от $h:$m';
      }
    } else {
      label = 'Данные из кэша';
      if (cachedAt != null) {
        final age = DateTime.now().difference(cachedAt);
        final hLabel = age.inMinutes < 60
            ? '${age.inMinutes} мин. назад'
            : DateFormat('HH:mm').format(cachedAt);
        label += ' ($hLabel)';
      }
    }

    return Container(
      width: double.infinity,
      color: offline
          ? theme.colorScheme.errorContainer
          : theme.colorScheme.tertiaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            offline ? Icons.signal_wifi_off_rounded : Icons.history_rounded,
            size: 16,
            color: offline
                ? theme.colorScheme.onErrorContainer
                : theme.colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: offline
                    ? theme.colorScheme.onErrorContainer
                    : theme.colorScheme.onTertiaryContainer,
              ),
            ),
          ),
          if (offline)
            TextButton(
              onPressed: provider.fetchWeather,
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onErrorContainer,
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Обновить'),
            ),
        ],
      ),
    ).animate().slideY(begin: -1, duration: 300.ms, curve: Curves.easeOut);
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.thunderstorm_rounded,
            size: 72,
            color: Theme.of(context).colorScheme.primary,
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 24),
          Text('Что-то пошло не так',
              style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Попробовать снова'),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }
}

// ── Updated label ─────────────────────────────────────────────────────────────

class _UpdatedLabel extends StatelessWidget {
  final WeatherProvider provider;
  const _UpdatedLabel({required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fetchedAt = provider.weatherData?.fetchedAt ?? DateTime.now();
    final h = fetchedAt.hour.toString().padLeft(2, '0');
    final m = fetchedAt.minute.toString().padLeft(2, '0');
    final source = provider.isShowingCache ? ' (кэш)' : '';

    return Center(
      child: Text(
        'Обновлено в $h:$m$source • Open-Meteo API',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

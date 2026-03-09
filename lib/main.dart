// lib/main.dart

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'providers/settings_provider.dart';
import 'providers/weather_provider.dart';
import 'screens/home_screen.dart';
import 'services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru');

  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await HomeWidget.setAppGroupId('group.ru.matveyb9.test.weatherapp');
  }

  await BackgroundService.initialize();

  // Initialize settings before runApp so ThemeMode is known immediately.
  final settingsProvider = SettingsProvider();
  await settingsProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProxyProvider<SettingsProvider, WeatherProvider>(
          create: (_) {
            final wp = WeatherProvider();
            wp.attachSettings(settingsProvider);
            wp.initialize();
            return wp;
          },
          update: (_, settings, weather) {
            weather!.attachSettings(settings);
            return weather;
          },
        ),
      ],
      child: const WeatherApp(),
    ),
  );
}

class WeatherApp extends StatefulWidget {
  const WeatherApp({super.key});

  @override
  State<WeatherApp> createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    BackgroundService.registerPeriodicSync();

    if (!kIsWeb && Platform.isIOS) {
      _checkiOSWidgetRefreshFlag();
      HomeWidget.widgetClicked.listen(_onWidgetLaunchUrl);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      BackgroundService.syncNow();
    }
    if (state == AppLifecycleState.resumed && !kIsWeb && Platform.isIOS) {
      _checkiOSWidgetRefreshFlag();
    }
  }

  void _onWidgetLaunchUrl(Uri? uri) {
    if (uri?.scheme == 'weatherapp' && uri?.host == 'refresh') {
      _triggerRefresh();
    }
  }

  Future<void> _checkiOSWidgetRefreshFlag() async {
    try {
      final val = await HomeWidget.getWidgetData<bool>(
          'wg_refresh_requested', defaultValue: false);
      if (val == true) {
        await HomeWidget.saveWidgetData('wg_refresh_requested', false);
        _triggerRefresh();
      }
    } catch (_) {}
  }

  void _triggerRefresh() {
    if (!context.mounted) return;
    context.read<WeatherProvider>().fetchWeather();
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild MaterialApp only when theme setting changes.
    final themeMode = context.select<SettingsProvider, ThemeMode>(
      (s) => s.themeMode,
    );

    const seedColor = Color(0xFF1565C0);
    return MaterialApp(
      title: 'Погода',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      themeMode: themeMode,
      home: const HomeScreen(),
    );
  }
}

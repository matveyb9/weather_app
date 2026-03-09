// lib/providers/weather_provider.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/location_model.dart';
import '../models/settings_model.dart';
import '../models/weather_model.dart';
import '../services/cache_service.dart';
import '../services/geocoding_service.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';
import '../services/widget_service.dart';

enum WeatherStatus { initial, loading, success, error }

/// Why the currently displayed data was loaded from.
enum DataSource { network, cache }

class WeatherProvider extends ChangeNotifier {
  final _weatherService   = WeatherService();
  final _geocodingService = GeocodingService();

  /// Injected so internal fetchWeather calls always use current unit prefs.
  SettingsProvider? _settings;
  void attachSettings(SettingsProvider s) { _settings = s; }

  // Shorthand getters for current unit prefs (fall back to defaults if not set)
  TempUnit     get _tempUnit     => _settings?.tempUnit     ?? TempUnit.celsius;
  WindUnit     get _windUnit     => _settings?.windUnit     ?? WindUnit.ms;
  PressureUnit get _pressureUnit => _settings?.pressureUnit ?? PressureUnit.mmhg;


  WeatherStatus   _status          = WeatherStatus.initial;
  WeatherData?    _weatherData;
  LocationModel?  _selectedLocation;
  String?         _errorMessage;
  List<LocationModel> _searchResults = [];
  bool            _isSearching      = false;
  Timer?          _searchDebounce;

  // ── New state ────────────────────────────────────────────────────────────────
  DataSource      _dataSource       = DataSource.network;
  DateTime?       _cachedAt;           // when the cache was written
  bool            _isOffline        = false;
  bool            _isLocating       = false;  // GPS in progress
  String?         _locationError;             // geolocation error message

  // ── Getters ──────────────────────────────────────────────────────────────────
  WeatherStatus       get status          => _status;
  WeatherData?        get weatherData     => _weatherData;
  LocationModel?      get selectedLocation => _selectedLocation;
  String?             get errorMessage    => _errorMessage;
  List<LocationModel> get searchResults  => _searchResults;
  bool                get isSearching    => _isSearching;
  DataSource          get dataSource     => _dataSource;
  DateTime?           get cachedAt       => _cachedAt;
  bool                get isOffline      => _isOffline;
  bool                get isLocating     => _isLocating;
  String?             get locationError  => _locationError;

  /// True when showing cached (potentially stale) data.
  bool get isShowingCache => _dataSource == DataSource.cache;

  static const _locationKey = 'last_location';

  static const _defaultLocation = LocationModel(
    name: 'Москва', country: 'Russia', admin1: 'Moscow',
    latitude: 55.7558, longitude: 37.6173,
  );

  // ── Init ─────────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    // Restore last saved location
    try {
      final prefs = await SharedPreferences.getInstance();
      final json  = prefs.getString(_locationKey);
      _selectedLocation = json != null
          ? LocationModel.fromJson(jsonDecode(json) as Map<String, dynamic>)
          : _defaultLocation;
    } catch (_) {
      _selectedLocation = _defaultLocation;
    }

    await fetchWeather();
  }

  // ── Weather fetch (main entry point) ─────────────────────────────────────────

  Future<void> fetchWeather() async {
    if (_selectedLocation == null) return;

    _status       = WeatherStatus.loading;
    _errorMessage = null;
    notifyListeners();

    // Check connectivity first
    final online = await _checkConnectivity();

    if (online) {
      await _fetchFromNetwork();
    } else {
      await _loadFromCache(offlineFallback: true);
    }

    notifyListeners();
  }

  Future<void> _fetchFromNetwork() async {
    try {
      final rawJson = await _weatherService.getWeatherRaw(
        _selectedLocation!.latitude,
        _selectedLocation!.longitude,
      );

      // Save to cache immediately
      await CacheService.saveWeather(rawJson: rawJson, location: _selectedLocation!);

      _weatherData = WeatherData.fromJson(
          jsonDecode(rawJson) as Map<String, dynamic>);
      _status     = WeatherStatus.success;
      _dataSource = DataSource.network;
      _isOffline  = false;
      _cachedAt   = null;

      // Push to home-screen widgets
      await WidgetService.updateWidgets(
        data:         _weatherData!,
        cityName:     _selectedLocation!.name,
        latitude:     _selectedLocation!.latitude,
        longitude:    _selectedLocation!.longitude,
        tempUnit:     _tempUnit,
        windUnit:     _windUnit,
        pressureUnit: _pressureUnit,
      );
    } catch (e) {
      debugPrint('WeatherProvider._fetchFromNetwork error: $e');
      // Network failed → try cache
      final loaded = await _loadFromCache(offlineFallback: false);
      if (!loaded) {
        _status       = WeatherStatus.error;
        _errorMessage = 'Не удалось загрузить погоду.\nПроверьте подключение к интернету.';
      }
    }
  }

  /// Load cached data. Returns true if cache was available.
  /// [offlineFallback]: if true, show a "you are offline" banner.
  Future<bool> _loadFromCache({required bool offlineFallback}) async {
    final cached = await CacheService.loadWeather();
    if (cached == null) return false;

    _weatherData = cached.data;
    _status      = WeatherStatus.success;
    _dataSource  = DataSource.cache;
    _cachedAt    = cached.fetchedAt;
    _isOffline   = offlineFallback;

    // Restore cached location if it differs from what the cache stored
    if (_selectedLocation == null ||
        (_selectedLocation!.latitude  != cached.location.latitude ||
         _selectedLocation!.longitude != cached.location.longitude)) {
      _selectedLocation = cached.location;
    }
    return true;
  }

  // ── Connectivity ──────────────────────────────────────────────────────────────

  Future<bool> _checkConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      // connectivity_plus returns a list; we're online if any result ≠ none
      return results.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      return true; // assume online if we can't determine
    }
  }

  // ── Geolocation ───────────────────────────────────────────────────────────────

  Future<void> detectCurrentLocation() async {
    _isLocating    = true;
    _locationError = null;
    notifyListeners();

    final (:location, :result) = await LocationService.getCurrentLocation();

    _isLocating = false;

    if (result == LocationResult.success && location != null) {
      _locationError = null;
      await selectLocation(location);    // saves + fetches weather
    } else {
      _locationError = LocationService.errorMessage(result);
      notifyListeners();
    }
  }

  // ── Search ────────────────────────────────────────────────────────────────────

  void searchLocations(String query) {
    _searchDebounce?.cancel();
    if (query.trim().isEmpty) {
      _searchResults = []; _isSearching = false; notifyListeners(); return;
    }
    _isSearching = true;
    notifyListeners();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        _searchResults = await _geocodingService.searchLocations(query);
      } catch (e) {
        _searchResults = [];
        debugPrint('Search error: $e');
      } finally {
        _isSearching = false;
        notifyListeners();
      }
    });
  }

  void clearSearch() {
    _searchDebounce?.cancel();
    _searchResults = []; _isSearching = false;
    notifyListeners();
  }

  // ── Location selection ────────────────────────────────────────────────────────

  Future<void> selectLocation(LocationModel location) async {
    _selectedLocation = location;
    clearSearch();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_locationKey, jsonEncode(location.toJson()));
    } catch (e) {
      debugPrint('Failed to save location: $e');
    }
    await fetchWeather();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}

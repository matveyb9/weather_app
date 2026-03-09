// lib/models/weather_model.dart

class CurrentWeather {
  final double temperature;
  final double apparentTemperature;
  final int weatherCode;
  final double windSpeed;
  final int windDirection;
  final int humidity;
  final double precipitation;
  final double pressureMsl;
  final int uvIndex;
  final bool isDay;

  const CurrentWeather({
    required this.temperature,
    required this.apparentTemperature,
    required this.weatherCode,
    required this.windSpeed,
    required this.windDirection,
    required this.humidity,
    required this.precipitation,
    required this.pressureMsl,
    required this.uvIndex,
    required this.isDay,
  });

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    return CurrentWeather(
      temperature: (json['temperature_2m'] as num).toDouble(),
      apparentTemperature: (json['apparent_temperature'] as num).toDouble(),
      weatherCode: (json['weather_code'] as num).toInt(),
      windSpeed: (json['wind_speed_10m'] as num).toDouble(),
      windDirection: (json['wind_direction_10m'] as num).toInt(),
      humidity: (json['relative_humidity_2m'] as num).toInt(),
      precipitation: (json['precipitation'] as num).toDouble(),
      pressureMsl: (json['pressure_msl'] as num).toDouble(),
      uvIndex: (json['uv_index'] as num? ?? 0).toInt(),
      isDay: (json['is_day'] as num).toInt() == 1,
    );
  }
}

class HourlyWeather {
  final DateTime time;
  final double temperature;
  final int weatherCode;
  final double precipitation;
  final int humidity;
  final bool isDay;

  const HourlyWeather({
    required this.time,
    required this.temperature,
    required this.weatherCode,
    required this.precipitation,
    required this.humidity,
    required this.isDay,
  });
}

class DailyWeather {
  final DateTime date;
  final double maxTemperature;
  final double minTemperature;
  final int weatherCode;
  final double precipitationSum;
  final double maxWindSpeed;
  final String sunrise;
  final String sunset;

  const DailyWeather({
    required this.date,
    required this.maxTemperature,
    required this.minTemperature,
    required this.weatherCode,
    required this.precipitationSum,
    required this.maxWindSpeed,
    required this.sunrise,
    required this.sunset,
  });
}

class WeatherData {
  final CurrentWeather current;
  final List<HourlyWeather> hourly;
  final List<DailyWeather> daily;
  final String timezone;
  final double latitude;
  final double longitude;
  final DateTime fetchedAt;

  const WeatherData({
    required this.current,
    required this.hourly,
    required this.daily,
    required this.timezone,
    required this.latitude,
    required this.longitude,
    required this.fetchedAt,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final current =
        CurrentWeather.fromJson(json['current'] as Map<String, dynamic>);

    // ---------- Hourly ----------
    final hourlyJson = json['hourly'] as Map<String, dynamic>;
    final hTimes = (hourlyJson['time'] as List).cast<String>();
    final hTemps = (hourlyJson['temperature_2m'] as List)
        .map((e) => (e as num).toDouble())
        .toList();
    final hCodes = (hourlyJson['weather_code'] as List)
        .map((e) => (e as num).toInt())
        .toList();
    final hPrecip = (hourlyJson['precipitation'] as List)
        .map((e) => (e as num).toDouble())
        .toList();
    final hHumidity = (hourlyJson['relative_humidity_2m'] as List)
        .map((e) => (e as num).toInt())
        .toList();
    final hIsDay = (hourlyJson['is_day'] as List)
        .map((e) => (e as num).toInt() == 1)
        .toList();

    final now = DateTime.now();
    final hourly = <HourlyWeather>[];
    for (int i = 0; i < hTimes.length && hourly.length < 25; i++) {
      final t = DateTime.parse(hTimes[i]);
      if (t.isAfter(now.subtract(const Duration(minutes: 30)))) {
        hourly.add(HourlyWeather(
          time: t,
          temperature: hTemps[i],
          weatherCode: hCodes[i],
          precipitation: hPrecip[i],
          humidity: hHumidity[i],
          isDay: hIsDay[i],
        ));
      }
    }

    // ---------- Daily ----------
    final dailyJson = json['daily'] as Map<String, dynamic>;
    final dDates = (dailyJson['time'] as List).cast<String>();
    final dMaxT = (dailyJson['temperature_2m_max'] as List)
        .map((e) => (e as num).toDouble())
        .toList();
    final dMinT = (dailyJson['temperature_2m_min'] as List)
        .map((e) => (e as num).toDouble())
        .toList();
    final dCodes = (dailyJson['weather_code'] as List)
        .map((e) => (e as num).toInt())
        .toList();
    final dPrecip = (dailyJson['precipitation_sum'] as List)
        .map((e) => (e as num).toDouble())
        .toList();
    final dWind = (dailyJson['wind_speed_10m_max'] as List)
        .map((e) => (e as num).toDouble())
        .toList();
    final dSunrise = (dailyJson['sunrise'] as List).cast<String>();
    final dSunset = (dailyJson['sunset'] as List).cast<String>();

    final daily = List.generate(
      dDates.length,
      (i) => DailyWeather(
        date: DateTime.parse(dDates[i]),
        maxTemperature: dMaxT[i],
        minTemperature: dMinT[i],
        weatherCode: dCodes[i],
        precipitationSum: dPrecip[i],
        maxWindSpeed: dWind[i],
        sunrise: dSunrise[i],
        sunset: dSunset[i],
      ),
    );

    return WeatherData(
      current: current,
      hourly: hourly,
      daily: daily,
      timezone: json['timezone'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      fetchedAt: DateTime.now(),
    );
  }
}

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AirQualityApiResponse {
  const AirQualityApiResponse({
    required this.temperature,
    required this.relativeHumidity,
    required this.windSpeed,
    required this.uvIndex,
    required this.pm25,
    required this.pm10,
    this.dust,
    this.pollen,
    required this.no2,
    required this.o3,
    required this.pm25Hourly,
    required this.usAqiHourly,
  });

  final double temperature;
  final double relativeHumidity;
  final double windSpeed;
  final double uvIndex;
  final double pm25;
  final double pm10;
  final double? dust;
  final double? pollen;
  final double no2;
  final double o3;
  final List<HourlyPm25Point> pm25Hourly;
  final List<HourlyUsAqiPoint> usAqiHourly;
}

class HourlyPm25Point {
  const HourlyPm25Point({required this.time, required this.pm25});

  final DateTime time;
  final double pm25;
}

class HourlyUsAqiPoint {
  const HourlyUsAqiPoint({required this.time, required this.usAqi});

  final DateTime time;
  final double usAqi;
}

class AirQualityApiClient {
  AirQualityApiClient({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  static const _weatherBaseUrl = 'https://api.open-meteo.com/v1/forecast';
  static const _airBaseUrl =
      'https://air-quality-api.open-meteo.com/v1/air-quality';

  Future<AirQualityApiResponse> fetch({
    required double latitude,
    required double longitude,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint(
          '[AQ API] fetch lat=${latitude.toStringAsFixed(2)} lon=${longitude.toStringAsFixed(2)}',
        );
      }
      final weatherFuture = _dio.get<Map<String, dynamic>>(
        _weatherBaseUrl,
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'current':
              'temperature_2m,relative_humidity_2m,wind_speed_10m,uv_index',
          'timezone': 'auto',
        },
      );

      final airFuture = _dio.get<Map<String, dynamic>>(
        _airBaseUrl,
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'current': 'pm2_5,pm10,nitrogen_dioxide,ozone',
          'hourly': 'us_aqi,pm2_5,pm10,dust,uv_index',
          'forecast_days': 7,
          'timezone': 'auto',
        },
      );

      final responses = await Future.wait([weatherFuture, airFuture]);
      final weather = responses[0].data;
      final air = responses[1].data;

      if (kDebugMode) {
        debugPrint('[AQ API] weather keys: ${weather?.keys.toList()}');
        debugPrint('[AQ API] air keys: ${air?.keys.toList()}');
      }

      if (weather == null || air == null) {
        throw const AirQualityApiException('Open-Meteo response is empty.');
      }

      final weatherCurrent = weather['current'] as Map<String, dynamic>?;
      final airCurrent = air['current'] as Map<String, dynamic>?;
      final airHourly = air['hourly'] as Map<String, dynamic>?;

      if (weatherCurrent == null || airCurrent == null || airHourly == null) {
        throw const AirQualityApiException(
          'Open-Meteo current/hourly data is missing.',
        );
      }

      final hourlyTimesRaw = airHourly['time'] as List<dynamic>?;
      final hourlyPm25Raw = airHourly['pm2_5'] as List<dynamic>?;
      final hourlyUsAqiRaw = airHourly['us_aqi'] as List<dynamic>?;
      if (hourlyTimesRaw == null ||
          hourlyPm25Raw == null ||
          hourlyUsAqiRaw == null) {
        throw const AirQualityApiException(
          'Open-Meteo hourly forecast data is missing.',
        );
      }

      final pm25Hourly = _parseHourlyPm25(
        times: hourlyTimesRaw,
        pm25Values: hourlyPm25Raw,
      );
      final usAqiHourly = _parseHourlyUsAqi(
        times: hourlyTimesRaw,
        aqiValues: hourlyUsAqiRaw,
      );

      if (kDebugMode) {
        debugPrint(
          '[AQ API] hourly parsed => pm25=${pm25Hourly.length}, us_aqi=${usAqiHourly.length}',
        );
        if (usAqiHourly.isNotEmpty) {
          debugPrint(
            '[AQ API] us_aqi sample first=${usAqiHourly.first.usAqi} last=${usAqiHourly.last.usAqi}',
          );
        }
      }

      return AirQualityApiResponse(
        temperature: _toDouble(weatherCurrent['temperature_2m']),
        relativeHumidity: _toDouble(weatherCurrent['relative_humidity_2m']),
        windSpeed: _toDouble(weatherCurrent['wind_speed_10m']),
        uvIndex: _toDouble(weatherCurrent['uv_index']),
        pm25: _toDouble(airCurrent['pm2_5']),
        pm10: _toDouble(airCurrent['pm10']),
        dust: _toNullableDouble(airCurrent['dust']),
        pollen: _toNullableDouble(airCurrent['pollen']),
        no2: _toDouble(airCurrent['nitrogen_dioxide']),
        o3: _toDouble(airCurrent['ozone']),
        pm25Hourly: pm25Hourly,
        usAqiHourly: usAqiHourly,
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (kDebugMode) {
        debugPrint(
          '[AQ API] DioException status=$statusCode message=${e.message}',
        );
      }
      throw AirQualityApiException(
        statusCode == null
            ? 'Failed to connect to Open-Meteo. Please check your connection.'
            : 'Open-Meteo request failed (HTTP $statusCode).',
      );
    } on AirQualityApiException {
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AQ API] Unexpected error: $e');
      }
      throw const AirQualityApiException(
        'Unexpected error when reading Open-Meteo data.',
      );
    }
  }

  double _toDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    throw const AirQualityApiException(
      'Unexpected number format from Open-Meteo.',
    );
  }

  double? _toNullableDouble(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return null;
  }

  List<HourlyPm25Point> _parseHourlyPm25({
    required List<dynamic> times,
    required List<dynamic> pm25Values,
  }) {
    final points = <HourlyPm25Point>[];
    final length = times.length < pm25Values.length
        ? times.length
        : pm25Values.length;

    for (var i = 0; i < length; i++) {
      final timeRaw = times[i];
      final pm25Raw = pm25Values[i];
      if (timeRaw is! String) {
        continue;
      }
      if (pm25Raw is! num) {
        continue;
      }
      final parsedTime = DateTime.tryParse(timeRaw);
      if (parsedTime == null) {
        continue;
      }
      points.add(HourlyPm25Point(time: parsedTime, pm25: pm25Raw.toDouble()));
    }

    return points;
  }

  List<HourlyUsAqiPoint> _parseHourlyUsAqi({
    required List<dynamic> times,
    required List<dynamic> aqiValues,
  }) {
    final points = <HourlyUsAqiPoint>[];
    final length = times.length < aqiValues.length
        ? times.length
        : aqiValues.length;

    for (var i = 0; i < length; i++) {
      final timeRaw = times[i];
      final aqiRaw = aqiValues[i];
      if (timeRaw is! String || aqiRaw is! num) {
        continue;
      }
      final parsedTime = DateTime.tryParse(timeRaw);
      if (parsedTime == null) {
        continue;
      }
      points.add(HourlyUsAqiPoint(time: parsedTime, usAqi: aqiRaw.toDouble()));
    }

    return points;
  }
}

class AirQualityApiException implements Exception {
  const AirQualityApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

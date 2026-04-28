import 'package:flutter/foundation.dart';

import '../domain/air_insight_generator.dart';
import '../domain/air_quality_model.dart';
import '../domain/aqi_calculator.dart';
import 'air_quality_api_client.dart';
import 'air_quality_cache.dart';

class AirQualityFetchResult {
  const AirQualityFetchResult({
    required this.data,
    required this.fromCache,
    required this.throttled,
    required this.lastUpdatedAt,
    required this.remainingThrottle,
  });

  final AirQualityModel data;
  final bool fromCache;
  final bool throttled;
  final DateTime lastUpdatedAt;
  final Duration remainingThrottle;
}

class AirQualityRepository {
  AirQualityRepository({
    required AirQualityApiClient apiClient,
    required AirQualityCache cache,
    AqiCalculator? aqiCalculator,
    AirInsightGenerator? insightGenerator,
  }) : _apiClient = apiClient,
       _cache = cache,
       _aqiCalculator = aqiCalculator ?? const AqiCalculator(),
       _insightGenerator = insightGenerator ?? const AirInsightGenerator();

  final AirQualityApiClient _apiClient;
  final AirQualityCache _cache;
  final AqiCalculator _aqiCalculator;
  final AirInsightGenerator _insightGenerator;

  Future<AirQualityFetchResult> fetch({
    required double latitude,
    required double longitude,
    required String cityLabel,
    required bool usingDefaultLocation,
    bool forceRefresh = false,
  }) async {
    final now = DateTime.now();
    final cached = _cache.get(latitude, longitude);

    if (cached != null && _cache.isFresh(cached, now)) {
      if (kDebugMode) {
        debugPrint('[AQ REPO] return fresh cache');
      }
      final remaining = _cache.remainingThrottle(cached, now);
      return AirQualityFetchResult(
        data: cached.data,
        fromCache: true,
        throttled: forceRefresh,
        lastUpdatedAt: cached.lastFetchedAt,
        remainingThrottle: remaining,
      );
    }

    try {
      if (kDebugMode) {
        debugPrint('[AQ REPO] fetching from API...');
      }
      final response = await _apiClient.fetch(
        latitude: latitude,
        longitude: longitude,
      );
      final aqiResult = _aqiCalculator.fromPm25(response.pm25);
      final forecast7Days = _build7DayForecast(
        response.usAqiHourly,
        response.pm25Hourly,
      );
      if (kDebugMode) {
        debugPrint('[AQ REPO] forecast7Days count=${forecast7Days.length}');
        if (forecast7Days.isNotEmpty) {
          final first = forecast7Days.first;
          debugPrint(
            '[AQ REPO] forecast first: ${first.dayLabel} aqi=${first.aqi} status=${first.status}',
          );
        }
      }

      final data = AirQualityModel(
        cityLabel: cityLabel,
        latitude: latitude,
        longitude: longitude,
        temperature: response.temperature,
        relativeHumidity: response.relativeHumidity,
        windSpeed: response.windSpeed,
        uvIndex: response.uvIndex,
        pm25: response.pm25,
        pm10: response.pm10,
        no2: response.no2,
        o3: response.o3,
        aqi: aqiResult.aqi,
        aqiStatus: aqiResult.label,
        aqiCategory: aqiResult.category,
        insight: _insightGenerator.generate(aqiResult.category),
        fetchedAt: now,
        usingDefaultLocation: usingDefaultLocation,
        forecast7Days: forecast7Days,
      );

      _cache.save(
        AirQualityCacheEntry(
          data: data,
          lastFetchedAt: now,
          latitude: latitude,
          longitude: longitude,
        ),
      );

      return AirQualityFetchResult(
        data: data,
        fromCache: false,
        throttled: false,
        lastUpdatedAt: now,
        remainingThrottle: AirQualityCache.throttleDuration,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AQ REPO] fetch error: $e');
      }
      if (cached != null) {
        if (kDebugMode) {
          debugPrint('[AQ REPO] fallback to stale cache');
        }
        return AirQualityFetchResult(
          data: cached.data,
          fromCache: true,
          throttled: false,
          lastUpdatedAt: cached.lastFetchedAt,
          remainingThrottle: _cache.remainingThrottle(cached, now),
        );
      }

      rethrow;
    }
  }

  List<DailyAqiForecast> _build7DayForecast(
    List<HourlyUsAqiPoint> usAqiPoints,
    List<HourlyPm25Point> pm25Points,
  ) {
    if (usAqiPoints.isEmpty && pm25Points.isEmpty) {
      return const [];
    }

    final byDateAqi = <DateTime, List<double>>{};
    for (final point in usAqiPoints) {
      final key = DateTime(point.time.year, point.time.month, point.time.day);
      byDateAqi.putIfAbsent(key, () => <double>[]).add(point.usAqi);
    }

    final byDatePm25 = <DateTime, List<double>>{};
    for (final point in pm25Points) {
      final key = DateTime(point.time.year, point.time.month, point.time.day);
      byDatePm25.putIfAbsent(key, () => <double>[]).add(point.pm25);
    }

    final dates = {...byDateAqi.keys, ...byDatePm25.keys}.toList()..sort();
    final forecast = <DailyAqiForecast>[];

    for (var i = 0; i < dates.length && forecast.length < 7; i++) {
      final date = dates[i];
      final aqiValues = byDateAqi[date];
      final pm25Values = byDatePm25[date];

      if ((aqiValues == null || aqiValues.isEmpty) &&
          (pm25Values == null || pm25Values.isEmpty)) {
        continue;
      }

      late final AqiResult result;
      if (aqiValues != null && aqiValues.isNotEmpty) {
        final avgAqi = (aqiValues.reduce((a, b) => a + b) / aqiValues.length)
            .round()
            .clamp(0, 500);
        result = _aqiFromUsAqi(avgAqi);
      } else {
        final avgPm25 = pm25Values!.reduce((a, b) => a + b) / pm25Values.length;
        result = _aqiCalculator.fromPm25(avgPm25);
      }

      forecast.add(
        DailyAqiForecast(
          date: date,
          dayLabel: i == 0 ? 'Today' : _weekdayShort(date.weekday),
          aqi: result.aqi,
          status: result.label,
          category: result.category,
        ),
      );
    }

    return forecast;
  }

  AqiResult _aqiFromUsAqi(int aqi) {
    if (aqi <= 50) {
      return AqiResult(aqi: aqi, label: 'Good', category: AqiCategory.good);
    }
    if (aqi <= 100) {
      return AqiResult(
        aqi: aqi,
        label: 'Moderate',
        category: AqiCategory.moderate,
      );
    }
    if (aqi <= 150) {
      return AqiResult(
        aqi: aqi,
        label: 'Unhealthy for Sensitive Groups',
        category: AqiCategory.unhealthySensitive,
      );
    }
    if (aqi <= 200) {
      return AqiResult(
        aqi: aqi,
        label: 'Unhealthy',
        category: AqiCategory.unhealthy,
      );
    }
    if (aqi <= 300) {
      return AqiResult(
        aqi: aqi,
        label: 'Very Unhealthy',
        category: AqiCategory.veryUnhealthy,
      );
    }
    return AqiResult(
      aqi: aqi,
      label: 'Hazardous',
      category: AqiCategory.hazardous,
    );
  }

  String _weekdayShort(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      case DateTime.sunday:
        return 'Sun';
      default:
        return '-';
    }
  }
}

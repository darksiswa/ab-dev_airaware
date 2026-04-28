import 'package:flutter/foundation.dart';

import '../../location/location_service.dart';
import '../data/air_quality_cache.dart';
import '../data/air_quality_repository.dart';
import '../domain/air_quality_model.dart';

enum AirQualityViewState { initial, loading, loaded, error }

class AirQualityController extends ChangeNotifier {
  AirQualityController({
    required AirQualityRepository repository,
    required LocationService locationService,
  }) : _repository = repository,
       _locationService = locationService;

  final AirQualityRepository _repository;
  final LocationService _locationService;

  AirQualityViewState state = AirQualityViewState.initial;
  AirQualityModel? data;
  String? errorMessage;
  DateTime? lastUpdatedAt;
  String? infoMessage;

  LocationFetchStatus? locationStatus;
  bool usingDefaultLocation = true;
  String locationLabel = LocationService.defaultCityLabel;
  double _latitude = LocationService.defaultLatitude;
  double _longitude = LocationService.defaultLongitude;

  bool get isLoading => state == AirQualityViewState.loading;

  Duration get remainingThrottleDuration {
    if (lastUpdatedAt == null) {
      return Duration.zero;
    }
    final elapsed = DateTime.now().difference(lastUpdatedAt!);
    final remaining = AirQualityCache.throttleDuration - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get canRefresh => remainingThrottleDuration == Duration.zero;

  String get locationStatusText {
    if (usingDefaultLocation) {
      return 'Using default city: ${LocationService.defaultCityLabel}';
    }
    return 'Using your area';
  }

  bool get shouldShowRetryLocation {
    return locationStatus == LocationFetchStatus.denied ||
        locationStatus == LocationFetchStatus.deniedForever ||
        locationStatus == LocationFetchStatus.serviceDisabled;
  }

  Future<void> initialize() async {
    await _load(requestLocation: true, forceRefresh: false, silent: false);
  }

  Future<void> retryLocation() async {
    await _load(requestLocation: true, forceRefresh: false, silent: false);
  }

  Future<void> manualRefresh() async {
    if (!canRefresh) {
      infoMessage =
          'Data was refreshed recently. Please try again in ${_minutesAndSeconds(remainingThrottleDuration)}.';
      notifyListeners();
      return;
    }

    await _load(requestLocation: false, forceRefresh: true, silent: true);
  }

  Future<void> openLocationSettings() async {
    await _locationService.openSettings();
  }

  Future<void> _load({
    required bool requestLocation,
    required bool forceRefresh,
    required bool silent,
  }) async {
    if (kDebugMode) {
      debugPrint(
        '[AQ CTRL] load start requestLocation=$requestLocation forceRefresh=$forceRefresh silent=$silent',
      );
    }
    if (!silent) {
      state = AirQualityViewState.loading;
    }
    errorMessage = null;
    infoMessage = null;
    notifyListeners();

    try {
      if (requestLocation || state == AirQualityViewState.initial) {
        final locationResult = await _locationService.getLocation();
        locationStatus = locationResult.status;
        usingDefaultLocation = locationResult.usingDefault;
        locationLabel = locationResult.cityLabel;
        _latitude = _roundTo2(locationResult.point.latitude);
        _longitude = _roundTo2(locationResult.point.longitude);
        if (kDebugMode) {
          debugPrint(
            '[AQ CTRL] location status=${locationResult.status} label=$locationLabel lat=${_latitude.toStringAsFixed(2)} lon=${_longitude.toStringAsFixed(2)}',
          );
        }
      }

      final result = await _repository.fetch(
        latitude: _latitude,
        longitude: _longitude,
        cityLabel: locationLabel,
        usingDefaultLocation: usingDefaultLocation,
        forceRefresh: forceRefresh,
      );

      data = result.data;
      lastUpdatedAt = result.lastUpdatedAt;
      state = AirQualityViewState.loaded;
      if (kDebugMode) {
        debugPrint(
          '[AQ CTRL] loaded fromCache=${result.fromCache} throttled=${result.throttled} forecastCount=${data?.forecast7Days.length}',
        );
      }

      if (result.throttled) {
        infoMessage =
            'Data was refreshed recently. Please try again in ${_minutesAndSeconds(result.remainingThrottle)}.';
      } else if (result.fromCache) {
        infoMessage = 'Showing cached data from the last update.';
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AQ CTRL] error: $e');
      }
      state = AirQualityViewState.error;
      errorMessage = e.toString();
      if (data != null) {
        state = AirQualityViewState.loaded;
        infoMessage = 'Could not refresh. Showing previously cached data.';
      }
    }

    notifyListeners();
  }

  String _minutesAndSeconds(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes > 0) {
      return '$minutes minute${minutes == 1 ? '' : 's'}';
    }
    return '$seconds second${seconds == 1 ? '' : 's'}';
  }

  double _roundTo2(double value) => (value * 100).roundToDouble() / 100;
}

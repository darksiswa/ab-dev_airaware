import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationPoint {
  const LocationPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

enum LocationFetchStatus {
  granted,
  recentArea,
  denied,
  deniedForever,
  serviceDisabled,
  fallbackDefault,
}

class LocationFetchResult {
  const LocationFetchResult({
    required this.status,
    required this.point,
    required this.usingDefault,
    required this.cityLabel,
    required this.source,
  });

  final LocationFetchStatus status;
  final LocationPoint point;
  final bool usingDefault;
  final String cityLabel;
  final String source;
}

class LocationService {
  static const double defaultLatitude = -6.2088;
  static const double defaultLongitude = 106.8456;
  static const String defaultCityLabel = 'Jakarta';

  static const Duration _debugLocationTimeout = Duration(seconds: 20);
  static const Duration _releaseLocationTimeout = Duration(seconds: 15);
  static const Duration _geocodingTimeout = Duration(seconds: 4);
  static const Duration _maxLastKnownAge = Duration(minutes: 3);
  static const Duration _startupLastKnownMaxAge = Duration(minutes: 30);

  Future<LocationFetchResult?> getRecentLastKnownForStartup() async {
    final canAccess = await _ensureServiceAndPermission();
    if (!canAccess) {
      return null;
    }

    final lastKnown = await Geolocator.getLastKnownPosition();
    if (lastKnown == null) {
      if (kDebugMode) {
        debugPrint('[LOC] startup lastKnown exists=false');
      }
      return null;
    }

    final age = DateTime.now().difference(lastKnown.timestamp);
    if (kDebugMode) {
      debugPrint('[LOC] startup lastKnown ageSec=${age.inSeconds}');
    }
    if (age <= _startupLastKnownMaxAge) {
      if (kDebugMode) {
        debugPrint('[LOC] source=recentLastKnown');
      }
      return _resultFromPosition(
        lastKnown,
        status: LocationFetchStatus.recentArea,
        source: 'recentLastKnown',
      );
    }

    if (kDebugMode) {
      debugPrint('[LOC] startup lastKnown rejected ageSec=${age.inSeconds}');
    }
    return null;
  }

  Future<LocationFetchResult?> getFreshCurrentLocation({
    bool allowRecentLastKnownFallback = false,
    Duration fallbackMaxAge = _maxLastKnownAge,
  }) async {
    final canAccess = await _ensureServiceAndPermission();
    if (!canAccess) {
      return null;
    }
    return _tryFreshCurrentThenOptionalLastKnown(
      allowRecentLastKnownFallback: allowRecentLastKnownFallback,
      fallbackMaxAge: fallbackMaxAge,
    );
  }

  Future<LocationFetchResult> getLocation() async {
    try {
      final canAccess = await _ensureServiceAndPermission();
      if (!canAccess) {
        final status = await _defaultStatusForDeniedAccess();
        return _defaultResult(status);
      }

      final result = await _tryFreshCurrentThenOptionalLastKnown(
        allowRecentLastKnownFallback: true,
        fallbackMaxAge: _maxLastKnownAge,
      );
      if (result != null) {
        return result;
      }
      return _defaultResult(LocationFetchStatus.fallbackDefault);
    } catch (_) {
      return _defaultResult(LocationFetchStatus.fallbackDefault);
    }
  }

  Stream<LocationFetchResult> watchApproximateAreaChanges() {
    return Geolocator.getPositionStream(
      locationSettings: _streamLocationSettings(),
    ).asyncMap(
    (position) => _resultFromPosition(
        position,
        status: LocationFetchStatus.granted,
        source: 'streamFirst',
      ),
    );
  }

  Future<void> openSettings() => Geolocator.openAppSettings();

  Future<LocationFetchResult> _resultFromPosition(
    Position position, {
    required LocationFetchStatus status,
    required String source,
  }) async {
    final roundedLat = _roundTo2(position.latitude);
    final roundedLon = _roundTo2(position.longitude);
    final areaLabel = await _resolveAreaLabel(
      latitude: roundedLat,
      longitude: roundedLon,
    );

    if (kDebugMode) {
      debugPrint(
        '[LOC] resolved status=$status lat=${roundedLat.toStringAsFixed(2)} lon=${roundedLon.toStringAsFixed(2)} label=$areaLabel',
      );
    }

    return LocationFetchResult(
      status: status,
      point: LocationPoint(latitude: roundedLat, longitude: roundedLon),
      usingDefault: false,
      cityLabel: areaLabel,
      source: source,
    );
  }

  LocationFetchResult _defaultResult(LocationFetchStatus status) {
    return LocationFetchResult(
      status: status,
      point: const LocationPoint(
        latitude: defaultLatitude,
        longitude: defaultLongitude,
      ),
      usingDefault: true,
      cityLabel: defaultCityLabel,
      source: 'default',
    );
  }

  double _roundTo2(double value) => (value * 100).roundToDouble() / 100;

  Future<String> _resolveAreaLabel({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      ).timeout(_geocodingTimeout);
      if (placemarks.isEmpty) {
        return 'Your area';
      }

      final placemark = placemarks.first;
      final district = _clean(placemark.subLocality) ?? _clean(placemark.locality);
      final city =
          _clean(placemark.subAdministrativeArea) ?? _clean(placemark.administrativeArea);

      if (district != null &&
          city != null &&
          district.toLowerCase() != city.toLowerCase()) {
        return '$district, $city';
      }
      if (district != null) {
        return district;
      }
      if (city != null) {
        return city;
      }
      return 'Your area';
    } catch (_) {
      return 'Your area';
    }
  }

  String? _clean(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  LocationSettings _requestLocationSettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
      );
    }
    return const LocationSettings(accuracy: LocationAccuracy.high);
  }

  LocationSettings _streamLocationSettings() {
    final distanceFilter = kDebugMode ? 100 : 1000;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.medium,
        intervalDuration: Duration(minutes: 1),
        distanceFilter: distanceFilter,
      );
    }
    return LocationSettings(
      accuracy: LocationAccuracy.medium,
      distanceFilter: distanceFilter,
    );
  }

  Duration get _activeLocationTimeout {
    return kDebugMode ? _debugLocationTimeout : _releaseLocationTimeout;
  }

  Future<bool> _ensureServiceAndPermission() async {
    if (kDebugMode) {
      debugPrint('[LOC] step=1 checkServiceEnabled');
    }
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (kDebugMode) {
      debugPrint('[LOC] serviceEnabled=$serviceEnabled');
    }
    if (!serviceEnabled) {
      return false;
    }

    if (kDebugMode) {
      debugPrint('[LOC] step=2 checkPermission');
    }
    var permission = await Geolocator.checkPermission();
    if (kDebugMode) {
      debugPrint('[LOC] permission initial=$permission');
    }
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (kDebugMode) {
        debugPrint('[LOC] permission after request=$permission');
      }
    }

    return permission != LocationPermission.denied &&
        permission != LocationPermission.deniedForever;
  }

  Future<LocationFetchStatus> _defaultStatusForDeniedAccess() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (kDebugMode) {
        debugPrint('[LOC] service disabled -> fallback default');
      }
      return LocationFetchStatus.serviceDisabled;
    }
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      if (kDebugMode) {
        debugPrint('[LOC] permission denied forever -> fallback default');
      }
      return LocationFetchStatus.deniedForever;
    }
    if (kDebugMode) {
      debugPrint('[LOC] permission denied -> fallback default');
    }
    return LocationFetchStatus.denied;
  }

  Future<LocationFetchResult?> _tryFreshCurrentThenOptionalLastKnown({
    required bool allowRecentLastKnownFallback,
    required Duration fallbackMaxAge,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint(
          '[LOC] step=3 getCurrentPosition start timeoutSec=${_activeLocationTimeout.inSeconds}',
        );
        debugPrint('[LOC] fresh request started');
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: _requestLocationSettings(),
      ).timeout(_activeLocationTimeout);
      if (kDebugMode) {
        debugPrint('[LOC] fresh request succeeded');
        debugPrint('[LOC] source=currentArea');
      }
      return _resultFromPosition(
        position,
        status: LocationFetchStatus.granted,
        source: 'currentArea',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LOC] fresh request failed type=${e.runtimeType}');
      }
      if (!allowRecentLastKnownFallback) {
        return null;
      }
    }

    final lastKnown = await Geolocator.getLastKnownPosition();
    if (lastKnown == null) {
      if (kDebugMode) {
        debugPrint('[LOC] getLastKnownPosition exists=false');
      }
      return null;
    }

    final age = DateTime.now().difference(lastKnown.timestamp);
    if (kDebugMode) {
      debugPrint('[LOC] getLastKnownPosition exists=true');
      debugPrint('[LOC] lastKnown ageSec=${age.inSeconds}');
    }
    if (age <= fallbackMaxAge) {
      if (kDebugMode) {
        debugPrint('[LOC] source=lastKnown');
      }
      return _resultFromPosition(
        lastKnown,
        status: LocationFetchStatus.recentArea,
        source: 'lastKnown',
      );
    }

    if (kDebugMode) {
      debugPrint('[LOC] old lastKnown rejected ageSec=${age.inSeconds}');
    }
    return null;
  }
}

import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationPoint {
  const LocationPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

enum LocationFetchStatus {
  granted,
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
  });

  final LocationFetchStatus status;
  final LocationPoint point;
  final bool usingDefault;
  final String cityLabel;
}

class LocationService {
  static const double defaultLatitude = -6.2088;
  static const double defaultLongitude = 106.8456;
  static const String defaultCityLabel = 'Your Area';
  static const Duration _locationTimeout = Duration(seconds: 8);
  static const Duration _geocodingTimeout = Duration(seconds: 4);

  Future<LocationFetchResult> getLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return _defaultResult(LocationFetchStatus.serviceDisabled);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        return _defaultResult(LocationFetchStatus.denied);
      }

      if (permission == LocationPermission.deniedForever) {
        return _defaultResult(LocationFetchStatus.deniedForever);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      ).timeout(_locationTimeout);
      final roundedLat = _roundTo2(position.latitude);
      final roundedLon = _roundTo2(position.longitude);
      final areaLabel = await _resolveAreaLabel(
        latitude: roundedLat,
        longitude: roundedLon,
      );

      return LocationFetchResult(
        status: LocationFetchStatus.granted,
        point: LocationPoint(
          latitude: roundedLat,
          longitude: roundedLon,
        ),
        usingDefault: false,
        cityLabel: areaLabel,
      );
    } on TimeoutException {
      return _defaultResult(LocationFetchStatus.fallbackDefault);
    } catch (_) {
      return _defaultResult(LocationFetchStatus.fallbackDefault);
    }
  }

  Future<void> openSettings() => Geolocator.openAppSettings();

  LocationFetchResult _defaultResult(LocationFetchStatus status) {
    return LocationFetchResult(
      status: status,
      point: const LocationPoint(
        latitude: defaultLatitude,
        longitude: defaultLongitude,
      ),
      usingDefault: true,
      cityLabel: defaultCityLabel,
    );
  }

  double _roundTo2(double value) => (value * 100).roundToDouble() / 100;

  Future<String> _resolveAreaLabel({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final placemarksTimed = await placemarkFromCoordinates(
        latitude,
        longitude,
      ).timeout(_geocodingTimeout);
      if (placemarksTimed.isEmpty) {
        return 'Your area';
      }

      final placemark = placemarksTimed.first;
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
}

import '../domain/air_quality_model.dart';

class AirQualityCacheEntry {
  const AirQualityCacheEntry({
    required this.data,
    required this.lastFetchedAt,
    required this.latitude,
    required this.longitude,
  });

  final AirQualityModel data;
  final DateTime lastFetchedAt;
  final double latitude;
  final double longitude;
}

class AirQualityCache {
  static const Duration throttleDuration = Duration(minutes: 5);

  final Map<String, AirQualityCacheEntry> _entries = {};

  String keyFor(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(2)},${longitude.toStringAsFixed(2)}';
  }

  AirQualityCacheEntry? get(double latitude, double longitude) {
    return _entries[keyFor(latitude, longitude)];
  }

  void save(AirQualityCacheEntry entry) {
    _entries[keyFor(entry.latitude, entry.longitude)] = entry;
  }

  void invalidate(double latitude, double longitude) {
    _entries.remove(keyFor(latitude, longitude));
  }

  bool isFresh(AirQualityCacheEntry entry, DateTime now) {
    return now.difference(entry.lastFetchedAt) < throttleDuration;
  }

  Duration remainingThrottle(AirQualityCacheEntry entry, DateTime now) {
    final elapsed = now.difference(entry.lastFetchedAt);
    final remaining = throttleDuration - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }
}

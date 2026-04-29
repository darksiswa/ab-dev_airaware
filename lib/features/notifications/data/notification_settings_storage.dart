import 'package:shared_preferences/shared_preferences.dart';

import '../domain/notification_settings.dart';

class NotificationSettingsStorage {
  static const morningEnabledKey = 'airaware_morning_report_enabled';
  static const dangerEnabledKey = 'airaware_danger_alert_enabled';
  static const morningTimeKey = 'airaware_morning_report_time';
  static const dangerThresholdKey = 'airaware_danger_alert_threshold';
  static const lastDangerAtKey = 'airaware_last_danger_alert_at';
  static const lastMorningAtKey = 'airaware_last_morning_report_at';
  static const lastDangerSignatureKey = 'airaware_last_danger_signature';
  static const lastKnownLatKey = 'airaware_last_lat';
  static const lastKnownLonKey = 'airaware_last_lon';
  static const lastKnownUpdatedAtKey = 'airaware_last_updated_at';
  static const _legacyLastKnownLatKey = 'airaware_last_known_lat_rounded';
  static const _legacyLastKnownLonKey = 'airaware_last_known_lon_rounded';

  Future<NotificationSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final rawTime = prefs.getString(morningTimeKey) ?? '07:00';
    final timeParts = rawTime.split(':');
    final hour = int.tryParse(timeParts.first) ?? 7;
    final minute = int.tryParse(timeParts.length > 1 ? timeParts[1] : '0') ?? 0;

    return NotificationSettings(
      morningReportEnabled: prefs.getBool(morningEnabledKey) ?? false,
      dangerAlertEnabled: prefs.getBool(dangerEnabledKey) ?? false,
      morningReportHour: hour,
      morningReportMinute: minute,
      dangerAlertThreshold: prefs.getInt(dangerThresholdKey) ?? 150,
      lastDangerAlertAt: _parseDateTime(prefs.getString(lastDangerAtKey)),
      lastMorningReportAt: _parseDateTime(prefs.getString(lastMorningAtKey)),
    );
  }

  Future<void> save(NotificationSettings value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(morningEnabledKey, value.morningReportEnabled);
    await prefs.setBool(dangerEnabledKey, value.dangerAlertEnabled);
    await prefs.setString(
      morningTimeKey,
      '${value.morningReportHour.toString().padLeft(2, '0')}:${value.morningReportMinute.toString().padLeft(2, '0')}',
    );
    await prefs.setInt(dangerThresholdKey, value.dangerAlertThreshold);
    if (value.lastDangerAlertAt != null) {
      await prefs.setString(lastDangerAtKey, value.lastDangerAlertAt!.toIso8601String());
    }
    if (value.lastMorningReportAt != null) {
      await prefs.setString(
        lastMorningAtKey,
        value.lastMorningReportAt!.toIso8601String(),
      );
    }
  }

  Future<void> saveLastKnownRoundedCoordinate({
    required double latitude,
    required double longitude,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(lastKnownLatKey, latitude);
    await prefs.setDouble(lastKnownLonKey, longitude);
    await prefs.setString(lastKnownUpdatedAtKey, DateTime.now().toIso8601String());
  }

  Future<void> saveLastDangerSignature(String signature) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(lastDangerSignatureKey, signature);
  }

  Future<String?> readLastDangerSignature() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(lastDangerSignatureKey);
  }

  Future<(double, double)?> readLastKnownRoundedCoordinate() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(lastKnownLatKey) ??
        prefs.getDouble(_legacyLastKnownLatKey);
    final lon = prefs.getDouble(lastKnownLonKey) ??
        prefs.getDouble(_legacyLastKnownLonKey);
    if (lat == null || lon == null) {
      return null;
    }
    return (lat, lon);
  }

  DateTime? _parseDateTime(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }
}

import 'dart:convert';

enum AirNotificationType { morningReport, dangerAlert }

class NotificationPayload {
  const NotificationPayload({
    required this.type,
    required this.aqi,
    required this.status,
    required this.locationLabel,
    required this.pm25,
    required this.pm10,
    required this.timestamp,
    required this.message,
  });

  final AirNotificationType type;
  final int aqi;
  final String status;
  final String locationLabel;
  final double pm25;
  final double pm10;
  final DateTime timestamp;
  final String message;

  String encode() {
    return jsonEncode({
      'type': type.name,
      'aqi': aqi,
      'status': status,
      'locationLabel': locationLabel,
      'pm25': pm25,
      'pm10': pm10,
      'timestamp': timestamp.toIso8601String(),
      'message': message,
    });
  }

  static NotificationPayload? decode(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return NotificationPayload(
        type: AirNotificationType.values.firstWhere(
          (e) => e.name == map['type'],
          orElse: () => AirNotificationType.morningReport,
        ),
        aqi: (map['aqi'] as num).toInt(),
        status: map['status'] as String,
        locationLabel: map['locationLabel'] as String,
        pm25: (map['pm25'] as num).toDouble(),
        pm10: (map['pm10'] as num).toDouble(),
        timestamp: DateTime.parse(map['timestamp'] as String),
        message: map['message'] as String,
      );
    } catch (_) {
      return null;
    }
  }
}

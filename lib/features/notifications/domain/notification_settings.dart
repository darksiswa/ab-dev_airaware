class NotificationSettings {
  const NotificationSettings({
    required this.morningReportEnabled,
    required this.dangerAlertEnabled,
    required this.morningReportHour,
    required this.morningReportMinute,
    required this.dangerAlertThreshold,
    this.lastDangerAlertAt,
    this.lastMorningReportAt,
  });

  static const NotificationSettings defaults = NotificationSettings(
    morningReportEnabled: false,
    dangerAlertEnabled: false,
    morningReportHour: 7,
    morningReportMinute: 0,
    dangerAlertThreshold: 150,
  );

  final bool morningReportEnabled;
  final bool dangerAlertEnabled;
  final int morningReportHour;
  final int morningReportMinute;
  final int dangerAlertThreshold;
  final DateTime? lastDangerAlertAt;
  final DateTime? lastMorningReportAt;

  NotificationSettings copyWith({
    bool? morningReportEnabled,
    bool? dangerAlertEnabled,
    int? morningReportHour,
    int? morningReportMinute,
    int? dangerAlertThreshold,
    DateTime? lastDangerAlertAt,
    DateTime? lastMorningReportAt,
    bool clearLastDangerAlertAt = false,
    bool clearLastMorningReportAt = false,
  }) {
    return NotificationSettings(
      morningReportEnabled: morningReportEnabled ?? this.morningReportEnabled,
      dangerAlertEnabled: dangerAlertEnabled ?? this.dangerAlertEnabled,
      morningReportHour: morningReportHour ?? this.morningReportHour,
      morningReportMinute: morningReportMinute ?? this.morningReportMinute,
      dangerAlertThreshold: dangerAlertThreshold ?? this.dangerAlertThreshold,
      lastDangerAlertAt: clearLastDangerAlertAt
          ? null
          : (lastDangerAlertAt ?? this.lastDangerAlertAt),
      lastMorningReportAt: clearLastMorningReportAt
          ? null
          : (lastMorningReportAt ?? this.lastMorningReportAt),
    );
  }
}

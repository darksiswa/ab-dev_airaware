import 'package:flutter/foundation.dart';

import '../data/battery_optimization_service.dart';
import '../data/local_notification_service.dart';
import '../data/notification_scheduler.dart';
import '../data/notification_settings_storage.dart';
import '../domain/notification_settings.dart';

enum NotificationPermissionResult { granted, denied }

class NotificationSettingsController extends ChangeNotifier {
  NotificationSettingsController({
    required NotificationSettingsStorage storage,
    required NotificationScheduler scheduler,
    required LocalNotificationService notificationService,
    required BatteryOptimizationService batteryOptimizationService,
  }) : _storage = storage,
       _scheduler = scheduler,
       _notificationService = notificationService,
       _batteryOptimizationService = batteryOptimizationService;

  final NotificationSettingsStorage _storage;
  final NotificationScheduler _scheduler;
  final LocalNotificationService _notificationService;
  final BatteryOptimizationService _batteryOptimizationService;

  NotificationSettings _settings = NotificationSettings.defaults;
  bool _initialized = false;

  NotificationSettings get settings => _settings;
  bool get initialized => _initialized;

  Future<void> initialize() async {
    await _notificationService.initialize();
    if (kDebugMode) {
      final granted = await _notificationService.isPermissionGranted();
      debugPrint(
        '[BG_DANGER] Android POST_NOTIFICATIONS granted=${(granted ?? false) ? 'yes' : 'no'}',
      );
    }
    await _scheduler.initialize();
    _settings = await _storage.load();
    await _scheduler.syncTasks(_settings);
    if (kDebugMode) {
      final battery = await _batteryOptimizationService.isBatteryOptimizationEnabled();
      debugPrint(
        '[BG_DANGER] batteryOptimization=${(battery ?? false) ? 'enabled' : 'disabled_or_unknown'}',
      );
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> setMorningReportEnabled(bool enabled) async {
    final permissionOk = enabled ? await _notificationService.requestPermission() : true;
    if (enabled && !permissionOk) {
      return;
    }

    _settings = _settings.copyWith(morningReportEnabled: enabled);
    notifyListeners();
    await _storage.save(_settings);
    await _scheduler.syncTasks(_settings);
  }

  Future<void> setDangerAlertEnabled(bool enabled) async {
    if (kDebugMode) {
      final permission = await _notificationService.isPermissionGranted();
      final battery = await _batteryOptimizationService.isBatteryOptimizationEnabled();
      debugPrint('[BG_DANGER] notificationPermission=${(permission ?? false) ? 'granted' : 'denied_or_unknown'}');
      debugPrint('[BG_DANGER] batteryOptimization=${(battery ?? false) ? 'enabled' : 'disabled_or_unknown'}');
    }
    _settings = _settings.copyWith(dangerAlertEnabled: enabled);
    notifyListeners();
    await _storage.save(_settings);
    await _scheduler.syncTasks(_settings);
  }

  Future<NotificationPermissionResult> requestNotificationPermission() async {
    final granted = await _notificationService.requestPermission();
    return granted
        ? NotificationPermissionResult.granted
        : NotificationPermissionResult.denied;
  }

  Future<bool?> isBatteryOptimizationEnabled() {
    return _batteryOptimizationService.isBatteryOptimizationEnabled();
  }

  Future<void> openBatteryOptimizationSettings() {
    return _batteryOptimizationService.openBatteryOptimizationSettings();
  }

  Future<void> sendTestNotificationNow() async {
    await _notificationService.initialize();
    final permissionOk = await _notificationService.requestPermission();
    if (!permissionOk) {
      return;
    }
    await _notificationService.sendSimpleTestNotification();
  }

  Future<void> testDangerAlertNow() async {
    await _scheduler.runDangerCheckNow();
  }
}

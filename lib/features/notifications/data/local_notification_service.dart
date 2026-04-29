import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../domain/notification_payload.dart';

class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final StreamController<NotificationPayload> _tapStreamController =
      StreamController<NotificationPayload>.broadcast();

  NotificationPayload? _launchPayload;
  bool _initialized = false;
  bool _androidChannelCreated = false;

  Stream<NotificationPayload> get onNotificationTap => _tapStreamController.stream;
  NotificationPayload? takeLaunchPayload() {
    final value = _launchPayload;
    _launchPayload = null;
    return value;
  }

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onTap,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundTap,
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      const channel = AndroidNotificationChannel(
        'airaware_alerts',
        'AirAware Alerts',
        description: 'Morning reports and danger alerts',
        importance: Importance.high,
      );
      await android.createNotificationChannel(channel);
      _androidChannelCreated = true;
    }

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    final payload = NotificationPayload.decode(
      launchDetails?.notificationResponse?.payload,
    );
    if (payload != null) {
      _launchPayload = payload;
    }

    _initialized = true;
    if (kDebugMode) {
      debugPrint('[BG_DANGER] local notification initialized=yes');
      debugPrint(
        '[BG_DANGER] notification channel created=${_androidChannelCreated ? 'yes' : 'no'}',
      );
    }
  }

  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final ios =
        _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

    var granted = true;
    if (android != null) {
      final enabled = await android.areNotificationsEnabled() ?? false;
      if (kDebugMode) {
        debugPrint(
          '[BG_DANGER] Android POST_NOTIFICATIONS granted before request=${enabled ? 'yes' : 'no'}',
        );
      }
      final result = await android.requestNotificationsPermission();
      granted = granted && (result ?? false);
      if (kDebugMode) {
        debugPrint(
          '[BG_DANGER] Android POST_NOTIFICATIONS granted after request=${(result ?? false) ? 'yes' : 'no'}',
        );
      }
    }
    if (ios != null) {
      final result = await ios.requestPermissions(alert: true, badge: true, sound: true);
      granted = granted && (result ?? false);
    }
    return granted;
  }

  Future<bool?> isPermissionGranted() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return android.areNotificationsEnabled();
    }
    return null;
  }

  Future<void> sendSimpleTestNotification() async {
    final payload = NotificationPayload(
      type: AirNotificationType.dangerAlert,
      aqi: 160,
      status: 'Unhealthy',
      locationLabel: 'Test Area',
      pm25: 42,
      pm10: 80,
      timestamp: DateTime.now(),
      message: 'This is a test notification from AirAware.',
    );
    await showNotification(
      id: 1999,
      title: 'AirAware Test Notification',
      body: payload.message,
      payload: payload,
    );
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    required NotificationPayload payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'airaware_alerts',
      'AirAware Alerts',
      channelDescription: 'Morning reports and danger alerts',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.show(id, title, body, details, payload: payload.encode());
  }

  void _onTap(NotificationResponse response) {
    final payload = NotificationPayload.decode(response.payload);
    if (payload != null) {
      _tapStreamController.add(payload);
    }
  }

  @pragma('vm:entry-point')
  static void _onBackgroundTap(NotificationResponse response) {
    if (kDebugMode) {
      debugPrint('[NOTIF] background tap payload exists=${response.payload != null}');
    }
  }
}

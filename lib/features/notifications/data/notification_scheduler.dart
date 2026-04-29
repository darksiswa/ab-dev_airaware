import 'dart:async';

import 'package:workmanager/workmanager.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../air_quality/data/air_quality_api_client.dart';
import '../../air_quality/data/air_quality_cache.dart';
import '../../air_quality/data/air_quality_repository.dart';
import '../../location/location_service.dart';
import '../domain/notification_payload.dart';
import '../domain/notification_settings.dart';
import 'local_notification_service.dart';
import 'notification_settings_storage.dart';

class NotificationScheduler {
  NotificationScheduler();

  static const morningTask = 'airaware_morning_report_task';
  static const dangerTask = 'airaware_danger_alert_task';

  Future<void> initialize() async {
    await Workmanager().initialize(
      airAwareBackgroundDispatcher,
      // Android WorkManager periodic task earliest interval is 15 minutes and
      // execution is best-effort. It may run later, especially with battery
      // optimization enabled.
      // ignore: deprecated_member_use
      isInDebugMode: kDebugMode,
    );
  }

  Future<void> syncTasks(NotificationSettings settings) async {
    if (kDebugMode) {
      debugPrint('[BG_DANGER] danger alert enabled=${settings.dangerAlertEnabled ? 'yes' : 'no'}');
      debugPrint('[BG_DANGER] frequency=${_dangerFrequency.inMinutes} minutes');
      debugPrint('[BG_DANGER] constraints=none');
    }

    if (settings.morningReportEnabled) {
      await Workmanager().registerPeriodicTask(
        morningTask,
        morningTask,
        frequency: _morningFrequency,
        constraints: Constraints(),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      );
    } else {
      await Workmanager().cancelByUniqueName(morningTask);
    }

    if (settings.dangerAlertEnabled) {
      await Workmanager().registerPeriodicTask(
        dangerTask,
        dangerTask,
        frequency: _dangerFrequency,
        constraints: Constraints(),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      );
      if (kDebugMode) {
        debugPrint('[BG_DANGER] registered=yes');
        debugPrint('[BG_DANGER] task name=$dangerTask');
      }
    } else {
      await Workmanager().cancelByUniqueName(dangerTask);
      if (kDebugMode) {
        debugPrint('[BG_DANGER] registered=no');
      }
    }
  }

  Duration get _morningFrequency {
    return kReleaseMode ? const Duration(minutes: 15) : const Duration(minutes: 15);
  }

  Duration get _dangerFrequency {
    return kReleaseMode ? const Duration(minutes: 15) : const Duration(minutes: 15);
  }

  static Future<bool> runBackgroundTask(String task) async {
      if (kDebugMode) {
        debugPrint('[BG_DANGER] callbackDispatcher entered');
        debugPrint('[BG_DANGER] task=$task');
        debugPrint('[BG_DANGER] inputData=none');
      }
      final storage = NotificationSettingsStorage();
      final settings = await storage.load();
      if (kDebugMode) {
        debugPrint('[BG_DANGER] sharedPreferences loaded=yes');
        debugPrint('[BG_DANGER] danger alert enabled=${settings.dangerAlertEnabled ? 'yes' : 'no'}');
      }

      if (!settings.morningReportEnabled && !settings.dangerAlertEnabled) {
        if (kDebugMode) {
          debugPrint('[BG_DANGER] task completed success=true');
        }
        return true;
      }

      final notificationService = LocalNotificationService.instance;
      await notificationService.initialize();

      late final (double, double, String, bool, String) location;
      try {
        location = await _resolveCoordinateForBackground(
          storage: storage,
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[BG_DANGER] should notify=no');
          debugPrint('[BG_DANGER] skip reason=location_unavailable');
          debugPrint('[BG_DANGER] error=$e');
          debugPrint('[BG_DANGER] task completed success=true');
        }
        return true;
      }

      final repository = AirQualityRepository(
        apiClient: AirQualityApiClient(),
        cache: AirQualityCache(),
      );

      late final AirQualityFetchResult fetched;
      try {
        fetched = await repository.fetch(
          latitude: location.$1,
          longitude: location.$2,
          cityLabel: location.$3,
          usingDefaultLocation: location.$4,
          forceRefresh: false,
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[BG_DANGER] should notify=no');
          debugPrint('[BG_DANGER] skip reason=api_error');
          debugPrint('[BG_DANGER] error=$e');
          debugPrint('[BG_DANGER] task completed success=false');
        }
        return false;
      }
      final data = fetched.data;
      if (kDebugMode) {
        debugPrint('[BG_DANGER] API fetched/cache reused=${fetched.fromCache ? 'cache_reused' : 'api_fetched'}');
      }

      await storage.saveLastKnownRoundedCoordinate(
        latitude: location.$1,
        longitude: location.$2,
      );

      final now = DateTime.now();

      if (task == morningTask && settings.morningReportEnabled) {
        final isMorningWindow = now.hour == settings.morningReportHour && now.minute < 30;
        final alreadySentToday = settings.lastMorningReportAt != null &&
            settings.lastMorningReportAt!.year == now.year &&
            settings.lastMorningReportAt!.month == now.month &&
            settings.lastMorningReportAt!.day == now.day;

        if (isMorningWindow && !alreadySentToday) {
          final payload = NotificationPayload(
            type: AirNotificationType.morningReport,
            aqi: data.aqi,
            status: data.aqiStatus,
            locationLabel: data.cityLabel,
            pm25: data.pm25,
            pm10: data.pm10,
            timestamp: now,
            message: 'AQI ${data.aqi} · ${data.aqiStatus}. Good to check before going out.',
          );
          await notificationService.showNotification(
            id: 1001,
            title: 'Morning Air Report',
            body: payload.message,
            payload: payload,
          );

          await storage.save(settings.copyWith(lastMorningReportAt: now));
        }
      }

      if (task == dangerTask) {
        await _runDangerCheck(
          settings: settings,
          notificationService: notificationService,
          storage: storage,
          aqi: data.aqi,
          status: data.aqiStatus,
          locationLabel: data.cityLabel,
          pm25: data.pm25,
          pm10: data.pm10,
          roundedLatitude: location.$1,
          roundedLongitude: location.$2,
          locationSource: location.$5,
          now: now,
        );
      }

      if (kDebugMode) {
        debugPrint('[BG_DANGER] task completed success=true');
      }
      return true;
  }

  static Future<(double, double, String, bool, String)> _resolveCoordinateForBackground({
    required NotificationSettingsStorage storage,
  }) async {
    final saved = await storage.readLastKnownRoundedCoordinate();
    if (kDebugMode) {
      debugPrint('[BG_DANGER] getCurrentPosition background start');
    }
    try {
      final current = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      ).timeout(const Duration(seconds: 10));
      final roundedLat = _roundTo2(current.latitude);
      final roundedLon = _roundTo2(current.longitude);
      await storage.saveLastKnownRoundedCoordinate(
        latitude: roundedLat,
        longitude: roundedLon,
      );
      if (kDebugMode) {
        debugPrint('[BG_DANGER] getCurrentPosition background success');
        debugPrint('[BG_DANGER] source=backgroundCurrentPosition');
        debugPrint(
          '[BG_DANGER] final coordinate used ${roundedLat.toStringAsFixed(2)},${roundedLon.toStringAsFixed(2)}',
        );
      }
      return (
        roundedLat,
        roundedLon,
        'Your area',
        false,
        'backgroundCurrentPosition',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[BG_DANGER] getCurrentPosition background failure');
        debugPrint('[BG_DANGER] error=$e');
      }
    }

    final lastKnown = await Geolocator.getLastKnownPosition();
    if (lastKnown != null) {
      final roundedLat = _roundTo2(lastKnown.latitude);
      final roundedLon = _roundTo2(lastKnown.longitude);
      await storage.saveLastKnownRoundedCoordinate(
        latitude: roundedLat,
        longitude: roundedLon,
      );
      if (kDebugMode) {
        debugPrint('[BG_DANGER] getCurrentPosition background failure');
        debugPrint('[BG_DANGER] source=backgroundLastKnown');
        debugPrint(
          '[BG_DANGER] final coordinate used ${roundedLat.toStringAsFixed(2)},${roundedLon.toStringAsFixed(2)}',
        );
      }
      return (
        roundedLat,
        roundedLon,
        'Your area',
        false,
        'backgroundLastKnown',
      );
    }

    if (saved != null) {
      if (kDebugMode) {
        debugPrint('[BG_DANGER] source=savedRounded');
        debugPrint(
          '[BG_DANGER] final coordinate used ${saved.$1.toStringAsFixed(2)},${saved.$2.toStringAsFixed(2)}',
        );
      }
      return (saved.$1, saved.$2, 'Your area', false, 'savedRounded');
    }

    if (kDebugMode) {
      debugPrint('[BG_DANGER] no background lastKnown available, using default coordinate');
      debugPrint('[BG_DANGER] lastKnown null, fallback to default');
      debugPrint(
        '[BG_DANGER] final coordinate used ${LocationService.defaultLatitude.toStringAsFixed(2)},${LocationService.defaultLongitude.toStringAsFixed(2)}',
      );
    }
    return (
      LocationService.defaultLatitude,
      LocationService.defaultLongitude,
      LocationService.defaultCityLabel,
      true,
      'defaultJakarta',
    );
  }

  Future<void> runDangerCheckNow() async {
    final storage = NotificationSettingsStorage();
    final settings = await storage.load();
    final notificationService = LocalNotificationService.instance;
    await notificationService.initialize();

    final location = await _resolveCoordinateForBackground(
      storage: storage,
    );

    final repository = AirQualityRepository(
      apiClient: AirQualityApiClient(),
      cache: AirQualityCache(),
    );
    final fetched = await repository.fetch(
      latitude: location.$1,
      longitude: location.$2,
      cityLabel: location.$3,
      usingDefaultLocation: location.$4,
      forceRefresh: false,
    );
    if (kDebugMode) {
      debugPrint('[BG_DANGER] API fetched/cache reused=${fetched.fromCache ? 'cache_reused' : 'api_fetched'}');
    }
    await _runDangerCheck(
      settings: settings,
      notificationService: notificationService,
      storage: storage,
      aqi: fetched.data.aqi,
      status: fetched.data.aqiStatus,
      locationLabel: fetched.data.cityLabel,
      pm25: fetched.data.pm25,
      pm10: fetched.data.pm10,
      roundedLatitude: location.$1,
      roundedLongitude: location.$2,
      locationSource: 'manual_debug_${location.$5}',
      now: DateTime.now(),
    );
  }

  static Future<void> _runDangerCheck({
    required NotificationSettings settings,
    required LocalNotificationService notificationService,
    required NotificationSettingsStorage storage,
    required int aqi,
    required String status,
    required String locationLabel,
    required double pm25,
    required double pm10,
    required double roundedLatitude,
    required double roundedLongitude,
    required String locationSource,
    required DateTime now,
  }) async {
    if (kDebugMode) {
      debugPrint('[BG_DANGER] task started');
      debugPrint('[BG_DANGER] timestamp=${now.toIso8601String()}');
      debugPrint('[BG_DANGER] danger enabled=${settings.dangerAlertEnabled ? 'yes' : 'no'}');
      debugPrint('[BG_DANGER] location source=$locationSource');
      debugPrint(
        '[BG_DANGER] rounded coordinate=${roundedLatitude.toStringAsFixed(2)},${roundedLongitude.toStringAsFixed(2)}',
      );
      debugPrint('[BG_DANGER] AQI value=$aqi');
      debugPrint('[BG_DANGER] threshold value=${settings.dangerAlertThreshold}');
    }

    if (!settings.dangerAlertEnabled) {
      if (kDebugMode) {
        debugPrint('[BG_DANGER] should notify=no');
        debugPrint('[BG_DANGER] skip reason=danger_disabled');
        debugPrint('[BG_DANGER] notification shown=no');
      }
      return;
    }

    final cooldownOk = settings.lastDangerAlertAt == null ||
        now.difference(settings.lastDangerAlertAt!) >= const Duration(hours: 2);
    if (!cooldownOk) {
      if (kDebugMode) {
        debugPrint('[BG_DANGER] should notify=no');
        debugPrint('[BG_DANGER] skip reason=last_alert_too_recent');
        debugPrint('[BG_DANGER] notification shown=no');
      }
      return;
    }

    if (aqi <= settings.dangerAlertThreshold) {
      if (kDebugMode) {
        debugPrint('[BG_DANGER] should notify=no');
        debugPrint('[BG_DANGER] skip reason=aqi_not_above_threshold');
        debugPrint('[BG_DANGER] notification shown=no');
      }
      return;
    }

    final signature =
        '${roundedLatitude.toStringAsFixed(2)},${roundedLongitude.toStringAsFixed(2)}|$status';
    final previousSignature = await storage.readLastDangerSignature();
    if (previousSignature == signature) {
      if (kDebugMode) {
        debugPrint('[BG_DANGER] should notify=no');
        debugPrint('[BG_DANGER] skip reason=same_coordinate_status');
        debugPrint('[BG_DANGER] notification shown=no');
      }
      return;
    }

    final payload = NotificationPayload(
      type: AirNotificationType.dangerAlert,
      aqi: aqi,
      status: status,
      locationLabel: locationLabel,
      pm25: pm25,
      pm10: pm10,
      timestamp: now,
      message: 'AQI $aqi. Reduce outdoor activity and consider wearing a mask.',
    );
    await notificationService.showNotification(
      id: 1002,
      title: 'Air Quality Danger Alert',
      body: payload.message,
      payload: payload,
    );
    await storage.save(settings.copyWith(lastDangerAlertAt: now));
    await storage.saveLastDangerSignature(signature);
    if (kDebugMode) {
      debugPrint('[BG_DANGER] should notify=yes');
      debugPrint('[BG_DANGER] notification shown=yes');
    }
  }

  static double _roundTo2(double value) => (value * 100).roundToDouble() / 100;
}

@pragma('vm:entry-point')
void airAwareBackgroundDispatcher() {
  Workmanager().executeTask((task, _) async {
    return NotificationScheduler.runBackgroundTask(task);
  });
}

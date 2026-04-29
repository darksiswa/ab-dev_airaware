import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class BatteryOptimizationService {
  static const MethodChannel _channel =
      MethodChannel('airaware/battery_optimization');

  Future<bool?> isBatteryOptimizationEnabled() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }
    try {
      final enabled = await _channel.invokeMethod<bool>(
        'isBatteryOptimizationEnabled',
      );
      return enabled;
    } catch (_) {
      return null;
    }
  }

  Future<void> openBatteryOptimizationSettings() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    const intent = AndroidIntent(
      action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
    );
    await intent.launch();
  }
}

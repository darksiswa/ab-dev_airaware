import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService._();

  static final AdService instance = AdService._();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    await MobileAds.instance.initialize();
    _initialized = true;
    if (kDebugMode) {
      debugPrint('[ADS] AdMob initialized');
    }
  }
}

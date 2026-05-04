import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';

class InterstitialAdManager {
  InterstitialAdManager._();

  static final InterstitialAdManager instance = InterstitialAdManager._();

  static const Duration _minimumInterval = Duration(minutes: 3);
  static const int _maxShowsPerSession = 3;
  static const Duration _startupGracePeriod = Duration(seconds: 20);

  InterstitialAd? _ad;
  bool _isLoading = false;
  bool _isShowing = false;
  int _shownCountThisSession = 0;
  DateTime? _lastShownAt;
  final DateTime _appStartedAt = DateTime.now();

  bool get isLoaded => _ad != null;

  void load() {
    if (_isLoading || _ad != null) {
      return;
    }
    _isLoading = true;

    InterstitialAd.load(
      adUnitId: AdConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoading = false;
          _ad = ad;
          if (kDebugMode) {
            debugPrint('[ADS] interstitial loaded');
          }
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          _ad = null;
          if (kDebugMode) {
            debugPrint('[ADS] interstitial failed: $error');
          }
        },
      ),
    );
  }

  bool canShow() {
    if (_ad == null || _isShowing) {
      return false;
    }
    if (_shownCountThisSession >= _maxShowsPerSession) {
      return false;
    }
    final sinceStartup = DateTime.now().difference(_appStartedAt);
    if (sinceStartup < _startupGracePeriod) {
      return false;
    }
    if (_lastShownAt == null) {
      return true;
    }
    final elapsed = DateTime.now().difference(_lastShownAt!);
    return elapsed >= _minimumInterval;
  }

  void showIfAllowed() {
    if (!canShow()) {
      load();
      return;
    }
    final ad = _ad;
    if (ad == null) {
      load();
      return;
    }

    _isShowing = true;
    _ad = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        if (kDebugMode) {
          debugPrint('[ADS] interstitial shown');
        }
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowing = false;
        _lastShownAt = DateTime.now();
        _shownCountThisSession += 1;
        ad.dispose();
        if (kDebugMode) {
          debugPrint('[ADS] interstitial dismissed');
        }
        load();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowing = false;
        ad.dispose();
        if (kDebugMode) {
          debugPrint('[ADS] interstitial failed to show: $error');
        }
        load();
      },
    );

    ad.show();
  }

  void dispose() {
    _ad?.dispose();
    _ad = null;
    _isLoading = false;
    _isShowing = false;
  }
}

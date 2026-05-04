class AdConfig {
  const AdConfig._();

  // Official Google test ad unit IDs for development.
  static const String testInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String testBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String testNativeAdUnitId =
      'ca-app-pub-3940256099942544/2247696110';

  // TODO(ads): Load production ad unit IDs from secure environment/config.
  static const String? productionInterstitialAdUnitId = null;
  static const String? productionBannerAdUnitId = null;
  static const String? productionNativeAdUnitId = null;

  static String get interstitialAdUnitId =>
      productionInterstitialAdUnitId ?? testInterstitialAdUnitId;
  static String get bannerAdUnitId =>
      productionBannerAdUnitId ?? testBannerAdUnitId;
  static String get nativeAdUnitId =>
      productionNativeAdUnitId ?? testNativeAdUnitId;

  // TODO(ads): Hide ads for premium users once subscription is implemented.
}

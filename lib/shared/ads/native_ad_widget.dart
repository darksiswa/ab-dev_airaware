import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../constants/app_colors.dart';
import 'ad_config.dart';

class NativeAdWidget extends StatefulWidget {
  const NativeAdWidget({super.key, this.height = 110, this.fallback});

  final double height;
  final Widget? fallback;

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _nativeAd = NativeAd(
      adUnitId: AdConfig.nativeAdUnitId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          if (!mounted) {
            return;
          }
          setState(() {
            _isLoaded = true;
            _failed = false;
          });
          if (kDebugMode) {
            debugPrint('[ADS] native loaded');
          }
        },
        onAdFailedToLoad: (_, error) {
          if (!mounted) {
            return;
          }
          setState(() {
            _failed = true;
            _isLoaded = false;
          });
          if (kDebugMode) {
            debugPrint('[ADS] native failed: $error');
          }
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: AppColors.surface.withValues(alpha: 0.5),
        cornerRadius: 14,
      ),
    )..load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoaded && _nativeAd != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sponsored · Ad',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: widget.height,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AdWidget(ad: _nativeAd!),
            ),
          ),
        ],
      );
    }

    if (_failed && widget.fallback != null) {
      return widget.fallback!;
    }

    return widget.fallback ?? const SizedBox.shrink();
  }
}

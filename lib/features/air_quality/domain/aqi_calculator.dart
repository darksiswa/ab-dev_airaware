import 'package:flutter/material.dart';

import '../../../shared/constants/app_colors.dart';

enum AqiCategory {
  good,
  moderate,
  unhealthySensitive,
  unhealthy,
  veryUnhealthy,
  hazardous,
}

class AqiResult {
  const AqiResult({
    required this.aqi,
    required this.label,
    required this.category,
  });

  final int aqi;
  final String label;
  final AqiCategory category;
}

class AqiCalculator {
  const AqiCalculator();

  AqiResult fromPm25(double pm25) {
    if (pm25 <= 12.0) {
      return _calc(pm25, 0, 12.0, 0, 50, 'Good', AqiCategory.good);
    }
    if (pm25 <= 35.4) {
      return _calc(pm25, 12.1, 35.4, 51, 100, 'Moderate', AqiCategory.moderate);
    }
    if (pm25 <= 55.4) {
      return _calc(
        pm25,
        35.5,
        55.4,
        101,
        150,
        'Unhealthy for Sensitive Groups',
        AqiCategory.unhealthySensitive,
      );
    }
    if (pm25 <= 150.4) {
      return _calc(
        pm25,
        55.5,
        150.4,
        151,
        200,
        'Unhealthy',
        AqiCategory.unhealthy,
      );
    }
    if (pm25 <= 250.4) {
      return _calc(
        pm25,
        150.5,
        250.4,
        201,
        300,
        'Very Unhealthy',
        AqiCategory.veryUnhealthy,
      );
    }
    return _calc(
      pm25,
      250.5,
      500.4,
      301,
      500,
      'Hazardous',
      AqiCategory.hazardous,
    );
  }

  AqiResult _calc(
    double cp,
    double bpLow,
    double bpHigh,
    int iLow,
    int iHigh,
    String label,
    AqiCategory category,
  ) {
    final aqi = (((iHigh - iLow) / (bpHigh - bpLow)) * (cp - bpLow) + iLow)
        .round();
    return AqiResult(aqi: aqi.clamp(0, 500), label: label, category: category);
  }

  Color colorFor(AqiCategory category) {
    switch (category) {
      case AqiCategory.good:
        return AppColors.accent;
      case AqiCategory.moderate:
        return AppColors.moderateAccent;
      case AqiCategory.unhealthySensitive:
        return const Color(0xFFFF9C42);
      case AqiCategory.unhealthy:
        return const Color(0xFFFF6464);
      case AqiCategory.veryUnhealthy:
        return const Color(0xFFBE63F9);
      case AqiCategory.hazardous:
        return const Color(0xFF8A1C1C);
    }
  }
}

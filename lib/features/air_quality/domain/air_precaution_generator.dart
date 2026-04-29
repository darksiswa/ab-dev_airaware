import '../../settings/domain/health_config.dart';
import 'air_quality_model.dart';

enum AirPrecautionSeverity { normal, caution, danger }

class AirPrecaution {
  const AirPrecaution({
    required this.title,
    required this.message,
    required this.severity,
  });

  final String title;
  final String message;
  final AirPrecautionSeverity severity;
}

class AirPrecautionGenerator {
  const AirPrecautionGenerator();

  static const int aqiCautionThreshold = 101;
  static const double pm25HighThreshold = 35;
  static const double pm10HighThreshold = 50;
  static const double dustHighThreshold = 50;
  // Pollen threshold can vary by source/index scale.
  static const double pollenHighThreshold = 1;

  AirPrecaution generate({
    required AirQualityModel data,
    required HealthConfig config,
  }) {
    final asthmaTriggered =
        config.asthmaMode &&
        (data.aqi >= aqiCautionThreshold || data.pm25 >= pm25HighThreshold);
    final allergyTriggered =
        config.allergyMode &&
        (data.aqi >= aqiCautionThreshold ||
            data.pm10 >= pm10HighThreshold ||
            (data.dust != null && data.dust! >= dustHighThreshold) ||
            (data.pollen != null && data.pollen! >= pollenHighThreshold));

    if (asthmaTriggered && allergyTriggered) {
      return const AirPrecaution(
        title: 'Breathing & Allergy Alert',
        message:
            'Air quality may affect breathing and allergies today. Reduce outdoor exposure, wear a mask, and keep your inhaler or routine medication accessible.',
        severity: AirPrecautionSeverity.danger,
      );
    }

    if (asthmaTriggered) {
      final aqiRisk = data.aqi >= aqiCautionThreshold;
      final pmRisk = data.pm25 >= pm25HighThreshold;
      if (aqiRisk && pmRisk) {
        return const AirPrecaution(
          title: 'Asthma Alert',
          message:
              'Air quality may affect breathing. Reduce outdoor activity, wear a mask, and keep your inhaler accessible. Fine particles may worsen breathing symptoms.',
          severity: AirPrecautionSeverity.danger,
        );
      }
      if (aqiRisk) {
        return const AirPrecaution(
          title: 'Asthma Alert',
          message:
              'Air quality may affect asthma today. Reduce outdoor activity, wear a mask, and keep your inhaler accessible.',
          severity: AirPrecautionSeverity.danger,
        );
      }
      return const AirPrecaution(
        title: 'Asthma Caution',
        message:
            'Fine particles may affect breathing today. Consider reducing prolonged outdoor exposure and use protection when needed.',
        severity: AirPrecautionSeverity.caution,
      );
    }

    if (allergyTriggered) {
      final parts = <String>[];
      if (data.aqi >= aqiCautionThreshold) {
        parts.add('air quality is elevated');
      }
      if (data.pm10 >= pm10HighThreshold) {
        parts.add('coarse particles may trigger allergy symptoms');
      }
      if (data.dust != null && data.dust! >= dustHighThreshold) {
        parts.add('dust levels are high');
      }
      if (data.pollen != null && data.pollen! >= pollenHighThreshold) {
        parts.add('pollen levels may affect sensitive users');
      }

      final detail = parts.isEmpty
          ? 'conditions may affect sensitive users'
          : parts.join(', ');

      return AirPrecaution(
        title: 'Allergy Caution',
        message:
            'For allergy-sensitive users, $detail. Consider reducing outdoor exposure and using protection when needed.',
        severity: AirPrecautionSeverity.caution,
      );
    }

    return AirPrecaution(
      title: 'AI Air Insight',
      message: data.insight,
      severity: AirPrecautionSeverity.normal,
    );
  }
}

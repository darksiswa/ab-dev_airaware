import 'aqi_calculator.dart';

class AirInsightGenerator {
  const AirInsightGenerator();

  String generate(AqiCategory category) {
    switch (category) {
      case AqiCategory.good:
        return 'Air quality looks good. It is a nice time for outdoor activity.';
      case AqiCategory.moderate:
        return 'Air quality is moderate. Sensitive users should reduce prolonged outdoor activity.';
      case AqiCategory.unhealthySensitive:
        return 'Air quality may affect sensitive groups. Limit heavy outdoor activity and wear protection if needed.';
      case AqiCategory.unhealthy:
        return 'Air quality may affect your health. Consider wearing a mask outside.';
      case AqiCategory.veryUnhealthy:
        return 'Air quality is very unhealthy. Avoid outdoor activity when possible.';
      case AqiCategory.hazardous:
        return 'Air quality is hazardous. Stay indoors and use protection if you must go outside.';
    }
  }
}

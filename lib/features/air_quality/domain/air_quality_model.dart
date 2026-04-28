import 'aqi_calculator.dart';

class DailyAqiForecast {
  const DailyAqiForecast({
    required this.date,
    required this.dayLabel,
    required this.aqi,
    required this.status,
    required this.category,
  });

  final DateTime date;
  final String dayLabel;
  final int aqi;
  final String status;
  final AqiCategory category;
}

class AirQualityModel {
  const AirQualityModel({
    required this.cityLabel,
    required this.latitude,
    required this.longitude,
    required this.temperature,
    required this.relativeHumidity,
    required this.windSpeed,
    required this.uvIndex,
    required this.pm25,
    required this.pm10,
    required this.no2,
    required this.o3,
    required this.aqi,
    required this.aqiStatus,
    required this.aqiCategory,
    required this.insight,
    required this.fetchedAt,
    required this.usingDefaultLocation,
    required this.forecast7Days,
  });

  final String cityLabel;
  final double latitude;
  final double longitude;

  final double temperature;
  final double relativeHumidity;
  final double windSpeed;
  final double uvIndex;

  final double pm25;
  final double pm10;
  final double no2;
  final double o3;

  final int aqi;
  final String aqiStatus;
  final AqiCategory aqiCategory;
  final String insight;

  final DateTime fetchedAt;
  final bool usingDefaultLocation;
  final List<DailyAqiForecast> forecast7Days;

  String get temperatureLabel => '${temperature.toStringAsFixed(0)}°C';
  String get humidityLabel => '${relativeHumidity.toStringAsFixed(0)}%';
  String get windSpeedLabel => '${windSpeed.toStringAsFixed(0)} km/h';
  String get uvIndexLabel => uvIndex.toStringAsFixed(0);
  String get pm25Label => pm25.toStringAsFixed(0);
  String get pm10Label => pm10.toStringAsFixed(0);
}

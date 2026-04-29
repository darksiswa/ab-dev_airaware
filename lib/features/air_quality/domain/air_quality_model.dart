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

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'dayLabel': dayLabel,
      'aqi': aqi,
      'status': status,
      'category': category.name,
    };
  }

  static DailyAqiForecast fromJson(Map<String, dynamic> json) {
    return DailyAqiForecast(
      date: DateTime.parse(json['date'] as String),
      dayLabel: json['dayLabel'] as String,
      aqi: (json['aqi'] as num).toInt(),
      status: json['status'] as String,
      category: AqiCategory.values.firstWhere(
        (value) => value.name == json['category'],
        orElse: () => AqiCategory.moderate,
      ),
    );
  }
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
    this.dust,
    this.pollen,
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
  final double? dust;
  final double? pollen;
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

  Map<String, dynamic> toJson() {
    return {
      'cityLabel': cityLabel,
      'latitude': latitude,
      'longitude': longitude,
      'temperature': temperature,
      'relativeHumidity': relativeHumidity,
      'windSpeed': windSpeed,
      'uvIndex': uvIndex,
      'pm25': pm25,
      'pm10': pm10,
      'dust': dust,
      'pollen': pollen,
      'no2': no2,
      'o3': o3,
      'aqi': aqi,
      'aqiStatus': aqiStatus,
      'aqiCategory': aqiCategory.name,
      'insight': insight,
      'fetchedAt': fetchedAt.toIso8601String(),
      'usingDefaultLocation': usingDefaultLocation,
      'forecast7Days': forecast7Days.map((item) => item.toJson()).toList(),
    };
  }

  static AirQualityModel fromJson(Map<String, dynamic> json) {
    final forecastRaw = (json['forecast7Days'] as List<dynamic>? ?? []);
    return AirQualityModel(
      cityLabel: json['cityLabel'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      temperature: (json['temperature'] as num).toDouble(),
      relativeHumidity: (json['relativeHumidity'] as num).toDouble(),
      windSpeed: (json['windSpeed'] as num).toDouble(),
      uvIndex: (json['uvIndex'] as num).toDouble(),
      pm25: (json['pm25'] as num).toDouble(),
      pm10: (json['pm10'] as num).toDouble(),
      dust: (json['dust'] as num?)?.toDouble(),
      pollen: (json['pollen'] as num?)?.toDouble(),
      no2: (json['no2'] as num).toDouble(),
      o3: (json['o3'] as num).toDouble(),
      aqi: (json['aqi'] as num).toInt(),
      aqiStatus: json['aqiStatus'] as String,
      aqiCategory: AqiCategory.values.firstWhere(
        (value) => value.name == json['aqiCategory'],
        orElse: () => AqiCategory.moderate,
      ),
      insight: json['insight'] as String,
      fetchedAt: DateTime.parse(json['fetchedAt'] as String),
      usingDefaultLocation: json['usingDefaultLocation'] as bool? ?? false,
      forecast7Days: forecastRaw
          .whereType<Map>()
          .map((item) => DailyAqiForecast.fromJson(item.cast<String, dynamic>()))
          .toList(),
    );
  }
}

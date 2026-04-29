class HealthConfig {
  const HealthConfig({
    required this.asthmaMode,
    required this.allergyMode,
    required this.temperatureUnit,
  });

  static const HealthConfig defaults = HealthConfig(
    asthmaMode: false,
    allergyMode: false,
    temperatureUnit: TemperatureUnit.celsius,
  );

  final bool asthmaMode;
  final bool allergyMode;
  final TemperatureUnit temperatureUnit;

  HealthConfig copyWith({
    bool? asthmaMode,
    bool? allergyMode,
    TemperatureUnit? temperatureUnit,
  }) {
    return HealthConfig(
      asthmaMode: asthmaMode ?? this.asthmaMode,
      allergyMode: allergyMode ?? this.allergyMode,
      temperatureUnit: temperatureUnit ?? this.temperatureUnit,
    );
  }
}

enum TemperatureUnit {
  celsius,
  fahrenheit,
}

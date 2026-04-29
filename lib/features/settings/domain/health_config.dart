class HealthConfig {
  const HealthConfig({
    required this.asthmaMode,
    required this.allergyMode,
  });

  static const HealthConfig defaults = HealthConfig(
    asthmaMode: false,
    allergyMode: false,
  );

  final bool asthmaMode;
  final bool allergyMode;

  HealthConfig copyWith({
    bool? asthmaMode,
    bool? allergyMode,
  }) {
    return HealthConfig(
      asthmaMode: asthmaMode ?? this.asthmaMode,
      allergyMode: allergyMode ?? this.allergyMode,
    );
  }
}

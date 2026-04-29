import 'package:shared_preferences/shared_preferences.dart';

import '../domain/health_config.dart';

class HealthConfigStorage {
  static const asthmaKey = 'airaware_asthma_mode';
  static const allergyKey = 'airaware_allergy_mode';
  static const temperatureUnitKey = 'airaware_temperature_unit';

  Future<HealthConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    return HealthConfig(
      asthmaMode: prefs.getBool(asthmaKey) ?? false,
      allergyMode: prefs.getBool(allergyKey) ?? false,
      temperatureUnit:
          (prefs.getString(temperatureUnitKey) == TemperatureUnit.fahrenheit.name)
          ? TemperatureUnit.fahrenheit
          : TemperatureUnit.celsius,
    );
  }

  Future<void> save(HealthConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(asthmaKey, config.asthmaMode);
    await prefs.setBool(allergyKey, config.allergyMode);
    await prefs.setString(temperatureUnitKey, config.temperatureUnit.name);
  }
}

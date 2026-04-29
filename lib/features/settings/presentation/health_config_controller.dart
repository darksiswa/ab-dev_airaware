import 'package:flutter/foundation.dart';

import '../data/health_config_storage.dart';
import '../domain/health_config.dart';

class HealthConfigController extends ChangeNotifier {
  HealthConfigController({required HealthConfigStorage storage})
    : _storage = storage;

  final HealthConfigStorage _storage;

  HealthConfig _config = HealthConfig.defaults;
  bool _isLoaded = false;

  HealthConfig get config => _config;
  bool get isLoaded => _isLoaded;

  Future<void> initialize() async {
    _config = await _storage.load();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setAsthmaMode(bool enabled) async {
    _config = _config.copyWith(asthmaMode: enabled);
    notifyListeners();
    await _storage.save(_config);
  }

  Future<void> setAllergyMode(bool enabled) async {
    _config = _config.copyWith(allergyMode: enabled);
    notifyListeners();
    await _storage.save(_config);
  }

  Future<void> setTemperatureUnit(TemperatureUnit unit) async {
    _config = _config.copyWith(temperatureUnit: unit);
    notifyListeners();
    await _storage.save(_config);
  }
}

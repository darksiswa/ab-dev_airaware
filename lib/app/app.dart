import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/air_quality/data/air_quality_api_client.dart';
import '../features/air_quality/data/air_quality_cache.dart';
import '../features/air_quality/data/air_quality_repository.dart';
import '../features/air_quality/presentation/air_quality_controller.dart';
import '../features/location/location_service.dart';
import '../features/settings/data/health_config_storage.dart';
import '../features/settings/presentation/health_config_controller.dart';
import '../features/splash/splash_page.dart';
import 'theme.dart';

class AirAwareApp extends StatelessWidget {
  const AirAwareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<HealthConfigController>(
          create: (_) => HealthConfigController(
            storage: HealthConfigStorage(),
          )..initialize(),
        ),
        ChangeNotifierProvider<AirQualityController>(
          create: (_) => AirQualityController(
            repository: AirQualityRepository(
              apiClient: AirQualityApiClient(),
              cache: AirQualityCache(),
            ),
            locationService: LocationService(),
          )..initialize(),
        ),
      ],
      child: MaterialApp(
        title: 'AirAware',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const SplashPage(),
      ),
    );
  }
}

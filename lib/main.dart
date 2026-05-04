import 'package:flutter/material.dart';

import 'app/app.dart';
import 'shared/ads/ad_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdService.instance.initialize();
  runApp(const AirAwareApp());
}

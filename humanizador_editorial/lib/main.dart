import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/app_services.dart';
import 'core/utils/app_logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ningún error no capturado debe cerrar la app sin registro; los logs no
  // incluyen texto del usuario ni claves.
  FlutterError.onError = (details) {
    AppLogger.error('flutter', details.exceptionAsString());
    FlutterError.presentError(details);
  };

  final services = await AppServices.bootstrap();
  runApp(HumanizadorApp(services: services));
}

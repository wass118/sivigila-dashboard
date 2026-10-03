import 'package:flutter/foundation.dart';

/// Modo de ejecución del servicio de humanización.
enum HumanizerMode {
  /// Usa el proveedor configurado en Ajustes (por defecto, el modo demo).
  auto,

  /// Fuerza el servicio simulado [FakeHumanizerService]. No hay red.
  demo,

  /// Usa el proveedor real configurado en Ajustes.
  real,
}

/// Variables de entorno de compilación (`--dart-define`).
///
/// Ejemplos:
/// ```
/// flutter run --dart-define=HUMANIZER_MODE=demo
/// flutter run --dart-define=HUMANIZER_MODE=real --dart-define=ENABLE_LOGS=false
/// ```
abstract final class AppEnvironment {
  static const String _modeRaw =
      String.fromEnvironment('HUMANIZER_MODE', defaultValue: 'auto');

  /// Logs técnicos: activos por defecto fuera de release.
  static const bool logsEnabled =
      bool.fromEnvironment('ENABLE_LOGS', defaultValue: !kReleaseMode);

  static HumanizerMode get mode => switch (_modeRaw.toLowerCase()) {
        'demo' || 'fake' => HumanizerMode.demo,
        'real' => HumanizerMode.real,
        _ => HumanizerMode.auto,
      };
}

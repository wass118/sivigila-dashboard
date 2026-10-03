import 'package:flutter/foundation.dart';

/// Logger técnico mínimo.
///
/// Reglas: nunca registrar claves API, cabeceras de autorización ni el texto
/// del usuario. Registrar solo longitudes, conteos, estados y códigos HTTP.
/// Se desactiva con `--dart-define=ENABLE_LOGS=false`.
abstract final class AppLogger {
  static bool enabled = false;

  static final List<RegExp> _secretPatterns = [
    RegExp(r'sk-[A-Za-z0-9_\-]{8,}'),
    RegExp(r'AIza[0-9A-Za-z_\-]{20,}'),
    RegExp(r'(Bearer\s+)[A-Za-z0-9._\-]+', caseSensitive: false),
    RegExp(r'((?:x-api-key|api[_-]?key|key|token)\s*[=:]\s*)[^\s&",]+',
        caseSensitive: false),
  ];

  /// Elimina posibles secretos de una cadena antes de registrarla.
  static String redact(String input) {
    var out = input;
    for (final p in _secretPatterns) {
      out = out.replaceAllMapped(p, (m) {
        final prefix = m.groupCount >= 1 ? (m.group(1) ?? '') : '';
        return '$prefix[REDACTADO]';
      });
    }
    return out;
  }

  static void debug(String tag, String message) => _log('DEBUG', tag, message);
  static void info(String tag, String message) => _log('INFO', tag, message);
  static void warning(String tag, String message) =>
      _log('WARN', tag, message);
  static void error(String tag, String message) => _log('ERROR', tag, message);

  static void _log(String level, String tag, String message) {
    if (!enabled) return;
    debugPrint('[$level][$tag] ${redact(message)}');
  }
}

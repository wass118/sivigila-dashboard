import 'dart:convert';

/// Recuperación segura de JSON devuelto por un modelo de lenguaje.
///
/// Estrategia (sin evaluar código ni "adivinar" contenido):
/// 1. Intento directo.
/// 2. Eliminar bloques de código Markdown (```json ... ```).
/// 3. Extraer el primer objeto `{...}` balanceado, respetando cadenas.
/// 4. Reparaciones conservadoras: comas finales, saltos de línea y
///    tabuladores sin escapar dentro de cadenas, BOM y caracteres de control.
/// Si nada funciona devuelve `null`; nunca lanza.
abstract final class JsonSanitizer {
  static Map<String, dynamic>? tryDecodeObject(String raw) {
    for (final candidate in candidates(raw)) {
      try {
        final decoded = jsonDecode(candidate);
        if (decoded is Map<String, dynamic>) return decoded;
      } on FormatException {
        continue;
      }
    }
    return null;
  }

  static Iterable<String> candidates(String raw) sync* {
    final trimmed = raw.replaceAll('﻿', '').trim();
    yield trimmed;
    final unfenced = stripCodeFences(trimmed);
    if (unfenced != trimmed) yield unfenced;
    final extracted = extractBalancedObject(unfenced);
    if (extracted != null) {
      yield extracted;
      yield repair(extracted);
    } else {
      yield repair(unfenced);
    }
  }

  static String stripCodeFences(String input) {
    final fence = RegExp(r'```(?:json|JSON)?\s*([\s\S]*?)```');
    final m = fence.firstMatch(input);
    return m == null ? input : m.group(1)!.trim();
  }

  /// Primer objeto JSON balanceado o `null` si está truncado.
  static String? extractBalancedObject(String input) {
    final start = input.indexOf('{');
    if (start < 0) return null;
    var depth = 0;
    var inString = false;
    var escaped = false;
    for (var i = start; i < input.length; i++) {
      final c = input[i];
      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (c == r'\') {
          escaped = true;
        } else if (c == '"') {
          inString = false;
        }
        continue;
      }
      if (c == '"') {
        inString = true;
      } else if (c == '{') {
        depth++;
      } else if (c == '}') {
        depth--;
        if (depth == 0) return input.substring(start, i + 1);
      }
    }
    return null;
  }

  /// Reparaciones conservadoras fuera/dentro de cadenas.
  static String repair(String input) {
    final out = StringBuffer();
    var inString = false;
    var escaped = false;
    for (var i = 0; i < input.length; i++) {
      final c = input[i];
      if (inString) {
        if (escaped) {
          escaped = false;
          out.write(c);
          continue;
        }
        if (c == r'\') {
          escaped = true;
          out.write(c);
        } else if (c == '"') {
          inString = false;
          out.write(c);
        } else if (c == '\n') {
          out.write(r'\n');
        } else if (c == '\r') {
          out.write(r'\r');
        } else if (c == '\t') {
          out.write(r'\t');
        } else if (c.codeUnitAt(0) < 0x20) {
          // Otros caracteres de control se descartan.
        } else {
          out.write(c);
        }
        continue;
      }
      if (c == '"') {
        inString = true;
        out.write(c);
      } else if (c == ',') {
        var j = i + 1;
        while (j < input.length && input[j].trim().isEmpty) {
          j++;
        }
        if (j < input.length && (input[j] == '}' || input[j] == ']')) {
          continue; // coma final
        }
        out.write(c);
      } else {
        out.write(c);
      }
    }
    return out.toString();
  }
}

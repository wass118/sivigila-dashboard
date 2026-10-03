import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/config/app_limits.dart';
import '../../core/errors/humanizer_failure.dart';
import '../../core/utils/app_logger.dart';

/// Envío HTTP común a los adaptadores con traducción explícita de errores.
class HttpJsonTransport {
  HttpJsonTransport(this._client, {this.timeout = AppLimits.requestTimeout});

  final http.Client _client;
  final Duration timeout;

  Future<Map<String, dynamic>> postJson(
    Uri uri, {
    required Map<String, String> headers,
    required Map<String, dynamic> body,
    required String providerLabel,
  }) async {
    final started = DateTime.now();
    http.Response response;
    try {
      response = await _client
          .post(uri,
              headers: {'Content-Type': 'application/json', ...headers},
              body: jsonEncode(body))
          .timeout(timeout);
    } on TimeoutException {
      throw ConnectionFailure(
          'El proveedor no respondió en ${timeout.inSeconds} s. Intente de '
          'nuevo o reduzca el tamaño del texto.',
          technicalDetail: 'timeout host=${uri.host}');
    } on http.ClientException catch (e) {
      throw ConnectionFailure(
          'No fue posible conectar con ${uri.host}. Verifique la conexión y '
          'el endpoint.${kIsWeb ? ' En la versión Web, muchos proveedores '
              'bloquean llamadas directas desde el navegador (CORS): use el '
              'backend intermedio.' : ''}',
          technicalDetail: AppLogger.redact(e.message));
    } catch (e) {
      throw ConnectionFailure('Error de red al contactar ${uri.host}.',
          technicalDetail: AppLogger.redact(e.runtimeType.toString()));
    }

    final elapsed = DateTime.now().difference(started).inMilliseconds;
    AppLogger.info('http', '$providerLabel status=${response.statusCode} '
        'bytes=${response.bodyBytes.length} ms=$elapsed');

    final status = response.statusCode;
    if (status == 401 || status == 403) {
      throw AuthenticationFailure(
          'El proveedor rechazó las credenciales (HTTP $status). Revise la '
          'clave API en Ajustes.',
          technicalDetail: 'status=$status');
    }
    if (status == 429) {
      throw ProviderFailure(
          'Se alcanzó el límite de uso del proveedor (HTTP 429). Espere un '
          'momento antes de reintentar.',
          statusCode: status);
    }
    if (status >= 500) {
      throw ProviderFailure(
          'El proveedor presenta una falla temporal (HTTP $status).',
          statusCode: status);
    }
    if (status >= 400) {
      throw ProviderFailure(
          'El proveedor devolvió un error (HTTP $status): '
          '${_providerMessage(response.body)}',
          statusCode: status);
    }

    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) return decoded;
      throw const FormatException('cuerpo no es un objeto');
    } on FormatException catch (e) {
      throw InvalidResponseFailure(
          'La respuesta HTTP del proveedor no es JSON válido.',
          technicalDetail: e.message);
    }
  }

  /// Extrae un mensaje de error del proveedor, redactado y acotado.
  static String _providerMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final err = decoded['error'];
        final msg = err is Map ? err['message'] : (err ?? decoded['message']);
        if (msg != null) {
          final s = AppLogger.redact(msg.toString());
          return s.length > 200 ? '${s.substring(0, 200)}…' : s;
        }
      }
    } catch (_) {
      // Cuerpo no JSON: se ignora.
    }
    return 'sin detalle';
  }
}

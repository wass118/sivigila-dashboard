/// Jerarquía explícita de errores del dominio.
///
/// Cada subtipo representa una causa diferenciable por la interfaz. Los
/// mensajes para el usuario nunca incluyen claves, cabeceras ni el texto
/// procesado; `technicalDetail` es apto para logs (ya redactado).
sealed class HumanizerFailure implements Exception {
  const HumanizerFailure(this.userMessage, {this.technicalDetail});

  /// Mensaje comprensible para el usuario final.
  final String userMessage;

  /// Detalle técnico breve, sin datos sensibles.
  final String? technicalDetail;

  /// Título corto para diálogos y banners.
  String get title;

  @override
  String toString() => '$runtimeType: $userMessage'
      '${technicalDetail == null ? '' : ' ($technicalDetail)'}';
}

final class ConnectionFailure extends HumanizerFailure {
  const ConnectionFailure(super.userMessage, {super.technicalDetail});
  @override
  String get title => 'Error de conexión';
}

final class AuthenticationFailure extends HumanizerFailure {
  const AuthenticationFailure(super.userMessage, {super.technicalDetail});
  @override
  String get title => 'Error de autenticación';
}

final class ProviderFailure extends HumanizerFailure {
  const ProviderFailure(super.userMessage,
      {this.statusCode, super.technicalDetail});
  final int? statusCode;
  @override
  String get title => 'Error del proveedor de IA';
}

final class InvalidResponseFailure extends HumanizerFailure {
  const InvalidResponseFailure(super.userMessage, {super.technicalDetail});
  @override
  String get title => 'Respuesta inválida del modelo';
}

final class EmptyTextFailure extends HumanizerFailure {
  const EmptyTextFailure()
      : super('Escriba o pegue un texto antes de continuar.');
  @override
  String get title => 'Texto vacío';
}

final class TextTooLongFailure extends HumanizerFailure {
  TextTooLongFailure({required this.length, required this.limit})
      : super('El texto tiene $length caracteres y el límite permitido es '
            '$limit. Divida el documento o active la segmentación automática '
            'en Ajustes si aún no está activa.');
  final int length;
  final int limit;
  @override
  String get title => 'Límite de longitud superado';
}

final class ConfigurationFailure extends HumanizerFailure {
  const ConfigurationFailure(super.userMessage, {super.technicalDetail});
  @override
  String get title => 'Configuración incompleta';
}

/// Funcionalidad declarada en la arquitectura pero aún no disponible.
final class UnsupportedFeatureFailure extends HumanizerFailure {
  const UnsupportedFeatureFailure(super.userMessage);
  @override
  String get title => 'Funcionalidad no disponible';
}

final class UnexpectedFailure extends HumanizerFailure {
  const UnexpectedFailure(super.userMessage, {super.technicalDetail});
  @override
  String get title => 'Error inesperado';
}

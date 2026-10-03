/// Límites operativos del MVP. Centralizados para poder ajustarlos sin tocar
/// la lógica.
abstract final class AppLimits {
  /// Longitud máxima de un documento (caracteres). Por encima se rechaza.
  static const int maxDocumentChars = 60000;

  /// Caracteres máximos enviados al modelo por petición. ~12.000 caracteres
  /// de español equivalen aproximadamente a 3.000–3.500 tokens; con la
  /// salida JSON (texto reescrito + análisis) cabe en ventanas de 16k tokens.
  static const int maxCharsPerRequest = 12000;

  /// Contexto de solo lectura que se adjunta del segmento anterior.
  static const int segmentContextChars = 600;

  /// Registros máximos en el historial local.
  static const int historyMaxEntries = 50;

  /// Reintentos controlados ante JSON inválido del modelo.
  static const int maxInvalidJsonRetries = 1;

  /// Tiempo máximo de espera de una petición al proveedor.
  static const Duration requestTimeout = Duration(seconds: 120);

  /// Elementos protegidos máximos listados en el prompt (el resto se audita
  /// igualmente en local).
  static const int maxProtectedInPrompt = 150;
}

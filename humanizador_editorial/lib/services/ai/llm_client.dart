/// Petición neutral respecto del proveedor.
class LlmPrompt {
  const LlmPrompt({
    required this.system,
    required this.user,
    required this.temperature,
    required this.maxTokens,
    this.expectJson = true,
  });

  final String system;
  final String user;
  final double temperature;
  final int maxTokens;
  final bool expectJson;
}

/// Contrato mínimo que implementa cada adaptador de proveedor (OpenAI,
/// Anthropic, Gemini, Ollama, backend propio, modelo local...). Los servicios
/// de dominio dependen solo de esta interfaz.
abstract interface class LlmClient {
  /// Nombre legible del proveedor (sin datos sensibles).
  String get providerLabel;

  /// Verdadero si el texto sale del dispositivo hacia un host remoto.
  bool get isRemote;

  /// Devuelve el texto bruto generado por el modelo.
  Future<String> complete(LlmPrompt prompt);
}

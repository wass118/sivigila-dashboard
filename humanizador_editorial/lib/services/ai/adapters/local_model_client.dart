import '../../../core/errors/humanizer_failure.dart';
import '../llm_client.dart';

/// MODO LOCAL — FUTURA FUNCIONALIDAD.
///
/// Punto de extensión para modelos ejecutados en el dispositivo (por
/// ejemplo, llama.cpp vía FFI o MediaPipe LLM). No está implementado en esta
/// versión y lo declara explícitamente en lugar de simular resultados.
/// Mientras tanto, un servidor local compatible con OpenAI (Ollama,
/// LM Studio) puede usarse con [OpenAiCompatibleClient] y localhost.
class LocalModelClient implements LlmClient {
  const LocalModelClient();

  @override
  String get providerLabel => 'Modelo local (no disponible)';

  @override
  bool get isRemote => false;

  @override
  Future<String> complete(LlmPrompt prompt) => Future.error(
      const UnsupportedFeatureFailure(
          'El modo local con modelos en el dispositivo es una funcionalidad '
          'futura. Para trabajar sin enviar datos a internet, use un servidor '
          'local compatible con OpenAI (Ollama o LM Studio) en localhost.'));
}

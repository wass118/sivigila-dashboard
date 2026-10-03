import '../../../core/errors/humanizer_failure.dart';
import '../http_error_mapper.dart';
import '../llm_client.dart';

/// Adaptador para un backend intermedio propio (arquitectura de producción).
///
/// El backend guarda la clave del proveedor y aplica autenticación, cuotas y
/// auditoría. Contrato en `docs/backend_contract.md`:
///   POST {endpoint}  {system, user, temperature, maxTokens, expectJson, model}
///   → 200 {"text": "..."}
class BackendProxyClient implements LlmClient {
  BackendProxyClient({
    required this.transport,
    required this.endpoint,
    this.model = '',
    this.sessionToken,
    required this.isRemote,
  });

  final HttpJsonTransport transport;
  final String endpoint;
  final String model;

  /// Token de sesión del usuario ante el backend (no es la clave del
  /// proveedor de IA).
  final String? sessionToken;
  @override
  final bool isRemote;

  @override
  String get providerLabel => 'Backend intermedio';

  @override
  Future<String> complete(LlmPrompt prompt) async {
    final json = await transport.postJson(
      Uri.parse(endpoint),
      providerLabel: providerLabel,
      headers: {
        if (sessionToken != null && sessionToken!.isNotEmpty)
          'Authorization': 'Bearer $sessionToken',
      },
      body: {
        'system': prompt.system,
        'user': prompt.user,
        'temperature': prompt.temperature,
        'maxTokens': prompt.maxTokens,
        'expectJson': prompt.expectJson,
        if (model.isNotEmpty) 'model': model,
      },
    );
    final text = json['text'];
    if (text is String) return text;
    throw const InvalidResponseFailure(
        'El backend no devolvió el campo "text".');
  }
}

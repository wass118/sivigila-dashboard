import '../../../core/errors/humanizer_failure.dart';
import '../http_error_mapper.dart';
import '../llm_client.dart';

/// Adaptador para la Messages API de Anthropic.
class AnthropicClient implements LlmClient {
  AnthropicClient({
    required this.transport,
    required this.endpoint,
    required this.model,
    required this.apiKey,
  });

  static const String apiVersion = '2023-06-01';

  final HttpJsonTransport transport;
  final String endpoint;
  final String model;
  final String apiKey;

  @override
  String get providerLabel => 'Anthropic';

  @override
  bool get isRemote => true;

  @override
  Future<String> complete(LlmPrompt prompt) async {
    final json = await transport.postJson(
      Uri.parse(endpoint),
      providerLabel: providerLabel,
      headers: {'x-api-key': apiKey, 'anthropic-version': apiVersion},
      body: {
        'model': model,
        'max_tokens': prompt.maxTokens,
        'temperature': prompt.temperature,
        'system': prompt.system,
        'messages': [
          {'role': 'user', 'content': prompt.user},
        ],
      },
    );
    final content = json['content'];
    if (content is List) {
      final text = content
          .whereType<Map>()
          .where((b) => b['type'] == 'text')
          .map((b) => b['text']?.toString() ?? '')
          .join();
      if (text.isNotEmpty) return text;
    }
    throw const InvalidResponseFailure(
        'El proveedor no devolvió bloques de texto en "content".');
  }
}

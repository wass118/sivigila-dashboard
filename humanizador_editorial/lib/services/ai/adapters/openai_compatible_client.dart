import '../../../core/errors/humanizer_failure.dart';
import '../http_error_mapper.dart';
import '../llm_client.dart';

/// Adaptador para endpoints compatibles con OpenAI Chat Completions
/// (OpenAI, Ollama, LM Studio, vLLM, llama.cpp server, Azure con proxy...).
class OpenAiCompatibleClient implements LlmClient {
  OpenAiCompatibleClient({
    required this.transport,
    required this.endpoint,
    required this.model,
    this.apiKey,
    this.jsonMode = false,
    required this.isRemote,
  });

  final HttpJsonTransport transport;
  final String endpoint;
  final String model;
  final String? apiKey;
  final bool jsonMode;
  @override
  final bool isRemote;

  @override
  String get providerLabel => 'Compatible OpenAI';

  @override
  Future<String> complete(LlmPrompt prompt) async {
    final json = await transport.postJson(
      Uri.parse(endpoint),
      providerLabel: providerLabel,
      headers: {
        if (apiKey != null && apiKey!.isNotEmpty)
          'Authorization': 'Bearer $apiKey',
      },
      body: {
        'model': model,
        'temperature': prompt.temperature,
        'max_tokens': prompt.maxTokens,
        'messages': [
          {'role': 'system', 'content': prompt.system},
          {'role': 'user', 'content': prompt.user},
        ],
        if (jsonMode && prompt.expectJson)
          'response_format': {'type': 'json_object'},
      },
    );
    final choices = json['choices'];
    if (choices is List && choices.isNotEmpty) {
      final message = (choices.first as Map?)?['message'];
      final content = message is Map ? message['content'] : null;
      if (content is String) return content;
    }
    throw const InvalidResponseFailure(
        'El proveedor no devolvió contenido en "choices".');
  }
}

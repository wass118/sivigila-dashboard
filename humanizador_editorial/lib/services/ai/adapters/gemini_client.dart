import '../../../core/errors/humanizer_failure.dart';
import '../http_error_mapper.dart';
import '../llm_client.dart';

/// Adaptador para Google Gemini (generateContent).
class GeminiClient implements LlmClient {
  GeminiClient({
    required this.transport,
    required this.endpointTemplate,
    required this.model,
    required this.apiKey,
    this.jsonMode = false,
  });

  final HttpJsonTransport transport;

  /// Admite el marcador `{model}`.
  final String endpointTemplate;
  final String model;
  final String apiKey;
  final bool jsonMode;

  @override
  String get providerLabel => 'Google Gemini';

  @override
  bool get isRemote => true;

  @override
  Future<String> complete(LlmPrompt prompt) async {
    final uri = Uri.parse(
        endpointTemplate.replaceAll('{model}', Uri.encodeComponent(model)));
    final json = await transport.postJson(
      uri,
      providerLabel: providerLabel,
      // La clave va en cabecera, no en la URL, para no exponerla en logs.
      headers: {'x-goog-api-key': apiKey},
      body: {
        'systemInstruction': {
          'parts': [
            {'text': prompt.system},
          ],
        },
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': prompt.user},
            ],
          },
        ],
        'generationConfig': {
          'temperature': prompt.temperature,
          'maxOutputTokens': prompt.maxTokens,
          if (jsonMode && prompt.expectJson)
            'responseMimeType': 'application/json',
        },
      },
    );
    final candidates = json['candidates'];
    if (candidates is List && candidates.isNotEmpty) {
      final content = (candidates.first as Map?)?['content'];
      final parts = content is Map ? content['parts'] : null;
      if (parts is List) {
        final text = parts
            .whereType<Map>()
            .map((p) => p['text']?.toString() ?? '')
            .join();
        if (text.isNotEmpty) return text;
      }
    }
    throw const InvalidResponseFailure(
        'El proveedor no devolvió texto en "candidates".');
  }
}

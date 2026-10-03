import 'package:http/http.dart' as http;

import '../../core/config/ai_provider_settings.dart';
import '../../core/config/app_environment.dart';
import '../../core/errors/humanizer_failure.dart';
import '../../core/prompts/prompt_builder.dart';
import '../analysis/local_text_analyzer.dart';
import 'adapters/anthropic_client.dart';
import 'adapters/backend_proxy_client.dart';
import 'adapters/gemini_client.dart';
import 'adapters/local_model_client.dart';
import 'adapters/openai_compatible_client.dart';
import 'fake_humanizer_service.dart';
import 'http_error_mapper.dart';
import 'humanizer_service.dart';
import 'llm_client.dart';
import 'llm_humanizer_service.dart';

/// Construye el [HumanizerService] adecuado según el modo de entorno y la
/// configuración. Es el único lugar que conoce los adaptadores concretos.
class HumanizerServiceFactory {
  HumanizerServiceFactory({
    required http.Client httpClient,
    required this.analyzer,
    this.mode = HumanizerMode.auto,
    this.fakeLatency = const Duration(milliseconds: 500),
  }) : _transport = HttpJsonTransport(httpClient);

  final HttpJsonTransport _transport;
  final LocalTextAnalyzer analyzer;
  final HumanizerMode mode;
  final Duration fakeLatency;

  bool usesDemo(AiProviderSettings settings) =>
      mode == HumanizerMode.demo ||
      (mode == HumanizerMode.auto &&
          settings.providerType == AiProviderType.demo);

  /// Descriptor sin construir el servicio (para la interfaz).
  ProviderDescriptor describe(AiProviderSettings settings) {
    if (usesDemo(settings)) {
      return FakeHumanizerService(analyzer: analyzer).descriptor;
    }
    return ProviderDescriptor(
      label: settings.providerType.label,
      isRemote: settings.isRemote,
      isDemo: false,
      endpointHost: settings.endpointHost,
      model: settings.model,
    );
  }

  HumanizerService create(AiProviderSettings settings, {String? apiKey}) {
    if (usesDemo(settings)) {
      return FakeHumanizerService(analyzer: analyzer, latency: fakeLatency);
    }
    if (settings.providerType == AiProviderType.demo) {
      throw const ConfigurationFailure(
          'La aplicación se inició con HUMANIZER_MODE=real, pero el '
          'proveedor seleccionado en Ajustes es la demostración. Elija un '
          'proveedor real.');
    }
    final client = createClient(settings, apiKey: apiKey);
    return LlmHumanizerService(
      client: client,
      prompts: PromptBuilder(
        baseTemperature: settings.temperature,
        maxOutputTokens: settings.maxOutputTokens,
      ),
      endpointHost: settings.endpointHost,
      model: settings.model,
    );
  }

  LlmClient createClient(AiProviderSettings settings, {String? apiKey}) {
    final type = settings.providerType;
    if (!type.implemented) return const LocalModelClient();

    final endpoint = settings.effectiveEndpoint;
    final uri = Uri.tryParse(endpoint);
    if (endpoint.isEmpty || uri == null || !uri.hasScheme ||
        uri.host.isEmpty) {
      throw const ConfigurationFailure(
          'Configure una URL de endpoint válida (http/https) en Ajustes.');
    }
    if (uri.scheme != 'https' && settings.isRemote) {
      throw const ConfigurationFailure(
          'Por seguridad, los endpoints remotos deben usar HTTPS. Solo se '
          'admite HTTP para localhost.');
    }
    if (settings.model.trim().isEmpty && type != AiProviderType.backendProxy) {
      throw const ConfigurationFailure(
          'Indique el identificador del modelo en Ajustes.');
    }
    if (type.requiresApiKey && (apiKey == null || apiKey.isEmpty)) {
      throw const ConfigurationFailure(
          'Este proveedor requiere una clave API. Guárdela en Ajustes.');
    }

    return switch (type) {
      AiProviderType.openAiCompatible => OpenAiCompatibleClient(
          transport: _transport,
          endpoint: endpoint,
          model: settings.model.trim(),
          apiKey: apiKey,
          jsonMode: settings.jsonMode,
          isRemote: settings.isRemote,
        ),
      AiProviderType.anthropic => AnthropicClient(
          transport: _transport,
          endpoint: endpoint,
          model: settings.model.trim(),
          apiKey: apiKey!,
        ),
      AiProviderType.gemini => GeminiClient(
          transport: _transport,
          endpointTemplate: endpoint,
          model: settings.model.trim(),
          apiKey: apiKey!,
          jsonMode: settings.jsonMode,
        ),
      AiProviderType.backendProxy => BackendProxyClient(
          transport: _transport,
          endpoint: endpoint,
          model: settings.model.trim(),
          sessionToken: apiKey,
          isRemote: settings.isRemote,
        ),
      AiProviderType.localModel || AiProviderType.demo =>
        const LocalModelClient(),
    };
  }
}

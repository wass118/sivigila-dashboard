import '../../core/config/app_limits.dart';
import '../../core/errors/humanizer_failure.dart';
import '../../core/prompts/prompt_builder.dart';
import '../../core/utils/app_logger.dart';
import '../../models/humanization_result.dart';
import '../../models/text_analysis.dart';
import 'humanizer_service.dart';
import 'llm_client.dart';
import 'response_parser.dart';

/// Implementación de [HumanizerService] sobre cualquier [LlmClient].
///
/// Incluye validación del JSON y un segundo intento controlado cuando la
/// respuesta es inválida (como máximo [AppLimits.maxInvalidJsonRetries]).
class LlmHumanizerService implements HumanizerService {
  LlmHumanizerService({
    required this.client,
    required this.prompts,
    this.parser = const ResponseParser(),
    this.endpointHost = '',
    this.model = '',
  });

  final LlmClient client;
  final PromptBuilder prompts;
  final ResponseParser parser;
  final String endpointHost;
  final String model;

  @override
  ProviderDescriptor get descriptor => ProviderDescriptor(
        label: client.providerLabel,
        isRemote: client.isRemote,
        isDemo: false,
        endpointHost: endpointHost,
        model: model,
      );

  @override
  Future<TextAnalysis> analyze(AnalysisInput input) {
    final prompt = prompts.analysis(input.context, input.text,
        local: input.local, partial: input.partial);
    return _completeValidated(prompt, parser.parseAnalysis, 'analysis');
  }

  @override
  Future<HumanizationResult> humanize(HumanizationInput input) {
    final prompt = prompts.humanization(
      input.context,
      input.text,
      protectedElements: input.protectedElements,
      analysis: input.analysis,
      segmentIndex: input.segmentIndex,
      segmentCount: input.segmentCount,
      contextBefore: input.contextBefore,
    );
    return _completeValidated(
      prompt,
      (raw) => parser.parseHumanization(raw,
          expectRewrite: input.context.intensity.producesRewrite,
          providerLabel: client.providerLabel),
      'humanize',
    );
  }

  @override
  Future<HumanizationResult> rewriteFragment(FragmentInput input) {
    final prompt = prompts.fragment(
      input.context,
      fragment: input.fragment,
      originalReference: input.originalReference,
      contextBefore: input.contextBefore,
      contextAfter: input.contextAfter,
      protectedElements: input.protectedElements,
    );
    return _completeValidated(
      prompt,
      (raw) => parser.parseFragment(raw, providerLabel: client.providerLabel),
      'fragment',
    );
  }

  Future<T> _completeValidated<T>(
      LlmPrompt prompt, T Function(String raw) parse, String op) async {
    var current = prompt;
    for (var attempt = 0;; attempt++) {
      final raw = await _guard(() => client.complete(current));
      try {
        final value = parse(raw);
        AppLogger.info('llm', '$op ok intento=${attempt + 1} '
            'chars=${raw.length}');
        return value;
      } on InvalidResponseFailure catch (e) {
        AppLogger.warning('llm', '$op JSON inválido intento=${attempt + 1}: '
            '${e.technicalDetail ?? e.userMessage}');
        if (attempt >= AppLimits.maxInvalidJsonRetries) {
          throw InvalidResponseFailure(
              'El modelo no devolvió una respuesta estructurada válida tras '
              '${attempt + 1} intentos. Pruebe de nuevo, reduzca el texto o '
              'active el modo JSON en Ajustes si su proveedor lo admite.',
              technicalDetail: e.technicalDetail);
        }
        current = prompts.repair(prompt, e.userMessage);
      }
    }
  }

  /// Garantiza que cualquier error inesperado del adaptador se traduzca a
  /// [HumanizerFailure] y nunca llegue sin tipar a la interfaz.
  Future<String> _guard(Future<String> Function() call) async {
    try {
      return await call();
    } on HumanizerFailure {
      rethrow;
    } catch (e) {
      throw UnexpectedFailure('Ocurrió un error inesperado al consultar el '
          'proveedor.', technicalDetail: e.runtimeType.toString());
    }
  }
}

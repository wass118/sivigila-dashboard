import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:humanizador_editorial/core/config/editorial_catalog.dart';
import 'package:humanizador_editorial/core/errors/humanizer_failure.dart';
import 'package:humanizador_editorial/core/prompts/prompt_builder.dart';
import 'package:humanizador_editorial/demo/demo_samples.dart';
import 'package:humanizador_editorial/models/audit_report.dart';
import 'package:humanizador_editorial/models/editorial_request.dart';
import 'package:humanizador_editorial/models/fidelity_warning.dart';
import 'package:humanizador_editorial/models/intensity.dart';
import 'package:humanizador_editorial/models/pipeline_models.dart';
import 'package:humanizador_editorial/services/ai/adapters/openai_compatible_client.dart';
import 'package:humanizador_editorial/services/ai/http_error_mapper.dart';
import 'package:humanizador_editorial/services/ai/llm_humanizer_service.dart';
import 'package:humanizador_editorial/services/pipeline/editorial_pipeline.dart';

/// Simula un proveedor OpenAI-compatible a nivel HTTP. La respuesta de
/// reescritura se construye con [rewrite] a partir del texto recibido.
class SimulatedProvider {
  SimulatedProvider({required this.rewrite, this.malformedFirst = false});

  final String Function(String original) rewrite;
  final bool malformedFirst;
  int humanizeCalls = 0;
  int analysisCalls = 0;

  static String extractText(String user) {
    final start = user.lastIndexOf(PromptBuilder.textStart);
    final end = user.lastIndexOf(PromptBuilder.textEnd);
    return user
        .substring(start + PromptBuilder.textStart.length, end)
        .trim();
  }

  http.Client get client => MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final user = (body['messages'] as List).last['content'] as String;
        String content;
        if (user.startsWith('TAREA: diagnostica')) {
          analysisCalls++;
          content = jsonEncode({
            'dominioDetectado': 'Vigilancia en salud pública',
            'audienciaDetectada': 'Técnica',
            'tonoDetectado': 'Formal',
            'nivelFormalidad': 'Alta',
            'proposito': 'Informe de situación',
            'nivelTecnico': 'alto',
            'problemas': [
              {'categoria': 'Lenguaje genérico',
               'descripcion': 'Fórmula vacía al inicio.',
               'fragmento': 'Es importante destacar que'}
            ],
            'observaciones': ['Diferenciar dato e interpretación.'],
          });
        } else {
          humanizeCalls++;
          if (malformedFirst && humanizeCalls == 1) {
            content = 'Claro, aquí tienes: {"rewrittenText": "incompleto';
          } else {
            content = '```json\n${jsonEncode({
              'analysis': {'dominioDetectado': 'Vigilancia'},
              'rewrittenText': rewrite(extractText(user)),
              'recommendations': [
                {'categoria': 'precision_tecnica',
                 'fragmento': 'se debe a la temporada de lluvias',
                 'problema': 'Inferencia causal sin sustento en el texto.',
                 'sugerencia': 'Presentarla como hipótesis o citar evidencia.'}
              ],
              'fidelityWarnings': [],
              'protectedElements': [],
              'improvements': ['Se eliminaron fórmulas genéricas.'],
            })}\n```';
          }
        }
        return http.Response(
            jsonEncode({
              'choices': [
                {'message': {'role': 'assistant', 'content': content}}
              ]
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'});
      });
}

EditorialPipeline buildPipeline(SimulatedProvider provider,
    {int maxCharsPerRequest = 12000}) {
  final domains = EditorialCatalog.domainRegistry();
  return EditorialPipeline(
    service: LlmHumanizerService(
      client: OpenAiCompatibleClient(
        transport: HttpJsonTransport(provider.client),
        endpoint: 'https://proveedor.simulado/v1/chat/completions',
        model: 'modelo-simulado',
        isRemote: true,
      ),
      prompts: const PromptBuilder(baseTemperature: 0.3, maxOutputTokens: 4096),
    ),
    domains: domains,
    audiences: EditorialCatalog.audienceCatalog(),
    goals: EditorialCatalog.goalCatalog(),
    authors: EditorialCatalog.authorCatalog(),
    maxCharsPerRequest: maxCharsPerRequest,
  );
}

String faithfulRewrite(String t) => t
    .replaceAll('Es importante destacar que, con', 'Con')
    .replaceAll('un total de ', '')
    .replaceAll('Cabe mencionar que se llevó a cabo', 'Se realizó')
    .replaceAll('Además, se llevó a cabo', 'Además, se realizó')
    .replaceAll('Además, se realizó la verificación de', 'También se verificó')
    .replaceAll('Con el fin de', 'Para');

void main() {
  const request = EditorialRequest(
    text: DemoSamples.publicHealth,
    options: EditorialOptions(
        domainId: 'auto', audienceId: 'tecnica', goalId: 'claridad',
        intensity: Intensity.moderate, authorProfileId: 'epidemiologo'),
  );

  test('flujo completo con respuesta fiel del proveedor', () async {
    final provider = SimulatedProvider(rewrite: faithfulRewrite);
    final pipeline = buildPipeline(provider);
    final phases = <PipelinePhase, PhaseStatus>{};
    void onPhase(PipelinePhase p, PhaseState s) => phases[p] = s.status;

    final analysis = await pipeline.analyze(request, onPhase: onPhase);
    expect(analysis.effectiveDomain.id, 'vigilancia_sp_co');
    expect(analysis.analysis.problems, isNotEmpty);
    expect(analysis.protectedElements.length, greaterThan(20));

    final output = await pipeline.humanize(request, analysis, onPhase: onPhase);
    expect(phases.values.every((s) => s == PhaseStatus.done), isTrue);
    expect(provider.analysisCalls, 1);
    expect(provider.humanizeCalls, 1);

    final text = output.result.rewrittenText!;
    for (final value in ['1.248', '412', '33,01 %', '37', '351,99',
        '100.000 habitantes', '11,5 %', '2025', 'semana epidemiológica 36 de 2026',
        'código de evento 210', 'código 220', '5,41 %', 'SIVIGILA', 'UPGD',
        'EAPB', 'INS', 'Aedes aegypti', '9 de septiembre de 2026']) {
      expect(text, contains(value), reason: value);
    }
    expect(output.audit.status, AuditStatus.editorialChanges);
    expect(output.audit.warnings.where((w) => w.severity == WarningSeverity.high),
        isEmpty);
    expect(output.result.recommendations.single.category.name,
        'technicalAccuracy');
    expect(output.audit.indexAfter, isNotNull);
  });

  test('la auditoría detecta cifras alteradas por el proveedor', () async {
    final provider = SimulatedProvider(
        rewrite: (t) => faithfulRewrite(t)
            .replaceAll('351,99', '352')
            .replaceAll('100.000 habitantes', '10.000 habitantes')
            .replaceAll('2026', '2025')
            .replaceAll(' (IEC)', ''));
    final pipeline = buildPipeline(provider);
    final analysis = await pipeline.analyze(request);
    final output = await pipeline.humanize(request, analysis);

    expect(output.audit.status, AuditStatus.possibleTechnicalChange);
    final high = output.audit.warnings
        .where((w) => w.severity == WarningSeverity.high)
        .toList();
    expect(high.any((w) => w.originalValue == '351,99' && w.foundValue == '352'),
        isTrue);
    expect(high.any((w) => w.originalValue == '100.000'), isTrue);
    expect(output.audit.warnings.any((w) => w.originalValue == 'IEC'), isTrue);
    // El texto nunca se corrige automáticamente.
    expect(output.result.rewrittenText, contains('352'));
  });

  test('JSON mal formado del proveedor → reintento controlado', () async {
    final provider =
        SimulatedProvider(rewrite: faithfulRewrite, malformedFirst: true);
    final pipeline = buildPipeline(provider);
    final analysis = await pipeline.analyze(request);
    final output = await pipeline.humanize(request, analysis);
    expect(provider.humanizeCalls, 2);
    expect(output.result.rewrittenText, isNotEmpty);
  });

  test('documento largo: segmentación y recomposición', () async {
    final provider = SimulatedProvider(rewrite: (t) => t);
    final pipeline = buildPipeline(provider, maxCharsPerRequest: 700);
    // > 8000 caracteres: ejercita también el análisis y la auditoría en isolate.
    final longText = List.filled(8, DemoSamples.publicHealth).join('\n\n');
    expect(longText.length, greaterThan(8000));
    final req = EditorialRequest(text: longText, options: request.options);
    final analysis = await pipeline.analyze(req);
    expect(analysis.segmentCount, greaterThan(1));
    final output = await pipeline.humanize(req, analysis);
    expect(provider.humanizeCalls, analysis.segmentCount);
    expect(output.result.rewrittenText!.replaceAll(RegExp(r'\s+'), ' '),
        longText.replaceAll(RegExp(r'\s+'), ' ').trim());
    expect(output.audit.status, AuditStatus.noTechnicalChanges);
  });

  test('regeneración de un párrafo y nueva auditoría', () async {
    final provider = SimulatedProvider(rewrite: faithfulRewrite);
    final pipeline = buildPipeline(provider);
    final analysis = await pipeline.analyze(request);
    final first = await pipeline.humanize(request, analysis);
    final second = await pipeline.regenerateParagraph(
        request: request, analysis: analysis, current: first, paragraphIndex: 1);
    expect(provider.humanizeCalls, 2);
    expect(second.originalText, first.originalText);
    expect(second.result.improvements.last, startsWith('Párrafo 2 regenerado'));
  });

  test('validación previa: vacío y demasiado largo', () async {
    final pipeline = buildPipeline(SimulatedProvider(rewrite: (t) => t));
    await expectLater(
        pipeline.analyze(const EditorialRequest(
            text: '   ', options: EditorialOptions())),
        throwsA(isA<EmptyTextFailure>()));
    await expectLater(
        pipeline.analyze(EditorialRequest(
            text: 'a' * 60001, options: const EditorialOptions())),
        throwsA(isA<TextTooLongFailure>()));
  });
}

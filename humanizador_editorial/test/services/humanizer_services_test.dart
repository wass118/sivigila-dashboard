import 'package:flutter_test/flutter_test.dart';
import 'package:humanizador_editorial/core/config/editorial_catalog.dart';
import 'package:humanizador_editorial/core/errors/humanizer_failure.dart';
import 'package:humanizador_editorial/core/prompts/prompt_builder.dart';
import 'package:humanizador_editorial/demo/demo_samples.dart';
import 'package:humanizador_editorial/models/intensity.dart';
import 'package:humanizador_editorial/models/protected_element.dart';
import 'package:humanizador_editorial/services/ai/fake_humanizer_service.dart';
import 'package:humanizador_editorial/services/ai/humanizer_service.dart';
import 'package:humanizador_editorial/services/ai/llm_humanizer_service.dart';
import 'package:humanizador_editorial/services/analysis/local_text_analyzer.dart';
import 'package:humanizador_editorial/services/audit/protected_content_detector.dart';

import '../helpers/test_helpers.dart';

const validHumanization = '{"analysis": {"dominioDetectado": "Vigilancia"}, '
    '"rewrittenText": "Versión editada.", "recommendations": [], '
    '"fidelityWarnings": [], "protectedElements": [], '
    '"improvements": ["Se simplificó."]}';

void main() {
  final detector = ProtectedContentDetector();
  final analyzer = LocalTextAnalyzer(domains: EditorialCatalog.domainRegistry());

  HumanizationInput input(String text,
          {Intensity intensity = Intensity.moderate}) =>
      HumanizationInput(
        text: text,
        context: contextFor(intensity: intensity),
        protectedElements: detector.detect(text,
            technicalTerms: publicHealthDomain().protectedTerms,
            eventNames: publicHealthDomain().eventNames),
      );

  group('FakeHumanizerService (demostración)', () {
    final fake =
        FakeHumanizerService(analyzer: analyzer, latency: Duration.zero);

    test('conserva literalmente todos los elementos protegidos', () async {
      final i = input(DemoSamples.publicHealth, intensity: Intensity.deep);
      final r = await fake.humanize(i);
      expect(r.isDemo, isTrue);
      expect(r.rewrittenText, isNot(DemoSamples.publicHealth));
      for (final p in i.protectedElements) {
        expect(r.rewrittenText, contains(p.value), reason: p.value);
      }
      expect(r.improvements.first, FakeHumanizerService.demoNotice);
    });

    test('elimina fórmulas genéricas y respeta la mayúscula inicial', () async {
      final r = await fake.humanize(
          input('Es importante destacar que se llevó a cabo la reunión.'));
      expect(r.rewrittenText, 'Se realizó la reunión.');
    });

    test('la intensidad conservadora no suprime fórmulas genéricas', () async {
      final r = await fake.humanize(input(
          'Es importante destacar que se llevó a cabo la reunión.',
          intensity: Intensity.conservative));
      expect(r.rewrittenText, startsWith('Es importante destacar que'));
      expect(r.rewrittenText, contains('se realizó'));
    });

    test('solo recomendaciones: sin texto nuevo', () async {
      final r = await fake.humanize(input(DemoSamples.publicHealth,
          intensity: Intensity.recommendationsOnly));
      expect(r.rewrittenText, isNull);
      expect(r.recommendations, isNotEmpty);
    });

    test('no altera texto dentro de un elemento protegido', () async {
      const text = 'Ver https://x.org/con-el-fin-de con el fin de leer.';
      final protectedEls = [
        const ProtectedElement(
            value: 'https://x.org/con-el-fin-de',
            type: ProtectedType.reference,
            start: 4,
            end: 31),
      ];
      final r = await fake.humanize(HumanizationInput(
          text: text,
          context: contextFor(),
          protectedElements: protectedEls));
      expect(r.rewrittenText, 'Ver https://x.org/con-el-fin-de para leer.');
    });
  });

  group('LlmHumanizerService', () {
    LlmHumanizerService service(ScriptedLlmClient client) =>
        LlmHumanizerService(
          client: client,
          prompts: const PromptBuilder(
              baseTemperature: 0.3, maxOutputTokens: 1000),
        );

    test('respuesta válida al primer intento', () async {
      final client = ScriptedLlmClient([validHumanization]);
      final r = await service(client).humanize(input('Texto 1.'));
      expect(r.rewrittenText, 'Versión editada.');
      expect(client.prompts, hasLength(1));
    });

    test('JSON inválido → segundo intento controlado y éxito', () async {
      final client = ScriptedLlmClient(['Lo siento, aquí va: {roto', validHumanization]);
      final r = await service(client).humanize(input('Texto 1.'));
      expect(r.rewrittenText, 'Versión editada.');
      expect(client.prompts, hasLength(2));
      expect(client.prompts[1].user, contains('## CORRECCIÓN'));
      expect(client.prompts[1].temperature, lessThanOrEqualTo(0.2));
    });

    test('dos respuestas inválidas → InvalidResponseFailure (sin crash)',
        () async {
      final client = ScriptedLlmClient(['nada', 'tampoco']);
      await expectLater(service(client).humanize(input('Texto 1.')),
          throwsA(isA<InvalidResponseFailure>()));
      expect(client.prompts, hasLength(2));
    });

    test('errores tipados del adaptador se propagan sin reintentar', () async {
      final client = ScriptedLlmClient(
          [const AuthenticationFailure('credenciales')]);
      await expectLater(service(client).humanize(input('Texto 1.')),
          throwsA(isA<AuthenticationFailure>()));
      expect(client.prompts, hasLength(1));
    });

    test('excepción no tipada → UnexpectedFailure', () async {
      final client = ScriptedLlmClient([StateError('boom')]);
      await expectLater(service(client).humanize(input('Texto 1.')),
          throwsA(isA<UnexpectedFailure>()));
    });

    test('el prompt tiene las cuatro secciones y los datos protegidos',
        () async {
      final client = ScriptedLlmClient([validHumanization]);
      await service(client).humanize(input(DemoSamples.publicHealth));
      final p = client.prompts.single;
      for (final section in [
        '## CONTEXTO DE DOMINIO', '## RESTRICCIONES', '## ESTILO',
        '## FORMATO DE SALIDA'
      ]) {
        expect(p.user, contains(section));
      }
      expect(p.user, contains('351,99 casos por 100.000 habitantes'));
      expect(p.user, contains('Vigilancia en Salud Pública – Colombia'));
      expect(p.system, contains('No inventas hechos'));
      expect(p.temperature, 0.3);
    });

    test('solo recomendaciones usa temperatura de análisis', () async {
      final client = ScriptedLlmClient(['{"rewrittenText": null}']);
      final r = await service(client).humanize(
          input('Texto 1.', intensity: Intensity.recommendationsOnly));
      expect(r.rewrittenText, isNull);
      expect(client.prompts.single.temperature, 0.2);
      expect(client.prompts.single.user, contains('"rewrittenText" debe ser null'));
    });
  });
}

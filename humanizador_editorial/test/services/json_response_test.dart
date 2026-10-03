import 'package:flutter_test/flutter_test.dart';
import 'package:humanizador_editorial/core/errors/humanizer_failure.dart';
import 'package:humanizador_editorial/core/utils/json_sanitizer.dart';
import 'package:humanizador_editorial/models/fidelity_warning.dart';
import 'package:humanizador_editorial/models/recommendation.dart';
import 'package:humanizador_editorial/services/ai/response_parser.dart';

void main() {
  group('JsonSanitizer', () {
    test('JSON directo', () {
      expect(JsonSanitizer.tryDecodeObject('{"a": 1}'), {'a': 1});
    });

    test('bloque de código Markdown y texto alrededor', () {
      const raw = 'Aquí está:\n```json\n{"a": "x"}\n```\nGracias.';
      expect(JsonSanitizer.tryDecodeObject(raw), {'a': 'x'});
    });

    test('texto antes y después sin bloque de código', () {
      const raw = 'Respuesta: {"a": {"b": "}"}} fin';
      expect(JsonSanitizer.tryDecodeObject(raw), {'a': {'b': '}'}});
    });

    test('comas finales y saltos de línea sin escapar', () {
      const raw = '{"t": "línea 1\nlínea 2", "l": [1, 2,],}';
      expect(JsonSanitizer.tryDecodeObject(raw),
          {'t': 'línea 1\nlínea 2', 'l': [1, 2]});
    });

    test('JSON truncado devuelve null sin lanzar', () {
      expect(JsonSanitizer.tryDecodeObject('{"a": "sin cerrar'), isNull);
      expect(JsonSanitizer.tryDecodeObject('no es json'), isNull);
      expect(JsonSanitizer.tryDecodeObject('[1,2]'), isNull);
    });
  });

  group('ResponseParser', () {
    const parser = ResponseParser();

    test('respuesta completa válida', () {
      const raw = '''{
        "analysis": {"dominioDetectado": "Vigilancia", "audienciaDetectada": "Técnica",
          "tonoDetectado": "Formal", "nivelTecnico": "alto", "problemas": [], "observaciones": []},
        "rewrittenText": "Texto nuevo.",
        "recommendations": [{"categoria": "redundancia", "fragmento": "un total de", "problema": "p", "sugerencia": "s"}],
        "fidelityWarnings": [{"tipo": "Cifra", "original": "1", "encontrado": "2", "mensaje": "m", "severidad": "alta"}],
        "protectedElements": [{"valor": "SIVIGILA", "tipo": "sigla"}],
        "improvements": ["Se eliminó una fórmula genérica."]
      }''';
      final r = parser.parseHumanization(raw, expectRewrite: true);
      expect(r.rewrittenText, 'Texto nuevo.');
      expect(r.analysis.detectedDomain, 'Vigilancia');
      expect(r.recommendations.single.category,
          RecommendationCategory.redundancy);
      expect(r.fidelityWarnings.single.severity, WarningSeverity.high);
      expect(r.protectedElements.single.value, 'SIVIGILA');
      expect(r.improvements, hasLength(1));
    });

    test('falta rewrittenText cuando se pidió reescritura → error tipado', () {
      expect(
          () => parser.parseHumanization('{"recommendations": []}',
              expectRewrite: true),
          throwsA(isA<InvalidResponseFailure>()));
    });

    test('modo solo recomendaciones acepta rewrittenText null', () {
      final r = parser.parseHumanization(
          '{"rewrittenText": null, "recommendations": ["usar frases breves"]}',
          expectRewrite: false);
      expect(r.rewrittenText, isNull);
      expect(r.recommendations.single.problem, 'usar frases breves');
    });

    test('ignora rewrittenText si no se pidió reescritura', () {
      final r = parser.parseHumanization('{"rewrittenText": "x"}',
          expectRewrite: false);
      expect(r.rewrittenText, isNull);
    });

    test('listas con tipos incorrectos se toleran', () {
      final r = parser.parseHumanization(
          '{"rewrittenText": "x", "recommendations": "no es lista", '
          '"fidelityWarnings": [null, "texto suelto"]}',
          expectRewrite: true);
      expect(r.recommendations, isEmpty);
      expect(r.fidelityWarnings.single.message, 'texto suelto');
    });

    test('JSON mal formado → InvalidResponseFailure', () {
      expect(() => parser.parseHumanization('{roto', expectRewrite: true),
          throwsA(isA<InvalidResponseFailure>()));
      expect(() => parser.parseAnalysis(''),
          throwsA(isA<InvalidResponseFailure>()));
    });

    test('análisis sin campos esperados → error', () {
      expect(() => parser.parseAnalysis('{"otra": 1}'),
          throwsA(isA<InvalidResponseFailure>()));
      final a = parser.parseAnalysis(
          '{"dominioDetectado": "General", "problemas": []}');
      expect(a.detectedDomain, 'General');
    });
  });
}

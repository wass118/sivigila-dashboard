import 'package:flutter_test/flutter_test.dart';
import 'package:humanizador_editorial/core/config/editorial_catalog.dart';
import 'package:humanizador_editorial/demo/demo_samples.dart';
import 'package:humanizador_editorial/services/analysis/editorial_metrics.dart';
import 'package:humanizador_editorial/services/analysis/local_text_analyzer.dart';
import 'package:humanizador_editorial/services/audit/protected_content_detector.dart';
import 'package:humanizador_editorial/services/pipeline/editorial_pipeline.dart';
import 'package:humanizador_editorial/services/pipeline/text_segmenter.dart';

void main() {
  group('TextSegmenter', () {
    const seg = TextSegmenter();

    test('texto corto: un solo segmento', () {
      final s = seg.split('Hola.', maxChars: 100);
      expect(s, hasLength(1));
    });

    test('divide por párrafos y recompone sin pérdidas', () {
      final paragraphs = List.generate(
          8, (i) => 'Párrafo $i con datos 1$i,5 % y texto de relleno suficiente.');
      final text = paragraphs.join('\n\n');
      final segments = seg.split(text, maxChars: 150, contextChars: 40);
      expect(segments.length, greaterThan(1));
      for (final s in segments) {
        expect(s.text.length, lessThanOrEqualTo(150));
      }
      expect(segments[1].contextBefore, isNotEmpty);
      final joined = seg.join(segments, segments.map((s) => s.text).toList());
      expect(joined, text);
    });

    test('no corta dentro de un elemento protegido ni de una oración', () {
      final sentence = 'La incidencia fue de 351,99 casos por 100.000 '
          'habitantes en la semana epidemiológica 36. ';
      final text = sentence * 12;
      final protectedSpans = ProtectedContentDetector().detect(text);
      final segments =
          seg.split(text, maxChars: 300, protectedSpans: protectedSpans);
      expect(segments.length, greaterThan(1));
      for (final s in segments) {
        expect(s.text.trim().endsWith('36.'), isTrue,
            reason: 'Cada segmento debe terminar al final de una oración');
      }
      final joined = seg.join(segments, segments.map((s) => s.text).toList());
      expect(joined.replaceAll(RegExp(r'\s+'), ' ').trim(),
          text.replaceAll(RegExp(r'\s+'), ' ').trim());
    });

    test('las tablas se mantienen en un solo segmento', () {
      final table = List.generate(10, (i) => '| fila $i | $i | ${i * 2} |')
          .join('\n');
      final text = 'Introducción breve.\n\n$table\n\nCierre.';
      final segments = seg.split(text, maxChars: 60);
      final withTable = segments.where((s) => s.text.contains('| fila 0'));
      expect(withTable.single.text, contains('| fila 9'));
    });
  });

  group('ParagraphSplit', () {
    test('reemplaza un párrafo conservando separadores', () {
      final p = ParagraphSplit.of('A uno.\n\nB dos.\nC tres.');
      expect(p.paragraphs, ['A uno.', 'B dos.', 'C tres.']);
      expect(p.replace(1, 'B nuevo.'), 'A uno.\n\nB nuevo.\nC tres.');
    });
  });

  group('LocalTextAnalyzer', () {
    final analyzer =
        LocalTextAnalyzer(domains: EditorialCatalog.domainRegistry());

    test('detecta el dominio de vigilancia y problemas del texto demo', () {
      final r = analyzer.analyze(DemoSamples.publicHealth);
      expect(r.detectedDomainId, 'vigilancia_sp_co');
      final cats = r.issues.map((i) => i.category).toSet();
      expect(cats, containsAll([
        'Lenguaje genérico',
        'Construcción rígida',
        'Abuso de conectores',
        'Inferencia por verificar',
        'Frase extensa',
      ]));
      // Términos técnicos del dominio no cuentan como repetición léxica.
      expect(r.issues.where((i) =>
          i.category == 'Repetición léxica' && i.description.contains('dengue')),
          isEmpty);
    });

    test('texto sin señales: dominio general', () {
      final r = analyzer.analyze('Hoy salimos a caminar por el parque.');
      expect(r.detectedDomainId, 'general');
    });

    test('mezcla de separadores decimales y porcentajes > 100', () {
      final r = analyzer.analyze('Valores 51.99 y 11,5; variación de 150 %.');
      final techn = r.issues.where((i) => i.category == 'Posible problema técnico');
      expect(techn.length, 2);
    });

    test('recomendaciones derivadas con categoría', () {
      final r = analyzer.analyze(DemoSamples.publicHealth);
      final recs = analyzer.recommendationsFrom(r);
      expect(recs, isNotEmpty);
      expect(recs.every((x) => x.suggestion.isNotEmpty), isTrue);
    });
  });

  group('Índice editorial', () {
    test('métricas transparentes acotadas a 0–100', () {
      final idx = const EditorialMetricsCalculator()
          .compute(DemoSamples.publicHealth);
      expect(idx.metrics, hasLength(6));
      for (final m in idx.metrics) {
        expect(m.score, inInclusiveRange(0, 100));
        expect(m.explanation, isNotEmpty);
      }
      expect(idx.score, inInclusiveRange(0, 100));
    });

    test('texto vacío no falla', () {
      final idx = const EditorialMetricsCalculator().compute('');
      expect(idx.metrics, isEmpty);
      expect(idx.score, 0);
    });
  });
}

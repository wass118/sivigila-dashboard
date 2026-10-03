import 'package:flutter_test/flutter_test.dart';
import 'package:humanizador_editorial/models/protected_element.dart';
import 'package:humanizador_editorial/services/audit/protected_content_detector.dart';

import '../helpers/test_helpers.dart';

void main() {
  final detector = ProtectedContentDetector();

  List<String> valuesOf(String text, ProtectedType type) => detector
      .detect(text,
          technicalTerms: publicHealthDomain().protectedTerms,
          eventNames: publicHealthDomain().eventNames)
      .where((e) => e.type == type)
      .map((e) => e.value)
      .toList();

  test('números enteros, decimales y miles', () {
    const t = 'Se registraron 1.248 casos, un valor de 51.99 y otro de 11,5 '
        'en 2026.';
    expect(valuesOf(t, ProtectedType.number),
        containsAll(['1.248', '51.99', '11,5', '2026']));
  });

  test('porcentajes con y sin espacio', () {
    const t = 'Fue de 33,01 % y luego 5% del total.';
    expect(valuesOf(t, ProtectedType.percentage), ['33,01 %', '5%']);
  });

  test('fechas en varios formatos', () {
    const t = 'Entre el 15/03/2026 y el 2026-04-01; también el 9 de '
        'septiembre de 2026 y en marzo de 2025.';
    final dates = valuesOf(t, ProtectedType.date);
    expect(dates, contains('15/03/2026'));
    expect(dates, contains('2026-04-01'));
    expect(dates.any((d) => d.contains('9 de septiembre de 2026')), isTrue);
    expect(dates, contains('marzo de 2025'));
  });

  test('periodos y semanas epidemiológicas', () {
    const t = 'Con corte a la semana epidemiológica 36 de 2026 (SE 36) y el '
        'periodo epidemiológico IX.';
    final periods = valuesOf(t, ProtectedType.epidemiologicalPeriod);
    expect(periods, contains('semana epidemiológica 36 de 2026'));
    expect(periods, contains('SE 36'));
    expect(periods, contains('periodo epidemiológico IX'));
  });

  test('tasas con denominador', () {
    const t = 'La incidencia fue de 351,99 casos por 100.000 habitantes.';
    expect(valuesOf(t, ProtectedType.rate),
        ['351,99 casos por 100.000 habitantes']);
  });

  test('códigos de evento, CIE-10 y alfanuméricos', () {
    const t = 'Dengue (código de evento 210), diagnóstico A90, virus H1N1 y '
        'COVID-19; UPGD 0800100123.';
    final codes = valuesOf(t, ProtectedType.code);
    expect(codes, containsAll(['código de evento 210', 'A90', 'H1N1',
        'COVID-19', '0800100123']));
  });

  test('siglas, citas, referencias y nombres científicos', () {
    const t = 'Según el INS (Pérez et al., 2021) y la Ley 1751 de 2015, el '
        'vector Aedes aegypti persiste [3]. Ver https://ins.gov.co/x.';
    final all = detector.detect(t);
    String? valueOf(ProtectedType ty) =>
        all.where((e) => e.type == ty).map((e) => e.value).firstOrNull;
    expect(valueOf(ProtectedType.acronym), 'INS');
    expect(all.where((e) => e.type == ProtectedType.citation).map((e) => e.value),
        containsAll(['(Pérez et al., 2021)', '[3]']));
    expect(all.where((e) => e.type == ProtectedType.reference).map((e) => e.value),
        containsAll(['Ley 1751 de 2015', 'https://ins.gov.co/x']));
    expect(valueOf(ProtectedType.scientificName), 'Aedes aegypti');
  });

  test('instituciones y términos del dominio', () {
    const t = 'El Instituto Nacional de Salud reportó un brote de dengue '
        'grave e inició la investigación epidemiológica de campo.';
    expect(valuesOf(t, ProtectedType.institution),
        ['Instituto Nacional de Salud']);
    expect(valuesOf(t, ProtectedType.eventName), ['dengue grave']);
    expect(valuesOf(t, ProtectedType.technicalTerm),
        containsAll(['brote', 'investigación epidemiológica de campo']));
  });

  test('los elementos no se solapan y conservan posiciones', () {
    const t = 'Se notificaron 412 (33,01 %) casos el 2 de mayo de 2026.';
    final els = detector.detect(t);
    for (var i = 1; i < els.length; i++) {
      expect(els[i].start, greaterThanOrEqualTo(els[i - 1].end));
    }
    for (final e in els) {
      expect(t.substring(e.start, e.end), e.value);
    }
  });

  test('numericValue distingue formato de valor', () {
    expect(ProtectedContentDetector.numericValue('100.000'), 100000);
    expect(ProtectedContentDetector.numericValue('51,99'), 51.99);
    expect(ProtectedContentDetector.numericValue('51.99'), 51.99);
    expect(ProtectedContentDetector.numericValue('1,248.5'), 1248.5);
  });

  test('la huella separa contenedores y átomos numéricos', () {
    const t = 'El 15/03/2026 hubo 37 casos (código 220) y 11,5 %.';
    final f = detector.fingerprint(t);
    expect(f.of(ProtectedType.date), ['15/03/2026']);
    expect(f.of(ProtectedType.code), ['código 220']);
    expect(f.of(ProtectedType.percentage), ['11,5%']);
    expect(f.of(ProtectedType.number), ['37']);
  });
}

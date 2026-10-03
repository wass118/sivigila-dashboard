import 'package:flutter_test/flutter_test.dart';
import 'package:humanizador_editorial/models/audit_report.dart';
import 'package:humanizador_editorial/models/fidelity_warning.dart';
import 'package:humanizador_editorial/services/audit/fidelity_auditor.dart';

import '../helpers/test_helpers.dart';

void main() {
  final auditor = FidelityAuditor();
  final terms = publicHealthDomain().protectedTerms;
  final events = publicHealthDomain().eventNames;

  AuditReport run(String a, String b,
          {List<FidelityWarning> model = const []}) =>
      auditor.audit(
          original: a,
          revised: b,
          modelWarnings: model,
          technicalTerms: terms,
          eventNames: events);

  FidelityWarning? find(AuditReport r, String original) =>
      r.warnings.where((w) => w.originalValue == original).firstOrNull;

  test('texto idéntico: sin cambios técnicos', () {
    final r = run('La tasa fue 51,99 en 2026.', 'La tasa fue 51,99 en 2026.');
    expect(r.status, AuditStatus.noTechnicalChanges);
    expect(r.warnings, isEmpty);
  });

  test('cambio editorial sin tocar datos: cambios editoriales', () {
    final r = run(
        'Es importante destacar que se notificaron 37 casos en 2026.',
        'Se notificaron 37 casos en 2026.');
    expect(r.status, AuditStatus.editorialChanges);
    expect(r.diff.stats.wordsDeleted, greaterThan(0));
  });

  test('51.99 → 52: alerta alta con valor original y encontrado', () {
    final r = run('El indicador fue 51.99 puntos.', 'El indicador fue 52 puntos.');
    expect(r.status, AuditStatus.possibleTechnicalChange);
    final w = find(r, '51.99')!;
    expect(w.severity, WarningSeverity.high);
    expect(w.foundValue, '52');
  });

  test('2026 → 2025 y 11,5 → 15', () {
    final r = run('En 2026 aumentó 11,5 veces.', 'En 2025 aumentó 15 veces.');
    expect(find(r, '2026')?.foundValue, '2025');
    expect(find(r, '11,5')?.foundValue, '15');
    expect(r.status, AuditStatus.possibleTechnicalChange);
  });

  test('100.000 habitantes → 10.000 habitantes', () {
    final r = run('Incidencia de 351,99 por 100.000 habitantes.',
        'Incidencia de 351,99 por 10.000 habitantes.');
    expect(find(r, '100.000')?.foundValue, '10.000');
  });

  test('porcentaje y fecha alterados', () {
    final r = run('Fue 33,01 % el 9 de septiembre de 2026.',
        'Fue 33 % el 19 de septiembre de 2026.');
    expect(find(r, '33,01%')?.foundValue, '33%');
    expect(r.warnings.any((w) => w.category == 'Fecha'), isTrue);
  });

  test('código de evento alterado', () {
    final r = run('Dengue (código de evento 210).', 'Dengue (código de evento 220).');
    expect(find(r, 'código de evento 210')?.severity, WarningSeverity.high);
  });

  test('cambio solo de formato numérico: severidad media', () {
    final r = run('Se reportaron 1.248 casos.', 'Se reportaron 1248 casos.');
    final w = find(r, '1.248')!;
    expect(w.severity, WarningSeverity.medium);
    expect(r.status, AuditStatus.humanReviewRecommended);
  });

  test('cifra nueva no presente en el original: alerta alta', () {
    final r = run('Se notificaron casos.', 'Se notificaron 15 casos.');
    final w = r.warnings.firstWhere((w) => w.foundValue == '15');
    expect(w.severity, WarningSeverity.high);
    expect(w.originalValue, isNull);
  });

  test('cambio de unidad con la misma cifra', () {
    final r = run('Se administraron 5 mg.', 'Se administraron 5 g.');
    expect(r.warnings.any((w) => w.category == 'Unidad'), isTrue);
    expect(r.status, AuditStatus.possibleTechnicalChange);
  });

  test('cambio de certeza y negación: revisión humana', () {
    final r = run('Se registraron 2 casos probables. No hubo brote.',
        'Se registraron 2 casos confirmados. Hubo brote.');
    expect(r.warnings.any((w) => w.category == 'Grado de certeza'), isTrue);
    expect(r.warnings.any((w) => w.category == 'Negación'), isTrue);
  });

  test('sigla eliminada: revisión humana', () {
    final r = run('Se notificó al SIVIGILA según el protocolo.',
        'Se notificó según el protocolo.');
    expect(r.warnings.any((w) => w.originalValue == 'SIVIGILA'), isTrue);
    expect(r.status, AuditStatus.humanReviewRecommended);
  });

  test('las alertas del modelo se conservan y se marcan por origen', () {
    final r = run('Texto 1.', 'Texto 1.', model: const [
      FidelityWarning(
          category: 'Revisión',
          message: 'dudoso',
          severity: WarningSeverity.medium,
          origin: WarningOrigin.model),
    ]);
    expect(r.warnings.single.origin, WarningOrigin.model);
    expect(r.status, AuditStatus.humanReviewRecommended);
  });

  test('sin versión generada (solo recomendaciones)', () {
    final r = auditor.audit(original: 'Texto 1.', revised: null);
    expect(r.status, AuditStatus.noTechnicalChanges);
    expect(r.notes, isNotEmpty);
    expect(r.indexBefore, isNotNull);
  });

  test('las alertas se ordenan por severidad', () {
    final r = run('Valor 10 en 2026. Sin brote. SIVIGILA.',
        'Valor 11 en 2026. Con brote. SIVIGILA.');
    for (var i = 1; i < r.warnings.length; i++) {
      expect(r.warnings[i].severity.index,
          greaterThanOrEqualTo(r.warnings[i - 1].severity.index));
    }
  });
}

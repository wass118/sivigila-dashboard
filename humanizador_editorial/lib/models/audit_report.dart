import 'editorial_index.dart';
import 'fidelity_warning.dart';
import 'text_diff.dart';

/// Estado global de la auditoría. Apoyo a la revisión humana, no garantía
/// de equivalencia semántica.
enum AuditStatus {
  noTechnicalChanges(
    'Sin cambios técnicos detectados',
    'La comparación automática no encontró diferencias en cifras, fechas, '
        'códigos ni términos protegidos.',
  ),
  editorialChanges(
    'Cambios editoriales detectados',
    'Hay cambios de redacción. No se detectaron alteraciones en los '
        'elementos técnicos verificados.',
  ),
  humanReviewRecommended(
    'Revisión humana recomendada',
    'Hay diferencias que pueden ser editoriales pero conviene verificar '
        '(términos, grado de certeza, longitud o alertas del modelo).',
  ),
  possibleTechnicalChange(
    'Posible modificación técnica',
    'Se detectaron diferencias en cifras, fechas, códigos, unidades o '
        'citas. Revise cada alerta antes de usar el texto.',
  );

  const AuditStatus(this.label, this.explanation);
  final String label;
  final String explanation;
}

/// Informe de la fase 4 (auditoría de fidelidad).
class AuditReport {
  const AuditReport({
    required this.status,
    required this.warnings,
    required this.diff,
    this.indexBefore,
    this.indexAfter,
    this.checkedEntities = 0,
    this.notes = const [],
  });

  final AuditStatus status;
  final List<FidelityWarning> warnings;
  final TextDiffResult diff;
  final EditorialIndex? indexBefore;
  final EditorialIndex? indexAfter;

  /// Número de entidades del original verificadas.
  final int checkedEntities;
  final List<String> notes;

  static const String disclaimer = 'La auditoría es un mecanismo automático '
      'de apoyo. No garantiza equivalencia semántica: la validación final '
      'corresponde a una persona.';

  int count(WarningSeverity severity) =>
      warnings.where((w) => w.severity == severity).length;

  String toPlainText() {
    final b = StringBuffer()
      ..writeln('AUDITORÍA DE FIDELIDAD: ${status.label}')
      ..writeln(status.explanation)
      ..writeln('Entidades verificadas: $checkedEntities');
    for (final w in warnings) {
      b.write('- [${w.severity.label}] ${w.category}: ${w.message}');
      if (w.originalValue != null) b.write(' | Original: ${w.originalValue}');
      if (w.foundValue != null) b.write(' | Encontrado: ${w.foundValue}');
      b.writeln(w.origin == WarningOrigin.model ? ' (reportado por el modelo)' : '');
    }
    for (final n in notes) {
      b.writeln('Nota: $n');
    }
    b.writeln(disclaimer);
    return b.toString();
  }
}

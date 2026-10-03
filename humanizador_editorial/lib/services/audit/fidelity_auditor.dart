import '../../core/utils/text_utils.dart';
import '../../models/audit_report.dart';
import '../../models/fidelity_warning.dart';
import '../../models/protected_element.dart';
import '../../models/text_diff.dart';
import '../analysis/editorial_metrics.dart';
import 'protected_content_detector.dart';
import 'text_differ.dart';

/// Fase 4: auditoría de fidelidad determinista.
///
/// Compara entidades críticas antes y después, marca valores ausentes,
/// modificados o nuevos, revisa marcadores de certeza, negación y tendencia,
/// y combina las alertas del modelo. Nunca modifica el texto: solo informa.
class FidelityAuditor {
  FidelityAuditor({
    ProtectedContentDetector? detector,
    TextDiffer? differ,
    EditorialMetricsCalculator? metrics,
  })  : detector = detector ?? ProtectedContentDetector(),
        differ = differ ?? const TextDiffer(),
        metrics = metrics ?? const EditorialMetricsCalculator();

  final ProtectedContentDetector detector;
  final TextDiffer differ;
  final EditorialMetricsCalculator metrics;

  /// Tipos cuya alteración es de prioridad alta.
  static const List<ProtectedType> criticalTypes = [
    ProtectedType.number,
    ProtectedType.percentage,
    ProtectedType.date,
    ProtectedType.epidemiologicalPeriod,
    ProtectedType.code,
    ProtectedType.citation,
    ProtectedType.reference,
  ];

  /// Tipos léxicos: su desaparición total requiere revisión.
  static const List<ProtectedType> lexicalTypes = [
    ProtectedType.acronym,
    ProtectedType.institution,
    ProtectedType.eventName,
    ProtectedType.scientificName,
    ProtectedType.technicalTerm,
    ProtectedType.properName,
  ];

  /// Grupos de marcadores semánticos cuya variación se señala.
  static const Map<String, List<String>> semanticMarkers = {
    'Grado de certeza': [
      'confirmado', 'confirmada', 'confirmados', 'confirmadas', 'probable',
      'probables', 'sospechoso', 'sospechosa', 'sospechosos', 'sospechosas',
      'descartado', 'descartada', 'descartados', 'descartadas', 'posible',
      'posibles', 'posiblemente', 'probablemente', 'presunto', 'presunta',
      'hipótesis', 'podría', 'podrían', 'sugiere', 'sugieren',
    ],
    'Negación': ['no', 'ni', 'sin', 'nunca', 'ningún', 'ninguna', 'tampoco',
        'nadie', 'nada'],
    'Tendencia': ['aumento', 'aumentó', 'incremento', 'incrementó', 'ascenso',
        'disminución', 'disminuyó', 'descenso', 'reducción', 'redujo',
        'estable', 'estabilidad', 'mayor', 'menor'],
  };

  AuditReport audit({
    required String original,
    required String? revised,
    List<FidelityWarning> modelWarnings = const [],
    List<String> technicalTerms = const [],
    List<String> eventNames = const [],
  }) {
    final indexBefore = metrics.compute(original);
    if (revised == null || revised.trim().isEmpty) {
      return AuditReport(
        status: modelWarnings.isEmpty
            ? AuditStatus.noTechnicalChanges
            : AuditStatus.humanReviewRecommended,
        warnings: modelWarnings,
        diff: TextDiffResult.empty,
        indexBefore: indexBefore,
        notes: const ['No se generó una nueva versión (modo solo '
            'recomendaciones); no hay texto que comparar.'],
      );
    }

    final before = detector.fingerprint(original,
        technicalTerms: technicalTerms, eventNames: eventNames);
    final after = detector.fingerprint(revised,
        technicalTerms: technicalTerms, eventNames: eventNames);

    final warnings = <FidelityWarning>[
      ..._compareCritical(before, after),
      ..._compareMeasurements(before, after),
      ..._compareLexical(before, after),
      ..._compareMarkers(original, revised),
      ..._compareLength(original, revised),
    ];
    // Alertas del modelo: se muestran todas, marcadas por origen.
    warnings.addAll(modelWarnings.map((w) => FidelityWarning(
          category: w.category,
          message: w.message,
          severity: w.severity,
          originalValue: w.originalValue,
          foundValue: w.foundValue,
          origin: WarningOrigin.model,
        )));

    final diff = differ.diff(original, revised);
    final notes = <String>[];
    if (diff.stats.paragraphsAdded + diff.stats.paragraphsRemoved > 0) {
      notes.add('Cambió la estructura de párrafos: '
          '${diff.stats.paragraphsAdded} añadidos, '
          '${diff.stats.paragraphsRemoved} eliminados.');
    }

    return AuditReport(
      status: _status(warnings, diff.stats),
      warnings: _sorted(warnings),
      diff: diff,
      indexBefore: indexBefore,
      indexAfter: metrics.compute(revised),
      checkedEntities: before.total,
      notes: notes,
    );
  }

  AuditStatus _status(List<FidelityWarning> warnings, DiffStats stats) {
    if (warnings.any((w) => w.severity == WarningSeverity.high)) {
      return AuditStatus.possibleTechnicalChange;
    }
    if (warnings.any((w) => w.severity == WarningSeverity.medium)) {
      return AuditStatus.humanReviewRecommended;
    }
    return stats.hasChanges
        ? AuditStatus.editorialChanges
        : AuditStatus.noTechnicalChanges;
  }

  List<FidelityWarning> _sorted(List<FidelityWarning> list) =>
      List.of(list)..sort((a, b) => a.severity.index.compareTo(b.severity.index));

  // ---------------------------------------------------------------------

  List<FidelityWarning> _compareCritical(
      EntityFingerprint before, EntityFingerprint after) {
    final warnings = <FidelityWarning>[];
    for (final type in criticalTypes) {
      final diff = _multisetDiff(before.of(type), after.of(type));
      final missing = List.of(diff.missing);
      final added = List.of(diff.added);

      // Emparejar ausentes con nuevos del mismo tipo: "modificado".
      while (missing.isNotEmpty && added.isNotEmpty) {
        final o = missing.removeAt(0);
        final f = added.removeAt(0);
        final ov = ProtectedContentDetector.numericValue(o);
        final fv = ProtectedContentDetector.numericValue(f);
        final sameValue = (type == ProtectedType.number ||
                type == ProtectedType.percentage) &&
            ov != null &&
            fv != null &&
            ov == fv;
        warnings.add(FidelityWarning(
          category: type.label,
          severity: sameValue ? WarningSeverity.medium : WarningSeverity.high,
          originalValue: o,
          foundValue: f,
          message: sameValue
              ? 'Cambió el formato del valor (separadores o espacios).'
              : 'Posible modificación del valor.',
        ));
      }
      for (final o in missing) {
        final stillPresent = after.of(type).contains(o);
        warnings.add(FidelityWarning(
          category: type.label,
          severity:
              stillPresent ? WarningSeverity.medium : WarningSeverity.high,
          originalValue: o,
          message: stillPresent
              ? 'Aparece menos veces que en el original; verifique que no '
                  'se haya omitido un dato.'
              : 'No aparece en el texto final.',
        ));
      }
      for (final f in added) {
        final existed = before.of(type).contains(f);
        warnings.add(FidelityWarning(
          category: type.label,
          severity: existed ? WarningSeverity.medium : WarningSeverity.high,
          foundValue: f,
          message: existed
              ? 'Aparece más veces que en el original.'
              : 'Valor nuevo que no está en el original.',
        ));
      }
    }
    return warnings;
  }

  /// Cambios de unidad cuando la cifra se conserva (p. ej., 5 mg → 5 g).
  List<FidelityWarning> _compareMeasurements(
      EntityFingerprint before, EntityFingerprint after) {
    final warnings = <FidelityWarning>[];
    final diff = _multisetDiff(
        before.of(ProtectedType.measurement), after.of(ProtectedType.measurement));
    final afterNumbers = {
      ...after.of(ProtectedType.number),
      ...after.of(ProtectedType.percentage),
    };
    final numberPattern = RegExp(ProtectedContentDetector.num);
    for (final o in diff.missing) {
      final numberInIt = numberPattern.firstMatch(o)?.group(0);
      // Si la cifra desapareció, ya hay alerta numérica; evitar duplicados.
      if (numberInIt == null || !afterNumbers.contains(numberInIt)) continue;
      final candidate = diff.added.firstWhere(
          (f) => numberPattern.firstMatch(f)?.group(0) == numberInIt,
          orElse: () => '');
      warnings.add(FidelityWarning(
        category: 'Unidad',
        severity: WarningSeverity.high,
        originalValue: o,
        foundValue: candidate.isEmpty ? null : candidate,
        message: 'La cifra se conserva, pero la unidad que la acompañaba '
            'cambió o desapareció.',
      ));
    }
    return warnings;
  }

  List<FidelityWarning> _compareLexical(
      EntityFingerprint before, EntityFingerprint after) {
    final warnings = <FidelityWarning>[];
    for (final type in lexicalTypes) {
      final beforeSet = before.of(type).toSet();
      final afterSet = after.of(type).toSet();
      for (final o in beforeSet.difference(afterSet)) {
        warnings.add(FidelityWarning(
          category: type.label,
          severity: type == ProtectedType.properName
              ? WarningSeverity.low
              : WarningSeverity.medium,
          originalValue: o,
          message: 'Ya no aparece en el texto final.',
        ));
      }
      if (type == ProtectedType.acronym ||
          type == ProtectedType.institution ||
          type == ProtectedType.scientificName) {
        for (final f in afterSet.difference(beforeSet)) {
          warnings.add(FidelityWarning(
            category: type.label,
            severity: WarningSeverity.medium,
            foundValue: f,
            message: 'Término nuevo: verifique que no agregue información '
                'ausente en el original.',
          ));
        }
      }
    }
    return warnings;
  }

  List<FidelityWarning> _compareMarkers(String original, String revised) {
    final warnings = <FidelityWarning>[];
    final o = original.toLowerCase();
    final r = revised.toLowerCase();
    semanticMarkers.forEach((group, words) {
      for (final w in words) {
        final pattern = RegExp('(?<![\\p{L}])${RegExp.escape(w)}(?![\\p{L}])',
            unicode: true);
        final co = pattern.allMatches(o).length;
        final cr = pattern.allMatches(r).length;
        if (co == cr) continue;
        // En "Tendencia", "mayor/menor" son frecuentes; solo se señalan si
        // desaparecen o aparecen por completo.
        if (group == 'Tendencia' && co > 0 && cr > 0) continue;
        warnings.add(FidelityWarning(
          category: group,
          severity: WarningSeverity.medium,
          originalValue: '"$w" × $co',
          foundValue: '"$w" × $cr',
          message: co > cr
              ? 'Aparece menos veces; verifique que no cambió el sentido de '
                  'la afirmación.'
              : 'Aparece más veces; verifique que no se añadió una '
                  'afirmación.',
        ));
      }
    });
    return warnings;
  }

  List<FidelityWarning> _compareLength(String original, String revised) {
    final wo = TextUtils.countWords(original);
    final wr = TextUtils.countWords(revised);
    if (wo < 20) return const [];
    final ratio = wr / wo;
    if (ratio > 1.3) {
      return [
        FidelityWarning(
          category: 'Longitud',
          severity: WarningSeverity.medium,
          originalValue: '$wo palabras',
          foundValue: '$wr palabras',
          message: 'La versión es ${((ratio - 1) * 100).toStringAsFixed(0)} % '
              'más larga: posible adición de contenido.',
        ),
      ];
    }
    if (ratio < 0.6) {
      return [
        FidelityWarning(
          category: 'Longitud',
          severity: WarningSeverity.medium,
          originalValue: '$wo palabras',
          foundValue: '$wr palabras',
          message: 'La versión es ${((1 - ratio) * 100).toStringAsFixed(0)} % '
              'más corta: posible omisión de contenido.',
        ),
      ];
    }
    return const [];
  }

  static ({List<String> missing, List<String> added}) _multisetDiff(
      List<String> before, List<String> after) {
    final remaining = <String, int>{};
    for (final v in after) {
      remaining[v] = (remaining[v] ?? 0) + 1;
    }
    final missing = <String>[];
    for (final v in before) {
      final c = remaining[v] ?? 0;
      if (c > 0) {
        remaining[v] = c - 1;
      } else {
        missing.add(v);
      }
    }
    final added = <String>[];
    for (final v in after) {
      // Conservar orden de aparición de los sobrantes.
      final c = remaining[v] ?? 0;
      if (c > 0) {
        added.add(v);
        remaining[v] = c - 1;
      }
    }
    return (missing: missing, added: added);
  }
}

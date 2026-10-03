import '../../core/utils/text_utils.dart';
import '../../models/domain_profile.dart';
import '../../models/pipeline_models.dart';
import '../../models/recommendation.dart';
import '../../models/text_analysis.dart';
import 'editorial_metrics.dart';

/// Analizador local determinista. Funciona sin conexión y complementa el
/// diagnóstico del modelo con hallazgos verificables (cada hallazgo cita el
/// fragmento que lo origina).
class LocalTextAnalyzer {
  LocalTextAnalyzer({
    required this.domains,
    this.metrics = const EditorialMetricsCalculator(),
  });

  final DomainRegistry domains;
  final EditorialMetricsCalculator metrics;

  static const int longSentenceWords = 35;

  LocalAnalysisReport analyze(String text) {
    final folded = TextUtils.fold(text);
    final (domainId, confidence) = detectDomain(folded);
    final issues = <EditorialIssue>[
      ..._longSentences(text),
      ..._phraseIssues(text, EditorialLexicon.genericPhrases,
          'Lenguaje genérico', 'Fórmula genérica que no aporta contenido.'),
      ..._phraseIssues(text, EditorialLexicon.rigidConstructions,
          'Construcción rígida', 'Construcción burocrática o perifrástica.'),
      ..._phraseIssues(text, EditorialLexicon.redundancies, 'Redundancia',
          'Expresión redundante.'),
      ..._connectorAbuse(text),
      ..._lexicalRepetition(text, domains.byId(domainId)),
      ..._nominalizations(text),
      ..._phraseIssues(text, EditorialLexicon.ambiguousReferences,
          'Ambigüedad', 'Referencia anafórica que puede resultar ambigua.',
          maxPerPhrase: 1),
      ..._terminology(text),
      ..._technicalChecks(text, domainId),
    ];
    return LocalAnalysisReport(
      detectedDomainId: domainId,
      domainConfidence: confidence,
      formality: _formality(text),
      purpose: _purpose(folded),
      estimatedAudienceId: _audience(domainId, folded),
      issues: issues,
      index: metrics.compute(text),
    );
  }

  /// Detección automática de dominio por palabras clave (sin tildes).
  (String, double) detectDomain(String foldedText) {
    var bestId = DomainRegistry.generalId;
    var bestScore = 0;
    var total = 0;
    for (final profile in domains.all) {
      var score = 0;
      for (final kw in profile.keywords) {
        score += EditorialMetricsCalculator.phraseRegex(kw)
            .allMatches(foldedText)
            .length;
      }
      total += score;
      if (score > bestScore) {
        bestScore = score;
        bestId = profile.id;
      }
    }
    if (bestScore < 2) return (DomainRegistry.generalId, 0);
    return (bestId, total == 0 ? 0 : bestScore / total);
  }

  /// Convierte el informe local en un [TextAnalysis] legible.
  TextAnalysis toTextAnalysis(LocalAnalysisReport report,
      {required String audienceLabel, bool isDemo = false}) {
    final domain = domains.byId(report.detectedDomainId);
    final idx = report.index;
    return TextAnalysis(
      detectedDomain: domain.label,
      detectedAudience: audienceLabel,
      detectedTone: report.formality == 'Alta'
          ? 'Formal'
          : (report.formality == 'Baja' ? 'Informal' : 'Neutro'),
      formality: report.formality,
      purpose: report.purpose,
      technicalLevel: _technicalLevel(report),
      problems: report.issues,
      observations: [
        'Índice editorial: ${idx.score.toStringAsFixed(0)}/100 '
            '(${idx.wordCount} palabras, ${idx.sentenceCount} oraciones).',
        if (report.detectedDomainId != DomainRegistry.generalId)
          'Dominio estimado por palabras clave (confianza '
              '${(report.domainConfidence * 100).toStringAsFixed(0)} %).',
      ],
      isDemo: isDemo,
    );
  }

  /// Recomendaciones derivadas de los hallazgos locales.
  List<Recommendation> recommendationsFrom(LocalAnalysisReport report) {
    return report.issues.map((issue) {
      final (category, suggestion) = switch (issue.category) {
        'Frase extensa' => (
            RecommendationCategory.structure,
            'Divida la oración en dos o tres unidades con una idea principal '
                'cada una, sin alterar datos.'
          ),
        'Lenguaje genérico' => (
            RecommendationCategory.clarity,
            'Elimine la fórmula y enuncie directamente la información.'
          ),
        'Construcción rígida' => (
            RecommendationCategory.clarity,
            'Use el verbo pleno (p. ej., "realizar" en lugar de "llevar a '
                'cabo"; "para" en lugar de "con el fin de").'
          ),
        'Redundancia' => (
            RecommendationCategory.redundancy,
            'Suprima el elemento redundante.'
          ),
        'Abuso de conectores' => (
            RecommendationCategory.cohesion,
            'Varíe o suprima conectores que no expresen una relación lógica.'
          ),
        'Repetición léxica' => (
            RecommendationCategory.redundancy,
            'Use referencias o reestructure; conserve el término si es '
                'técnico y no tiene sinónimo exacto.'
          ),
        'Exceso de nominalizaciones' => (
            RecommendationCategory.clarity,
            'Convierta algunos sustantivos abstractos en verbos.'
          ),
        'Ambigüedad' => (
            RecommendationCategory.precision,
            'Haga explícito el referente.'
          ),
        'Inconsistencia terminológica' => (
            RecommendationCategory.terminology,
            'Unifique la forma elegida en todo el documento.'
          ),
        _ => (
            RecommendationCategory.technicalAccuracy,
            'Verifique el dato o el sustento con la fuente. La herramienta no '
                'corrige contenido técnico.'
          ),
      };
      return Recommendation(
        category: category,
        problem: issue.description,
        excerpt: issue.excerpt,
        suggestion: suggestion,
      );
    }).toList();
  }

  // ---------------------------------------------------------------------

  List<EditorialIssue> _longSentences(String text) {
    final result = <EditorialIssue>[];
    for (final s in TextUtils.sentences(text)) {
      final n = TextUtils.countWords(s);
      if (n > longSentenceWords) {
        result.add(EditorialIssue(
          category: 'Frase extensa',
          description: 'Oración de $n palabras (referencia: ≤ '
              '$longSentenceWords).',
          excerpt: TextUtils.excerpt(s, max: 120),
        ));
      }
    }
    return result;
  }

  List<EditorialIssue> _phraseIssues(
      String text, List<String> phrases, String category, String description,
      {int maxPerPhrase = 2}) {
    final folded = TextUtils.fold(text);
    final result = <EditorialIssue>[];
    for (final phrase in phrases) {
      final matches = EditorialMetricsCalculator.phraseRegex(phrase)
          .allMatches(folded)
          .take(maxPerPhrase);
      for (final m in matches) {
        // `fold` conserva longitudes, así que los índices son válidos.
        result.add(EditorialIssue(
          category: category,
          description: '$description ("${_safeSub(text, m.start, m.end)}")',
          excerpt: _contextAround(text, m.start, m.end),
        ));
      }
    }
    return result;
  }

  List<EditorialIssue> _connectorAbuse(String text) {
    final folded = TextUtils.fold(text);
    final result = <EditorialIssue>[];
    for (final c in EditorialLexicon.connectors) {
      final count =
          EditorialMetricsCalculator.phraseRegex(c).allMatches(folded).length;
      if (count >= 2) {
        result.add(EditorialIssue(
          category: 'Abuso de conectores',
          description: 'El conector "$c" aparece $count veces.',
        ));
      }
    }
    final words = TextUtils.countWords(text);
    final total =
        EditorialMetricsCalculator.countPhrases(folded, EditorialLexicon.connectors);
    if (words > 0 && total * 100 / words > 5) {
      result.add(EditorialIssue(
        category: 'Abuso de conectores',
        description: 'Densidad de conectores elevada: '
            '${(total * 100 / words).toStringAsFixed(1)} por cada 100 '
            'palabras.',
      ));
    }
    return result;
  }

  /// Los términos técnicos del dominio no se señalan: repetirlos suele ser
  /// necesario para la precisión.
  List<EditorialIssue> _lexicalRepetition(String text, DomainProfile domain) {
    final technical = {
      for (final t in [...domain.protectedTerms, ...domain.eventNames])
        ...TextUtils.words(t.toLowerCase()),
    };
    final repeated =
        EditorialMetricsCalculator.repeatedContentWords(TextUtils.words(text))
            .where((e) => !technical.contains(e.key));
    return repeated.take(5).map((e) => EditorialIssue(
          category: 'Repetición léxica',
          description: '"${e.key}" aparece ${e.value} veces.',
        )).toList();
  }

  List<EditorialIssue> _nominalizations(String text) {
    final words = TextUtils.words(text);
    if (words.length < 30) return const [];
    final noms = words
        .where((w) => EditorialLexicon.nominalization.hasMatch(w.toLowerCase()))
        .length;
    final density = noms * 100 / words.length;
    if (density <= 10) return const [];
    return [
      EditorialIssue(
        category: 'Exceso de nominalizaciones',
        description: '${density.toStringAsFixed(1)} nominalizaciones por cada '
            '100 palabras (referencia: ≤ 8).',
      ),
    ];
  }

  List<EditorialIssue> _terminology(String text) {
    final result = <EditorialIssue>[];
    // Variantes ortográficas: se compara sin plegar tildes.
    for (final group in EditorialLexicon.terminologyVariants) {
      final used = group
          .where((v) => RegExp('(?<![\\p{L}])${RegExp.escape(v)}s?(?![\\p{L}])',
                  unicode: true, caseSensitive: false)
              .hasMatch(text))
          .toList();
      if (used.length >= 2) {
        result.add(EditorialIssue(
          category: 'Inconsistencia terminológica',
          description: 'Se alternan formas para el mismo concepto: '
              '${used.map((u) => '"$u"').join(', ')}.',
        ));
      }
    }
    return result;
  }

  List<EditorialIssue> _technicalChecks(String text, String domainId) {
    final result = <EditorialIssue>[];
    final usesDotDecimal =
        RegExp(r'(?<![\d.,])\d+\.\d{1,2}(?![\d])').hasMatch(text);
    final usesCommaDecimal =
        RegExp(r'(?<![\d.,])\d+,\d{1,2}(?![\d])').hasMatch(text);
    if (usesDotDecimal && usesCommaDecimal) {
      result.add(const EditorialIssue(
        category: 'Posible problema técnico',
        description: 'Se mezclan separadores decimales (punto y coma). '
            'Verifique la convención; la herramienta no los modifica.',
      ));
    }
    for (final m in RegExp(r'(\d+(?:[.,]\d+)?)\s?%').allMatches(text)) {
      final v = double.tryParse(m.group(1)!.replaceAll(',', '.'));
      if (v != null && v > 100) {
        result.add(EditorialIssue(
          category: 'Posible problema técnico',
          description: 'Porcentaje mayor que 100 %. Confirme si corresponde '
              'a una variación relativa.',
          excerpt: _contextAround(text, m.start, m.end),
        ));
      }
    }
    final folded = TextUtils.fold(text);
    for (final phrase in EditorialLexicon.causalInferences) {
      for (final m in EditorialMetricsCalculator.phraseRegex(phrase)
          .allMatches(folded)
          .take(2)) {
        result.add(EditorialIssue(
          category: 'Inferencia por verificar',
          description: 'Afirmación causal o concluyente ("${_safeSub(text, m.start, m.end)}"). '
              '${domainId == 'vigilancia_sp_co' ? 'En vigilancia, diferencie dato observado, interpretación e hipótesis; ' : ''}'
              'verifique que el texto presente el sustento.',
          excerpt: _contextAround(text, m.start, m.end),
        ));
      }
    }
    return result;
  }

  String _formality(String text) {
    final f = TextUtils.fold(text);
    const informal = ['vale', 'super', 'chevere', 'ok', 'bacano', 'pues',
        'osea', 'o sea', 'creo que', 'me parece'];
    final informalHits = EditorialMetricsCalculator.countPhrases(f, informal) +
        '!'.allMatches(text).length;
    final impersonal = RegExp(r'(?<![\p{L}])se\s+\p{L}+(?:ó|aron|a|an)(?![\p{L}])',
            unicode: true)
        .allMatches(f)
        .length;
    if (informalHits >= 3) return 'Baja';
    if (impersonal >= 2 || informalHits == 0) return 'Alta';
    return 'Media';
  }

  String _purpose(String folded) {
    bool has(String p) =>
        EditorialMetricsCalculator.phraseRegex(p).hasMatch(folded);
    if (has('sitrep') || has('informe de situacion') || has('boletin')) {
      return 'Informe de situación';
    }
    if (has('por medio de la presente') || has('solicito') ||
        has('atentamente')) {
      return 'Comunicación oficial';
    }
    if (has('metodologia') || has('resultados') || has('hipotesis')) {
      return 'Documento académico o de investigación';
    }
    if (has('se recomienda') || has('recomendaciones')) {
      return 'Informe con recomendaciones';
    }
    return 'Informativo';
  }

  String _audience(String domainId, String folded) => switch (domainId) {
        'vigilancia_sp_co' || 'clinico' => 'tecnica',
        'academico' => 'academica',
        'administrativo' => 'institucional',
        'juridico' => 'profesional',
        'empresarial' => 'directiva',
        'divulgativo' => 'comunitaria',
        _ => 'general',
      };

  String _technicalLevel(LocalAnalysisReport r) {
    if (r.detectedDomainId == DomainRegistry.generalId ||
        r.detectedDomainId == 'divulgativo') {
      return 'medio';
    }
    return 'alto';
  }

  /// `fold` conserva la longitud en español; se acota por seguridad.
  static String _safeSub(String text, int start, int end) =>
      text.substring(start.clamp(0, text.length), end.clamp(0, text.length));

  static String _contextAround(String text, int start, int end) {
    final from = (start - 50).clamp(0, text.length);
    final to = (end + 50).clamp(0, text.length);
    final prefix = from > 0 ? '…' : '';
    final suffix = to < text.length ? '…' : '';
    return '$prefix${TextUtils.normalizeSpaces(text.substring(from, to))}$suffix';
  }
}

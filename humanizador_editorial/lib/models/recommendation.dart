import '../core/utils/text_utils.dart';

/// Categorías mínimas del módulo de recomendaciones de redacción.
enum RecommendationCategory {
  clarity('Claridad'),
  precision('Precisión'),
  cohesion('Cohesión'),
  structure('Estructura'),
  redundancy('Redundancia'),
  tone('Tono'),
  terminology('Consistencia terminológica'),
  technicalAccuracy('Precisión técnica');

  const RecommendationCategory(this.label);
  final String label;

  static RecommendationCategory fromLabel(String? raw) {
    final f = TextUtils.fold(raw ?? '').replaceAll('_', ' ').trim();
    for (final c in RecommendationCategory.values) {
      if (c.name.toLowerCase() == f || TextUtils.fold(c.label) == f) return c;
    }
    if (f.contains('tecnic')) return RecommendationCategory.technicalAccuracy;
    if (f.contains('termin')) return RecommendationCategory.terminology;
    if (f.contains('redund') || f.contains('repet')) {
      return RecommendationCategory.redundancy;
    }
    if (f.contains('cohes') || f.contains('conector')) {
      return RecommendationCategory.cohesion;
    }
    if (f.contains('estruct') || f.contains('longitud')) {
      return RecommendationCategory.structure;
    }
    if (f.contains('tono') || f.contains('registro')) {
      return RecommendationCategory.tone;
    }
    if (f.contains('precis')) return RecommendationCategory.precision;
    return RecommendationCategory.clarity;
  }
}

/// Recomendación editorial: qué problema hay, dónde y por qué mejorarlo.
class Recommendation {
  const Recommendation({
    required this.category,
    required this.problem,
    required this.suggestion,
    this.excerpt,
  });

  final RecommendationCategory category;
  final String problem;
  final String suggestion;
  final String? excerpt;

  Map<String, dynamic> toJson() => {
        'categoria': category.name,
        'fragmento': excerpt,
        'problema': problem,
        'sugerencia': suggestion,
      };

  factory Recommendation.fromJson(Map<String, dynamic> json) => Recommendation(
        category: RecommendationCategory.fromLabel(
            (json['categoria'] ?? json['category'])?.toString()),
        excerpt: (json['fragmento'] ?? json['excerpt'])?.toString(),
        problem: (json['problema'] ?? json['problem'] ?? '').toString(),
        suggestion: (json['sugerencia'] ?? json['suggestion'] ?? '').toString(),
      );

  String toPlainText() {
    final b = StringBuffer('[${category.label}] $problem');
    if (excerpt != null && excerpt!.isNotEmpty) b.write('\n  Fragmento: "$excerpt"');
    if (suggestion.isNotEmpty) b.write('\n  Sugerencia: $suggestion');
    return b.toString();
  }
}

/// Problema editorial identificado en el diagnóstico.
class EditorialIssue {
  const EditorialIssue({
    required this.category,
    required this.description,
    this.excerpt,
  });

  final String category;
  final String description;
  final String? excerpt;

  Map<String, dynamic> toJson() => {
        'categoria': category,
        'descripcion': description,
        'fragmento': excerpt,
      };

  factory EditorialIssue.fromJson(Object? raw) {
    if (raw is Map) {
      return EditorialIssue(
        category: (raw['categoria'] ?? raw['tipo'] ?? 'General').toString(),
        description:
            (raw['descripcion'] ?? raw['description'] ?? '').toString(),
        excerpt: (raw['fragmento'] ?? raw['excerpt'])?.toString(),
      );
    }
    return EditorialIssue(category: 'General', description: '$raw');
  }
}

/// Resultado de la fase de análisis.
class TextAnalysis {
  const TextAnalysis({
    required this.detectedDomain,
    required this.detectedAudience,
    required this.detectedTone,
    required this.technicalLevel,
    this.formality = '',
    this.purpose = '',
    this.problems = const [],
    this.observations = const [],
    this.isDemo = false,
  });

  final String detectedDomain;
  final String detectedAudience;
  final String detectedTone;
  final String technicalLevel;
  final String formality;
  final String purpose;
  final List<EditorialIssue> problems;
  final List<String> observations;

  /// Verdadero si lo produjo el servicio de demostración (reglas locales).
  final bool isDemo;

  Map<String, dynamic> toJson() => {
        'dominioDetectado': detectedDomain,
        'audienciaDetectada': detectedAudience,
        'tonoDetectado': detectedTone,
        'nivelTecnico': technicalLevel,
        'nivelFormalidad': formality,
        'proposito': purpose,
        'problemas': problems.map((p) => p.toJson()).toList(),
        'observaciones': observations,
        'demo': isDemo,
      };

  factory TextAnalysis.fromJson(Map<String, dynamic> json) => TextAnalysis(
        detectedDomain: (json['dominioDetectado'] ?? '').toString(),
        detectedAudience: (json['audienciaDetectada'] ?? '').toString(),
        detectedTone: (json['tonoDetectado'] ?? '').toString(),
        technicalLevel: (json['nivelTecnico'] ?? '').toString(),
        formality: (json['nivelFormalidad'] ?? '').toString(),
        purpose: (json['proposito'] ?? '').toString(),
        problems: (json['problemas'] as List? ?? const [])
            .map(EditorialIssue.fromJson)
            .toList(),
        observations: _stringList(json['observaciones']),
        isDemo: json['demo'] as bool? ?? false,
      );

  static List<String> _stringList(Object? raw) {
    if (raw is List) return raw.map((e) => e.toString()).toList();
    if (raw is String && raw.trim().isNotEmpty) return [raw];
    return const [];
  }

  String toPlainText() {
    final b = StringBuffer()
      ..writeln('DIAGNÓSTICO')
      ..writeln('Dominio: $detectedDomain')
      ..writeln('Audiencia: $detectedAudience')
      ..writeln('Tono: $detectedTone')
      ..writeln('Formalidad: $formality')
      ..writeln('Propósito: $purpose')
      ..writeln('Nivel técnico: $technicalLevel');
    if (problems.isNotEmpty) {
      b.writeln('Problemas:');
      for (final p in problems) {
        b.writeln('- [${p.category}] ${p.description}'
            '${p.excerpt == null ? '' : ' — "${p.excerpt}"'}');
      }
    }
    if (observations.isNotEmpty) {
      b.writeln('Observaciones:');
      for (final o in observations) {
        b.writeln('- $o');
      }
    }
    return b.toString();
  }
}

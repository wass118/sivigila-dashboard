/// Tipos de contenido que no puede alterarse durante la reescritura.
enum ProtectedType {
  number('Número', critical: true),
  percentage('Porcentaje', critical: true),
  date('Fecha', critical: true),
  epidemiologicalPeriod('Periodo epidemiológico', critical: true),
  range('Intervalo', critical: true),
  measurement('Cifra con unidad', critical: true),
  rate('Tasa', critical: true),
  ratio('Razón / proporción', critical: true),
  formula('Fórmula', critical: true),
  code('Código', critical: true),
  citation('Cita', critical: true),
  reference('Referencia / enlace', critical: true),
  acronym('Sigla / acrónimo'),
  institution('Institución'),
  properName('Nombre propio'),
  eventName('Evento de interés'),
  scientificName('Nombre científico'),
  technicalTerm('Término técnico');

  const ProtectedType(this.label, {this.critical = false});

  final String label;

  /// Los tipos críticos generan alertas de prioridad alta en la auditoría.
  final bool critical;

  static ProtectedType fromName(String? name) {
    final folded = (name ?? '').toLowerCase();
    for (final t in ProtectedType.values) {
      if (t.name.toLowerCase() == folded || t.label.toLowerCase() == folded) {
        return t;
      }
    }
    return switch (folded) {
      'numero' || 'número' || 'cifra' => ProtectedType.number,
      'fecha' => ProtectedType.date,
      'porcentaje' => ProtectedType.percentage,
      'codigo' || 'código' => ProtectedType.code,
      'sigla' || 'acronimo' || 'acrónimo' => ProtectedType.acronym,
      'cita' => ProtectedType.citation,
      'referencia' => ProtectedType.reference,
      'tasa' => ProtectedType.rate,
      'unidad' => ProtectedType.measurement,
      'nombre' || 'nombre propio' => ProtectedType.properName,
      _ => ProtectedType.technicalTerm,
    };
  }
}

/// Origen de la identificación.
enum DetectionSource { rules, model }

/// Elemento protegido localizado en el texto original.
class ProtectedElement {
  const ProtectedElement({
    required this.value,
    required this.type,
    this.start = -1,
    this.end = -1,
    this.source = DetectionSource.rules,
  });

  final String value;
  final ProtectedType type;

  /// Posición en el texto original (-1 si la reporta el modelo).
  final int start;
  final int end;
  final DetectionSource source;

  Map<String, dynamic> toJson() => {
        'valor': value,
        'tipo': type.name,
        'inicio': start,
        'fin': end,
        'origen': source.name,
      };

  factory ProtectedElement.fromJson(Map<String, dynamic> json) =>
      ProtectedElement(
        value: (json['valor'] ?? json['value'] ?? '').toString(),
        type: ProtectedType.fromName(
            (json['tipo'] ?? json['type'])?.toString()),
        start: (json['inicio'] as num?)?.toInt() ?? -1,
        end: (json['fin'] as num?)?.toInt() ?? -1,
        source: json['origen'] == 'rules'
            ? DetectionSource.rules
            : DetectionSource.model,
      );

  @override
  bool operator ==(Object other) =>
      other is ProtectedElement &&
      other.value == value &&
      other.type == type &&
      other.start == start;

  @override
  int get hashCode => Object.hash(value, type, start);
}

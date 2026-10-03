/// Severidad de una alerta de fidelidad.
enum WarningSeverity {
  high('Alta'),
  medium('Media'),
  low('Informativa');

  const WarningSeverity(this.label);
  final String label;

  static WarningSeverity fromName(String? name) {
    final n = (name ?? '').toLowerCase();
    if (n.startsWith('alt') || n == 'high' || n == 'critica') {
      return WarningSeverity.high;
    }
    if (n.startsWith('baj') || n == 'low' || n.startsWith('info')) {
      return WarningSeverity.low;
    }
    return WarningSeverity.medium;
  }
}

/// Origen de la alerta: auditoría local determinista o el propio modelo.
enum WarningOrigin { audit, model }

/// Alerta de fidelidad. Incluye valor original y valor encontrado; nunca se
/// usa para modificar el texto automáticamente.
class FidelityWarning {
  const FidelityWarning({
    required this.category,
    required this.message,
    required this.severity,
    this.originalValue,
    this.foundValue,
    this.origin = WarningOrigin.audit,
  });

  /// Categoría legible (p. ej., "Porcentaje", "Grado de certeza").
  final String category;
  final String message;
  final WarningSeverity severity;
  final String? originalValue;
  final String? foundValue;
  final WarningOrigin origin;

  Map<String, dynamic> toJson() => {
        'tipo': category,
        'mensaje': message,
        'severidad': severity.name,
        'original': originalValue,
        'encontrado': foundValue,
        'origen': origin.name,
      };

  factory FidelityWarning.fromJson(Map<String, dynamic> json,
          {WarningOrigin origin = WarningOrigin.model}) =>
      FidelityWarning(
        category: (json['tipo'] ?? json['type'] ?? 'Revisión').toString(),
        message: (json['mensaje'] ?? json['message'] ?? '').toString(),
        severity: WarningSeverity.fromName(
            (json['severidad'] ?? json['severity'])?.toString()),
        originalValue: json['original']?.toString(),
        foundValue: (json['encontrado'] ?? json['found'])?.toString(),
        origin: json['origen'] == 'audit' ? WarningOrigin.audit : origin,
      );
}

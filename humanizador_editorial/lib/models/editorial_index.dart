/// Componente transparente del índice editorial.
class EditorialMetric {
  const EditorialMetric({
    required this.name,
    required this.value,
    required this.unit,
    required this.score,
    required this.explanation,
  });

  final String name;

  /// Valor observado (p. ej., 27.4 palabras por oración).
  final double value;
  final String unit;

  /// Puntuación 0–100 derivada del valor con una fórmula documentada.
  final double score;
  final String explanation;
}

/// Índice editorial: promedio de métricas observables de redacción.
///
/// Es un indicador interno de calidad de redacción. No mide autoría, no
/// estima probabilidad de texto generado por IA y no es un detector.
class EditorialIndex {
  const EditorialIndex({required this.metrics, required this.wordCount,
      required this.sentenceCount});

  final List<EditorialMetric> metrics;
  final int wordCount;
  final int sentenceCount;

  double get score {
    if (metrics.isEmpty) return 0;
    final total = metrics.fold<double>(0, (a, m) => a + m.score);
    return total / metrics.length;
  }

  EditorialMetric? metric(String name) {
    for (final m in metrics) {
      if (m.name == name) return m;
    }
    return null;
  }
}

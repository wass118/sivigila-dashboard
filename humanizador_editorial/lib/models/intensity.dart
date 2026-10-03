/// Nivel de intervención editorial.
enum Intensity {
  conservative(
    label: 'Conservadora',
    description: 'Cambios mínimos: corrige rigidez y redundancias evidentes.',
    instruction: 'Realiza cambios mínimos. Conserva la estructura, el orden '
        'de las oraciones y la mayor parte del vocabulario. Interviene solo '
        'en redundancias evidentes, fórmulas vacías y construcciones rígidas.',
  ),
  moderate(
    label: 'Moderada',
    description: 'Mejora naturalidad y cohesión manteniendo la estructura.',
    instruction: 'Mejora la naturalidad y la cohesión manteniendo la '
        'estructura general de párrafos. Puedes reordenar elementos dentro '
        'de una oración, variar conectores y unir o dividir oraciones cuando '
        'mejore la lectura.',
  ),
  deep(
    label: 'Profunda',
    description: 'Puede reconstruir oraciones y párrafos sin cambiar el '
        'significado.',
    instruction: 'Puedes reconstruir oraciones y párrafos completos cuando '
        'sea necesario para la claridad, sin modificar el significado, los '
        'datos ni las conclusiones. No agregues ni elimines información.',
  ),
  recommendationsOnly(
    label: 'Solo recomendaciones',
    description: 'Analiza el texto sin generar una nueva versión.',
    instruction: 'NO reescribas el texto. Devuelve "rewrittenText": null y '
        'concéntrate en recomendaciones editoriales concretas.',
  );

  const Intensity({
    required this.label,
    required this.description,
    required this.instruction,
  });

  final String label;
  final String description;
  final String instruction;

  bool get producesRewrite => this != Intensity.recommendationsOnly;

  static Intensity fromName(String? name) => Intensity.values
      .firstWhere((i) => i.name == name, orElse: () => Intensity.moderate);
}

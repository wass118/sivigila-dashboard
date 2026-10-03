/// Plantilla documental (FUTURA FUNCIONALIDAD, v1.2).
///
/// Define estructura, tono y reglas propias de un tipo de documento. En esta
/// versión solo existe el modelo y el catálogo; no se aplica al flujo.
class DocumentTemplate {
  const DocumentTemplate({
    required this.id,
    required this.name,
    required this.sections,
    required this.tone,
    this.rules = const [],
  });

  final String id;
  final String name;
  final List<String> sections;
  final String tone;
  final List<String> rules;
}

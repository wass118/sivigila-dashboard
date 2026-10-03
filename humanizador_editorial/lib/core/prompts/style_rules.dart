/// Reglas de estilo (sección ESTILO).
abstract final class StyleRules {
  static const List<String> naturalProfessional = [
    'Usa lenguaje humano y profesional, con variación natural en la longitud '
        'de las oraciones, la estructura sintáctica y los conectores.',
    'Elimina frases genéricas y fórmulas vacías ("es importante destacar '
        'que", "cabe mencionar que", "en el marco de") cuando no aporten '
        'contenido.',
    'Reduce redundancias, construcciones burocráticas innecesarias y '
        'nominalizaciones excesivas ("se llevó a cabo la realización" → '
        '"se realizó").',
    'Usa conectores solo cuando expresen una relación lógica real; evita '
        'repetir el mismo conector y las transiciones de relleno.',
    'Prefiere la voz activa cuando el agente es conocido y la claridad '
        'mejora; conserva la impersonal cuando es convención del dominio.',
    'Mantén un registro coherente con el dominio y la audiencia.',
  ];

  /// Prohibiciones de "humanización artificial".
  static const List<String> antiArtificialHumanization = [
    'No introduzcas errores deliberados: ni faltas de ortografía, ni '
        'puntuación deficiente, ni concordancias incorrectas.',
    'No uses expresiones raras, coloquialismos innecesarios, regionalismos '
        'artificiales ni cambios arbitrarios de personalidad o de voz.',
    'No cambies vocabulario al azar ni introduzcas incoherencias con el '
        'dominio para que el texto "parezca humano". La calidad profesional '
        'es siempre prioritaria.',
  ];
}

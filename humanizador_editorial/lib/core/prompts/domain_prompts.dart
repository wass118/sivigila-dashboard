/// Contextos de dominio (sección CONTEXTO DE DOMINIO). Un texto por perfil.
abstract final class DomainPrompts {
  static const String general =
      'Texto de propósito general. Prioriza claridad y naturalidad sin '
      'perder el registro original.';

  static const String academic =
      'Texto académico o científico. Conserva la estructura argumentativa, '
      'las citas, el aparato crítico y la cautela epistémica (hedging). No '
      'conviertas hipótesis en hechos ni resultados en conclusiones.';

  static const String clinical =
      'Texto clínico o de salud. Conserva diagnósticos, dosis, vías, '
      'frecuencias, valores de laboratorio, unidades y escalas exactamente. '
      'No sustituyas términos clínicos por equivalentes coloquiales.';

  static const String publicHealthColombia =
      'Vigilancia en salud pública en Colombia. Conserva el lenguaje técnico '
      'de vigilancia epidemiológica: SIVIGILA, INS, MINSALUD, ASIS, eventos '
      'de interés en salud pública, fichas de notificación, indicadores, '
      'incidencia, prevalencia, mortalidad, letalidad, tasas, razones, '
      'periodos y semanas epidemiológicas, conglomerados, brotes, '
      'investigación epidemiológica de campo (IEC), SITREP, UPGD y EAPB '
      'cuando aparezcan. No inventes lineamientos, códigos de evento, '
      'definiciones de caso ni cifras.';

  static const String administrative =
      'Texto administrativo o institucional. Mantén la formalidad y la '
      'trazabilidad (números de radicado, fechas, dependencias), pero '
      'elimina fórmulas burocráticas que no aportan contenido.';

  static const String legal =
      'Texto jurídico. Conserva literalmente normas, artículos, numerales, '
      'citas de sentencias y términos de arte. No reformules el alcance de '
      'obligaciones, plazos ni condiciones.';

  static const String business =
      'Texto empresarial. Prioriza claridad orientada a decisiones; conserva '
      'cifras, metas, indicadores y responsables.';

  static const String outreach =
      'Texto divulgativo. Facilita la lectura para público no especializado '
      'sin sacrificar exactitud; puedes explicar con otras palabras pero sin '
      'agregar datos.';

  /// Reglas adicionales del perfil de vigilancia en salud pública.
  static const List<String> publicHealthRules = [
    'Diferencia claramente entre dato observado, interpretación, hipótesis, '
        'conclusión y recomendación. No conviertas una hipótesis en '
        'conclusión ni una interpretación en dato.',
    'Si el original contiene una inferencia no sustentada (por ejemplo, una '
        'causa atribuida sin evidencia en el texto), consérvala tal como '
        'está y señálala como recomendación de revisión; no agregues una '
        'justificación inventada.',
    'Conserva clasificaciones de caso (sospechoso, probable, confirmado, '
        'descartado), periodos y semanas epidemiológicas, y denominadores de '
        'tasas (por ejemplo, "por 100.000 habitantes").',
  ];

  static const String publicHealthPrivacyNotice =
      'No introduzca nombres completos, números de documento, direcciones, '
      'teléfonos, coordenadas, números de historia clínica u otros datos '
      'personales identificables, salvo que el entorno utilizado esté '
      'autorizado para procesarlos.';
}

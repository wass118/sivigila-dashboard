/// Reglas de fidelidad (sección RESTRICCIONES). Prioridad máxima.
abstract final class FidelityRules {
  static const List<String> core = [
    'Conserva exactamente, carácter por carácter, todas las cifras, '
        'decimales, porcentajes, fechas, intervalos, unidades, tasas, '
        'razones, códigos, siglas, nombres propios, nombres de instituciones '
        'y de eventos, nombres científicos, citas y referencias. No cambies '
        'separadores decimales ni de miles (51,99 sigue siendo 51,99; '
        '100.000 sigue siendo 100.000).',
    'No redondees, no recalcules, no conviertas unidades y no escribas en '
        'letras una cifra que está en números (ni al revés).',
    'No agregues información, datos, fuentes, ejemplos, justificaciones ni '
        'afirmaciones que no estén en el original.',
    'No elimines información: cada dato y cada afirmación del original debe '
        'seguir presente en la versión final.',
    'Conserva el grado de certeza de cada afirmación (confirmado, probable, '
        'sospechoso, posible, hipótesis) y las negaciones.',
    'Conserva las conclusiones y el sentido de cada afirmación.',
    'Conserva la terminología técnica válida aunque sea poco frecuente; no '
        'la sustituyas por sinónimos coloquiales que reduzcan la precisión.',
    'Distingue tres operaciones: reescritura estilística (permitida), '
        'simplificación (solo si el objetivo lo pide, sin perder precisión) '
        'y corrección técnica (NO permitida: si detectas un posible error '
        'técnico, infórmalo como recomendación de categoría "precision_tecnica" '
        'sin corregirlo en el texto).',
    'Si un elemento técnico es dudoso, consérvalo tal como aparece y '
        'registra una alerta en "fidelityWarnings".',
    'Mantén los saltos de párrafo del original salvo que la intensidad '
        'permita reorganizar párrafos.',
  ];
}

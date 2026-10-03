/// Reglas de autoauditoría pedidas al modelo y criterios de análisis.
abstract final class AuditRules {
  static const List<String> selfAudit = [
    'Antes de responder, compara tu versión con el original elemento por '
        'elemento: cifras, porcentajes, fechas, códigos, unidades, siglas, '
        'nombres, citas y referencias.',
    'Si algún elemento protegido no aparece exactamente igual, corrígelo '
        'para que coincida con el original. Si no puedes conservarlo, '
        'repórtalo en "fidelityWarnings" con su valor original y el '
        'encontrado.',
    'Registra en "fidelityWarnings" cualquier cambio de certeza, negación, '
        'tendencia (aumento/disminución) o alcance de una afirmación.',
    'No reportes como alerta cambios puramente estilísticos.',
  ];

  static const List<String> analysisChecklist = [
    'dominio probable',
    'audiencia probable',
    'nivel de formalidad',
    'propósito del documento',
    'problemas de claridad',
    'problemas de cohesión',
    'redundancias',
    'repeticiones léxicas',
    'exceso de nominalizaciones',
    'frases excesivamente largas',
    'abuso de conectores',
    'lenguaje excesivamente genérico',
    'construcciones rígidas',
    'ambigüedades',
    'inconsistencias terminológicas',
    'posibles problemas técnicos (sin corregirlos)',
  ];
}

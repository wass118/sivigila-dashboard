/// Contratos JSON (sección FORMATO DE SALIDA).
abstract final class OutputFormats {
  static const String analysisSchema = '''
{
  "dominioDetectado": "string",
  "audienciaDetectada": "string",
  "tonoDetectado": "string",
  "nivelFormalidad": "string",
  "proposito": "string",
  "nivelTecnico": "bajo | medio | alto",
  "problemas": [
    {"categoria": "string", "descripcion": "string", "fragmento": "cita literal breve del original"}
  ],
  "observaciones": ["string"]
}''';

  static const String humanizationSchema = '''
{
  "analysis": {
    "dominioDetectado": "string",
    "audienciaDetectada": "string",
    "tonoDetectado": "string",
    "nivelTecnico": "bajo | medio | alto",
    "problemas": [{"categoria": "string", "descripcion": "string", "fragmento": "string"}],
    "observaciones": ["string"]
  },
  "rewrittenText": "texto completo generado (o null en modo solo recomendaciones)",
  "recommendations": [
    {"categoria": "claridad | precision | cohesion | estructura | redundancia | tono | consistencia_terminologica | precision_tecnica",
     "fragmento": "cita literal breve del original",
     "problema": "qué ocurre y por qué afecta la lectura",
     "sugerencia": "cómo mejorarlo sin agregar información"}
  ],
  "fidelityWarnings": [
    {"tipo": "string", "original": "valor original", "encontrado": "valor en tu versión o null", "mensaje": "string", "severidad": "alta | media | baja"}
  ],
  "protectedElements": [{"valor": "string", "tipo": "string"}],
  "improvements": ["explicación breve de cada mejora editorial realizada"]
}''';

  static const String fragmentSchema = '''
{
  "rewrittenText": "versión del fragmento",
  "improvements": ["string"],
  "fidelityWarnings": [{"tipo": "string", "original": "string", "encontrado": "string", "mensaje": "string", "severidad": "alta | media | baja"}]
}''';

  static const String jsonOnly =
      'Responde SOLO con el objeto JSON, sin comentarios, sin texto antes o '
      'después y sin bloques de código. Usa comillas dobles y escapa los '
      'saltos de línea dentro de cadenas como \\n.';
}

import '../../core/utils/text_utils.dart';
import '../../models/editorial_index.dart';

/// Léxico de referencia para métricas observables de redacción.
abstract final class EditorialLexicon {
  static const List<String> connectors = [
    'además', 'asimismo', 'así mismo', 'por otra parte', 'por otro lado',
    'sin embargo', 'no obstante', 'por lo tanto', 'por consiguiente',
    'en consecuencia', 'de igual manera', 'de igual forma', 'del mismo modo',
    'en este sentido', 'en este contexto', 'finalmente', 'en primer lugar',
    'en segundo lugar', 'por último', 'igualmente', 'de esta manera',
    'de este modo', 'en efecto', 'es decir', 'por ende', 'en conclusión',
    'en resumen', 'a su vez', 'por su parte', 'cabe destacar',
  ];

  /// Fórmulas genéricas que rara vez aportan contenido.
  static const List<String> genericPhrases = [
    'es importante destacar que', 'es importante mencionar que',
    'es importante resaltar que', 'es importante señalar que',
    'cabe mencionar que', 'cabe destacar que', 'cabe resaltar que',
    'cabe señalar que', 'vale la pena mencionar que', 'juega un papel '
        'fundamental', 'juega un papel importante', 'en la actualidad',
    'hoy en día', 'en el marco de', 'a nivel de', 'en lo que respecta a',
    'en lo referente a', 'de cara a', 'en aras de', 'como se mencionó '
        'anteriormente', 'por medio de la presente',
  ];

  /// Construcciones rígidas o burocráticas.
  static const List<String> rigidConstructions = [
    'llevar a cabo', 'llevó a cabo', 'llevaron a cabo', 'lleva a cabo',
    'se procedió a', 'se procede a', 'procedió a realizar',
    'realizó la realización', 'con el fin de', 'con el objetivo de',
    'con el propósito de', 'debido al hecho de que', 'el día de hoy',
    'dar cumplimiento a', 'hacer entrega de', 'realizar la verificación',
    'se realizó la verificación', 'efectuar el seguimiento',
  ];

  /// Redundancias frecuentes (pleonasmos).
  static const List<String> redundancies = [
    'volver a repetir', 'subir arriba', 'bajar abajo', 'salir afuera',
    'entrar adentro', 'previamente programado', 'totalmente gratis',
    'completamente lleno', 'resultado final', 'hecho real', 'lapso de '
        'tiempo', 'opinión personal', 'colaborar juntos', 'un total de',
    'ambos dos', 'prever con antelación', 'base fundamental',
  ];

  static const List<String> ambiguousReferences = [
    'lo anterior', 'este último', 'esta última', 'dicho', 'dicha',
    'dichos', 'dichas', 'el mismo', 'la misma', 'los mismos', 'las mismas',
  ];

  static const List<String> causalInferences = [
    'se debe a', 'se deben a', 'debido a', 'a causa de', 'se atribuye',
    'se atribuyen', 'es consecuencia de', 'causado por', 'causada por',
    'obedece a', 'demuestra que', 'confirma que', 'evidencia que',
  ];

  static const List<List<String>> terminologyVariants = [
    ['periodo', 'período'],
    ['notificación', 'reporte'],
    ['fallecimiento', 'muerte', 'defunción'],
    ['paciente', 'usuario'],
  ];

  static const Set<String> stopwords = {
    'el', 'la', 'los', 'las', 'un', 'una', 'unos', 'unas', 'de', 'del', 'al',
    'a', 'en', 'y', 'o', 'u', 'e', 'que', 'por', 'para', 'con', 'sin', 'se',
    'su', 'sus', 'lo', 'le', 'les', 'es', 'son', 'fue', 'fueron', 'ha',
    'han', 'como', 'más', 'menos', 'este', 'esta', 'estos', 'estas', 'ese',
    'esa', 'entre', 'sobre', 'cual', 'cuales', 'donde', 'cuando', 'también',
    'muy', 'ya', 'no', 'si', 'sí', 'pero', 'porque', 'desde', 'hasta',
    'durante', 'según', 'cada', 'todo', 'toda', 'todos', 'todas', 'otro',
    'otra', 'otros', 'otras', 'mismo', 'misma', 'casos', 'caso',
  };

  static final RegExp nominalization = RegExp(
      r'^[\p{L}]{4,}(?:ción|ciones|sión|siones|miento|mientos|idad|idades|'
      r'ancia|ancias|encia|encias)$',
      unicode: true);
}

/// Calcula el índice editorial a partir de variables transparentes.
///
/// Fórmulas (todas acotadas a 0–100):
/// * Longitud media de oración: 100 si está entre 12 y 25 palabras; resta 4
///   puntos por palabra fuera del rango.
/// * Oraciones largas (> 35 palabras): 100 − 2 × porcentaje.
/// * Repetición léxica: 100 − 12 × (palabras de contenido que superan 1,5
///   apariciones por cada 100 palabras, con mínimo 3 apariciones).
/// * Densidad de conectores: 100 si ≤ 3 por cada 100 palabras; resta 15 por
///   unidad adicional.
/// * Nominalizaciones: 100 si ≤ 8 por cada 100 palabras; resta 6 por unidad
///   adicional.
/// * Fórmulas genéricas, rígidas y redundancias: 100 − 25 × (casos por cada
///   100 palabras).
///
/// Es un indicador interno de calidad de redacción, no un detector de IA.
class EditorialMetricsCalculator {
  const EditorialMetricsCalculator();

  EditorialIndex compute(String text) {
    final words = TextUtils.words(text);
    final wordCount = words.length;
    final sentences = TextUtils.sentences(text);
    if (wordCount == 0 || sentences.isEmpty) {
      return const EditorialIndex(metrics: [], wordCount: 0, sentenceCount: 0);
    }
    final per100 = 100 / wordCount;
    final folded = TextUtils.fold(text);

    final sentenceLengths =
        sentences.map(TextUtils.countWords).where((n) => n > 0).toList();
    final avgLen = sentenceLengths.isEmpty
        ? 0.0
        : sentenceLengths.reduce((a, b) => a + b) / sentenceLengths.length;
    final double outOfRange =
        avgLen < 12 ? 12 - avgLen : (avgLen > 25 ? avgLen - 25 : 0.0);
    final longPct = sentenceLengths.isEmpty
        ? 0.0
        : 100 *
            sentenceLengths.where((n) => n > 35).length /
            sentenceLengths.length;

    final repeated = repeatedContentWords(words);
    final connectorCount = countPhrases(folded, EditorialLexicon.connectors);
    final nominalCount = words
        .where((w) => EditorialLexicon.nominalization.hasMatch(w.toLowerCase()))
        .length;
    final formulaic = countPhrases(folded, EditorialLexicon.genericPhrases) +
        countPhrases(folded, EditorialLexicon.rigidConstructions) +
        countPhrases(folded, EditorialLexicon.redundancies);

    double clamp(double v) => v.clamp(0, 100).toDouble();

    return EditorialIndex(
      wordCount: wordCount,
      sentenceCount: sentences.length,
      metrics: [
        EditorialMetric(
          name: 'Longitud media de oración',
          value: avgLen,
          unit: 'palabras',
          score: clamp(100 - 4 * outOfRange),
          explanation: 'Rango de referencia: 12–25 palabras por oración.',
        ),
        EditorialMetric(
          name: 'Oraciones largas',
          value: longPct,
          unit: '% (> 35 palabras)',
          score: clamp(100 - 2 * longPct),
          explanation: 'Porcentaje de oraciones con más de 35 palabras.',
        ),
        EditorialMetric(
          name: 'Repetición léxica',
          value: repeated.length.toDouble(),
          unit: 'palabras repetidas',
          score: clamp(100 - 12.0 * repeated.length),
          explanation: 'Palabras de contenido con frecuencia alta '
              '(≥ 3 apariciones y > 1,5 por cada 100 palabras).',
        ),
        EditorialMetric(
          name: 'Densidad de conectores',
          value: connectorCount * per100,
          unit: 'por 100 palabras',
          score: clamp(100 - 15 * ((connectorCount * per100) - 3)
              .clamp(0, double.infinity)),
          explanation: 'Referencia: hasta 3 conectores por cada 100 palabras.',
        ),
        EditorialMetric(
          name: 'Nominalizaciones',
          value: nominalCount * per100,
          unit: 'por 100 palabras',
          score: clamp(100 - 6 * ((nominalCount * per100) - 8)
              .clamp(0, double.infinity)),
          explanation: 'Sustantivos en -ción, -miento, -idad, -encia… '
              'Referencia: hasta 8 por cada 100 palabras.',
        ),
        EditorialMetric(
          name: 'Fórmulas genéricas y rígidas',
          value: formulaic * per100,
          unit: 'por 100 palabras',
          score: clamp(100 - 25 * formulaic * per100),
          explanation: 'Fórmulas vacías, construcciones burocráticas y '
              'redundancias del léxico de referencia.',
        ),
      ],
    );
  }

  /// Palabras de contenido sobreutilizadas, ordenadas por frecuencia.
  static List<MapEntry<String, int>> repeatedContentWords(List<String> words) {
    final counts = <String, int>{};
    for (final w in words) {
      final lw = w.toLowerCase();
      if (lw.length < 5 || EditorialLexicon.stopwords.contains(lw)) continue;
      if (RegExp(r'\d').hasMatch(lw)) continue;
      counts[lw] = (counts[lw] ?? 0) + 1;
    }
    final threshold = words.length * 0.015;
    final result = counts.entries
        .where((e) => e.value >= 3 && e.value > threshold)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return result;
  }

  /// Cuenta apariciones de frases (texto ya plegado con [TextUtils.fold]).
  static int countPhrases(String foldedText, List<String> phrases) {
    var total = 0;
    for (final phrase in phrases) {
      total += phraseRegex(phrase).allMatches(foldedText).length;
    }
    return total;
  }

  static final Map<String, RegExp> _cache = {};

  static RegExp phraseRegex(String phrase) => _cache.putIfAbsent(
      phrase,
      () => RegExp(
          '(?<![\\p{L}])${RegExp.escape(TextUtils.fold(phrase))}(?![\\p{L}])',
          unicode: true));
}

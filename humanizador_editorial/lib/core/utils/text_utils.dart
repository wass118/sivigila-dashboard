/// Utilidades de texto compartidas (conteo, normalización, división).
abstract final class TextUtils {
  static final RegExp wordPattern =
      RegExp(r"[\p{L}\p{N}]+(?:[.,'\-][\p{L}\p{N}]+)*", unicode: true);

  static final RegExp _sentenceBoundary =
      RegExp(r'(?<=[.!?…])\s+(?=[\p{Lu}¿¡"«(\d])', unicode: true);

  static int countWords(String text) => wordPattern.allMatches(text).length;

  static List<String> words(String text) =>
      wordPattern.allMatches(text).map((m) => m.group(0)!).toList();

  /// Párrafos no vacíos (separados por uno o más saltos de línea).
  static List<String> paragraphs(String text) => text
      .split(RegExp(r'\n+'))
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .toList();

  /// Oraciones aproximadas. No corta decimales (51.99) porque exige espacio
  /// y mayúscula/dígito después del signo.
  static List<String> sentences(String text) {
    final result = <String>[];
    for (final paragraph in paragraphs(text)) {
      result.addAll(paragraph
          .split(_sentenceBoundary)
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty));
    }
    return result;
  }

  /// Minúsculas sin tildes, para comparaciones de vocabulario.
  static String fold(String input) {
    const from = 'áàäâéèëêíìïîóòöôúùüûÁÀÄÂÉÈËÊÍÌÏÎÓÒÖÔÚÙÜÛ';
    const to = 'aaaaeeeeiiiioooouuuuAAAAEEEEIIIIOOOOUUUU';
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      final ch = String.fromCharCode(rune);
      final idx = from.indexOf(ch);
      buffer.write(idx >= 0 ? to[idx] : ch);
    }
    return buffer.toString().toLowerCase();
  }

  /// Colapsa espacios (incluido NBSP) para comparar entidades.
  static String normalizeSpaces(String input) =>
      input.replaceAll(RegExp(r'[\s  ]+'), ' ').trim();

  /// Recorta un fragmento para mostrarlo en la interfaz.
  static String excerpt(String text, {int max = 140}) {
    final clean = normalizeSpaces(text);
    if (clean.length <= max) return clean;
    return '${clean.substring(0, max - 1)}…';
  }

  /// Título razonable a partir de la primera línea.
  static String titleFrom(String text, {int max = 70}) {
    final first = paragraphs(text).firstOrNull ?? 'Documento sin título';
    return excerpt(first, max: max);
  }

  static String capitalizeFirst(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

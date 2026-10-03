import '../../models/protected_element.dart';

/// Segmento de un documento largo.
class TextSegment {
  const TextSegment({
    required this.index,
    required this.text,
    required this.separatorAfter,
    required this.contextBefore,
  });

  final int index;
  final String text;

  /// Separador original (saltos de línea) que sigue al segmento.
  final String separatorAfter;

  /// Final del segmento anterior, enviado como contexto de solo lectura.
  final String contextBefore;
}

/// Divide documentos que exceden el límite por petición.
///
/// Reglas: corta preferentemente entre párrafos; si un párrafo excede el
/// límite, corta entre oraciones; nunca corta dentro de una tabla (líneas con
/// "|" o tabuladores consecutivas) ni dentro de un elemento protegido. Si
/// una unidad indivisible supera el límite, se envía completa.
class TextSegmenter {
  const TextSegmenter();

  static final RegExp _paragraphSeparator = RegExp(r'\n[ \t]*\n+|\n');
  static final RegExp _sentenceEnd = RegExp(r'[.!?…]\s+');

  List<TextSegment> split(
    String text, {
    required int maxChars,
    int contextChars = 600,
    List<ProtectedElement> protectedSpans = const [],
  }) {
    if (text.length <= maxChars) {
      return [TextSegment(index: 0, text: text, separatorAfter: '',
          contextBefore: '')];
    }
    final units = _units(text, maxChars, protectedSpans);

    final segments = <TextSegment>[];
    final current = StringBuffer();
    var pendingSeparator = '';
    var previousText = '';

    void flush(String separatorAfter) {
      if (current.isEmpty) return;
      final segText = current.toString();
      segments.add(TextSegment(
        index: segments.length,
        text: segText,
        separatorAfter: separatorAfter,
        contextBefore: previousText.length > contextChars
            ? previousText.substring(previousText.length - contextChars)
            : previousText,
      ));
      previousText = segText;
      current.clear();
    }

    for (final unit in units) {
      final projected =
          current.length + pendingSeparator.length + unit.text.length;
      if (current.isNotEmpty && projected > maxChars) {
        flush(pendingSeparator);
        pendingSeparator = '';
      }
      if (current.isNotEmpty) current.write(pendingSeparator);
      current.write(unit.text);
      pendingSeparator = unit.separatorAfter;
    }
    flush(pendingSeparator);
    return segments;
  }

  /// Recompone el documento a partir de los textos procesados por segmento.
  String join(List<TextSegment> segments, List<String> processed) {
    assert(segments.length == processed.length);
    final b = StringBuffer();
    for (var i = 0; i < segments.length; i++) {
      b.write(processed[i].trim());
      b.write(segments[i].separatorAfter);
    }
    return b.toString();
  }

  List<_Unit> _units(
      String text, int maxChars, List<ProtectedElement> protectedSpans) {
    // 1. Bloques de párrafo conservando separadores.
    final blocks = <_Unit>[];
    var cursor = 0;
    for (final m in _paragraphSeparator.allMatches(text)) {
      blocks.add(_Unit(text.substring(cursor, m.start), m.group(0)!,
          cursor));
      cursor = m.end;
    }
    blocks.add(_Unit(text.substring(cursor), '', cursor));

    // 2. Fusionar líneas consecutivas de tabla en una unidad indivisible.
    final merged = <_Unit>[];
    for (final b in blocks) {
      final isTable = b.text.contains('|') || b.text.contains('\t');
      if (isTable && merged.isNotEmpty && merged.last.isTable) {
        final last = merged.removeLast();
        merged.add(_Unit('${last.text}${last.separatorAfter}${b.text}',
            b.separatorAfter, last.start, isTable: true));
      } else {
        merged.add(_Unit(b.text, b.separatorAfter, b.start, isTable: isTable));
      }
    }

    // 3. Párrafos que exceden el límite: dividir por oraciones seguras.
    final result = <_Unit>[];
    for (final u in merged) {
      if (u.text.length <= maxChars || u.isTable) {
        result.add(u);
        continue;
      }
      result.addAll(_splitSentences(u, maxChars, protectedSpans));
    }
    return result;
  }

  List<_Unit> _splitSentences(
      _Unit unit, int maxChars, List<ProtectedElement> protectedSpans) {
    bool insideProtected(int absolute) => protectedSpans
        .any((p) => p.start >= 0 && absolute > p.start && absolute < p.end);

    final pieces = <_Unit>[];
    var start = 0;
    var lastCut = 0;
    final cuts = <int>[];
    for (final m in _sentenceEnd.allMatches(unit.text)) {
      if (!insideProtected(unit.start + m.end)) cuts.add(m.end);
    }
    for (final cut in cuts) {
      if (cut - start > maxChars && lastCut > start) {
        pieces.add(_Unit(unit.text.substring(start, lastCut), '',
            unit.start + start));
        start = lastCut;
      }
      lastCut = cut;
    }
    if (unit.text.length - start > maxChars && lastCut > start) {
      pieces.add(_Unit(unit.text.substring(start, lastCut), '',
          unit.start + start));
      start = lastCut;
    }
    pieces.add(_Unit(unit.text.substring(start), unit.separatorAfter,
        unit.start + start));
    // Las piezas de una misma oración se unen con espacio al recomponer.
    for (var i = 0; i < pieces.length - 1; i++) {
      final p = pieces[i];
      final trimmed = p.text.trimRight();
      pieces[i] = _Unit(trimmed, p.text.substring(trimmed.length).isEmpty
          ? ' '
          : p.text.substring(trimmed.length), p.start);
    }
    return pieces;
  }
}

class _Unit {
  _Unit(this.text, this.separatorAfter, this.start, {this.isTable = false});
  final String text;
  final String separatorAfter;
  final int start;
  final bool isTable;
}

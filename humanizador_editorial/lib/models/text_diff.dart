/// Operación elemental de un diff.
enum DiffOperation { equal, insert, delete }

/// Tramo de texto con su operación.
class DiffSegment {
  const DiffSegment(this.operation, this.text);
  final DiffOperation operation;
  final String text;

  @override
  String toString() => '${operation.name}:"$text"';
}

/// Tipo de cambio a nivel de párrafo.
enum ParagraphChange { unchanged, modified, added, removed }

/// Diff de un párrafo (palabra a palabra cuando fue modificado).
class ParagraphDiff {
  const ParagraphDiff({required this.change, required this.segments});
  final ParagraphChange change;
  final List<DiffSegment> segments;
}

/// Estadísticas observables de los cambios.
class DiffStats {
  const DiffStats({
    this.wordsInserted = 0,
    this.wordsDeleted = 0,
    this.paragraphsModified = 0,
    this.paragraphsAdded = 0,
    this.paragraphsRemoved = 0,
    this.paragraphsUnchanged = 0,
  });

  final int wordsInserted;
  final int wordsDeleted;
  final int paragraphsModified;
  final int paragraphsAdded;
  final int paragraphsRemoved;
  final int paragraphsUnchanged;

  bool get hasChanges =>
      wordsInserted + wordsDeleted + paragraphsAdded + paragraphsRemoved > 0;
}

/// Resultado completo de la comparación original/generado.
class TextDiffResult {
  const TextDiffResult({required this.paragraphs, required this.stats});
  final List<ParagraphDiff> paragraphs;
  final DiffStats stats;

  static const empty = TextDiffResult(paragraphs: [], stats: DiffStats());
}

import 'package:flutter_test/flutter_test.dart';
import 'package:humanizador_editorial/models/text_diff.dart';
import 'package:humanizador_editorial/services/audit/text_differ.dart';

String rebuild(List<EditStep> steps, List<String> a, List<String> b,
    {required bool target}) {
  final out = StringBuffer();
  for (final s in steps) {
    switch (s.operation) {
      case DiffOperation.equal:
        out.write(a[s.aIndex]);
      case DiffOperation.delete:
        if (!target) out.write(a[s.aIndex]);
      case DiffOperation.insert:
        if (target) out.write(b[s.bIndex]);
    }
  }
  return out.toString();
}

void main() {
  test('Myers reconstruye ambas secuencias', () {
    final a = 'ABCABBA'.split('');
    final b = 'CBABAC'.split('');
    final steps = myers(a, b);
    expect(rebuild(steps, a, b, target: false), 'ABCABBA');
    expect(rebuild(steps, a, b, target: true), 'CBABAC');
    final edits = steps.where((s) => s.operation != DiffOperation.equal);
    expect(edits.length, 5); // distancia mínima conocida
  });

  test('Myers con secuencias vacías e idénticas', () {
    expect(myers<String>([], []), isEmpty);
    expect(myers(['a'], <String>[]).single.operation, DiffOperation.delete);
    expect(myers(<String>[], ['a']).single.operation, DiffOperation.insert);
    expect(myers(['a', 'b'], ['a', 'b']).every(
        (s) => s.operation == DiffOperation.equal), isTrue);
  });

  test('tope de distancia: degrada a reemplazo completo', () {
    final steps = myers(['a', 'b', 'c'], ['x', 'y', 'z'], maxD: 1);
    expect(steps.where((s) => s.operation == DiffOperation.delete).length, 3);
    expect(steps.where((s) => s.operation == DiffOperation.insert).length, 3);
  });

  test('diff de palabras marca solo lo cambiado', () {
    const differ = TextDiffer();
    final segs = differ.diffWords(
        'Se llevó a cabo la reunión.', 'Se realizó la reunión.');
    final deleted = segs
        .where((s) => s.operation == DiffOperation.delete)
        .map((s) => s.text)
        .join();
    final inserted = segs
        .where((s) => s.operation == DiffOperation.insert)
        .map((s) => s.text)
        .join();
    expect(deleted, contains('llevó a cabo'));
    expect(inserted, contains('realizó'));
    expect(segs.first.operation, DiffOperation.equal);
    expect(segs.last.text, contains('reunión.'));
  });

  test('diff por párrafos con estadísticas', () {
    const differ = TextDiffer();
    final r = differ.diff('Uno igual.\n\nDos viejo.\n\nTres borrado.',
        'Uno igual.\n\nDos nuevo.\n\nCuatro añadido.\n\nCinco extra.');
    expect(r.stats.paragraphsUnchanged, 1);
    expect(r.stats.paragraphsModified, 2);
    expect(r.stats.paragraphsAdded, 1);
    expect(r.stats.hasChanges, isTrue);
  });

  test('textos idénticos no tienen cambios', () {
    final r = const TextDiffer().diff('A b c.\nD e.', 'A b c.\nD e.');
    expect(r.stats.hasChanges, isFalse);
    expect(r.paragraphs.every((p) => p.change == ParagraphChange.unchanged),
        isTrue);
  });
}

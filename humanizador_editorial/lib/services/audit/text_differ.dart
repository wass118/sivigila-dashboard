import '../../core/utils/text_utils.dart';
import '../../models/text_diff.dart';

/// Comparación original/generado en dos niveles: primero alinea párrafos y
/// después compara palabra a palabra los párrafos modificados. Usa el
/// algoritmo de Myers (O((N+M)·D)) con un tope de distancia para mantener
/// el rendimiento en documentos largos.
class TextDiffer {
  const TextDiffer({this.maxEditDistance = 4000});

  final int maxEditDistance;

  static final RegExp _tokenPattern = RegExp(
      r'\s+|[\p{L}\p{N}]+(?:[.,][\p{N}]+)*|[^\s\p{L}\p{N}]',
      unicode: true);

  static List<String> tokenize(String text) =>
      _tokenPattern.allMatches(text).map((m) => m.group(0)!).toList();

  TextDiffResult diff(String original, String revised) {
    final a = TextUtils.paragraphs(original);
    final b = TextUtils.paragraphs(revised);
    final script = myers(a, b, maxD: maxEditDistance);

    final paragraphs = <ParagraphDiff>[];
    var inserted = 0, deleted = 0, modified = 0, added = 0, removed = 0;
    var unchanged = 0;

    var i = 0;
    while (i < script.length) {
      final op = script[i];
      if (op.operation == DiffOperation.equal) {
        paragraphs.add(ParagraphDiff(
            change: ParagraphChange.unchanged,
            segments: [DiffSegment(DiffOperation.equal, a[op.aIndex])]));
        unchanged++;
        i++;
        continue;
      }
      // Bloque contiguo de borrados e inserciones: se emparejan en orden.
      final dels = <int>[];
      final ins = <int>[];
      while (i < script.length && script[i].operation != DiffOperation.equal) {
        if (script[i].operation == DiffOperation.delete) {
          dels.add(script[i].aIndex);
        } else {
          ins.add(script[i].bIndex);
        }
        i++;
      }
      final pairs = dels.length < ins.length ? dels.length : ins.length;
      for (var p = 0; p < pairs; p++) {
        final segments = diffWords(a[dels[p]], b[ins[p]]);
        for (final s in segments) {
          final w = TextUtils.countWords(s.text);
          if (s.operation == DiffOperation.insert) inserted += w;
          if (s.operation == DiffOperation.delete) deleted += w;
        }
        paragraphs.add(ParagraphDiff(
            change: ParagraphChange.modified, segments: segments));
        modified++;
      }
      for (final d in dels.skip(pairs)) {
        paragraphs.add(ParagraphDiff(
            change: ParagraphChange.removed,
            segments: [DiffSegment(DiffOperation.delete, a[d])]));
        deleted += TextUtils.countWords(a[d]);
        removed++;
      }
      for (final n in ins.skip(pairs)) {
        paragraphs.add(ParagraphDiff(
            change: ParagraphChange.added,
            segments: [DiffSegment(DiffOperation.insert, b[n])]));
        inserted += TextUtils.countWords(b[n]);
        added++;
      }
    }

    return TextDiffResult(
      paragraphs: paragraphs,
      stats: DiffStats(
        wordsInserted: inserted,
        wordsDeleted: deleted,
        paragraphsModified: modified,
        paragraphsAdded: added,
        paragraphsRemoved: removed,
        paragraphsUnchanged: unchanged,
      ),
    );
  }

  /// Diff palabra a palabra con segmentos consecutivos fusionados.
  List<DiffSegment> diffWords(String a, String b) {
    final ta = tokenize(a);
    final tb = tokenize(b);
    final script = myers(ta, tb, maxD: maxEditDistance);
    final segments = <DiffSegment>[];
    void push(DiffOperation op, String text) {
      if (segments.isNotEmpty && segments.last.operation == op) {
        final last = segments.removeLast();
        segments.add(DiffSegment(op, last.text + text));
      } else {
        segments.add(DiffSegment(op, text));
      }
    }

    for (final e in script) {
      switch (e.operation) {
        case DiffOperation.equal:
          push(DiffOperation.equal, ta[e.aIndex]);
        case DiffOperation.delete:
          push(DiffOperation.delete, ta[e.aIndex]);
        case DiffOperation.insert:
          push(DiffOperation.insert, tb[e.bIndex]);
      }
    }
    return _absorbWhitespace(segments);
  }

  /// Un espacio aislado entre dos cambios se integra en ellos para que la
  /// vista sea legible ("[-a b-][+c d+]" en lugar de "[-a-] [-b-]...").
  List<DiffSegment> _absorbWhitespace(List<DiffSegment> input) {
    final out = <DiffSegment>[];
    for (var i = 0; i < input.length; i++) {
      final s = input[i];
      final isGap = s.operation == DiffOperation.equal &&
          s.text.trim().isEmpty &&
          i > 0 &&
          i < input.length - 1 &&
          input[i - 1].operation != DiffOperation.equal &&
          input[i + 1].operation != DiffOperation.equal;
      if (!isGap) {
        out.add(s);
        continue;
      }
      // Duplicar el espacio en borrado e inserción.
      out.add(DiffSegment(DiffOperation.delete, s.text));
      out.add(DiffSegment(DiffOperation.insert, s.text));
    }
    // Reagrupar: todos los borrados contiguos antes que las inserciones.
    final regrouped = <DiffSegment>[];
    var i = 0;
    while (i < out.length) {
      if (out[i].operation == DiffOperation.equal) {
        regrouped.add(out[i]);
        i++;
        continue;
      }
      final del = StringBuffer();
      final ins = StringBuffer();
      while (i < out.length && out[i].operation != DiffOperation.equal) {
        (out[i].operation == DiffOperation.delete ? del : ins)
            .write(out[i].text);
        i++;
      }
      if (del.isNotEmpty) {
        regrouped.add(DiffSegment(DiffOperation.delete, del.toString()));
      }
      if (ins.isNotEmpty) {
        regrouped.add(DiffSegment(DiffOperation.insert, ins.toString()));
      }
    }
    return regrouped;
  }
}

/// Paso del guion de edición.
class EditStep {
  const EditStep(this.operation, this.aIndex, this.bIndex);
  final DiffOperation operation;
  final int aIndex;
  final int bIndex;
}

/// Algoritmo de diff de Myers con recorte de prefijo/sufijo comunes.
/// Si la distancia supera [maxD], devuelve borrar todo + insertar todo.
List<EditStep> myers<T>(List<T> a, List<T> b, {int maxD = 4000}) {
  var prefix = 0;
  while (prefix < a.length && prefix < b.length && a[prefix] == b[prefix]) {
    prefix++;
  }
  var suffix = 0;
  while (suffix < a.length - prefix &&
      suffix < b.length - prefix &&
      a[a.length - 1 - suffix] == b[b.length - 1 - suffix]) {
    suffix++;
  }
  final aMid = a.sublist(prefix, a.length - suffix);
  final bMid = b.sublist(prefix, b.length - suffix);

  final steps = <EditStep>[
    for (var i = 0; i < prefix; i++) EditStep(DiffOperation.equal, i, i),
  ];
  for (final s in _myersCore(aMid, bMid, maxD)) {
    steps.add(EditStep(s.operation, s.aIndex + prefix, s.bIndex + prefix));
  }
  for (var k = 0; k < suffix; k++) {
    steps.add(EditStep(DiffOperation.equal, a.length - suffix + k,
        b.length - suffix + k));
  }
  return steps;
}

List<EditStep> _myersCore<T>(List<T> a, List<T> b, int maxD) {
  final n = a.length;
  final m = b.length;
  if (n == 0 && m == 0) return const [];
  if (n == 0) {
    return [for (var j = 0; j < m; j++) EditStep(DiffOperation.insert, 0, j)];
  }
  if (m == 0) {
    return [for (var i = 0; i < n; i++) EditStep(DiffOperation.delete, i, 0)];
  }

  final max = n + m;
  final offset = max + 1;
  final v = List<int>.filled(2 * max + 3, 0);
  // trace[d] guarda V antes del paso d, solo en el rango k ∈ [-d-1, d+1].
  final trace = <List<int>>[];
  var found = false;

  for (var d = 0; d <= max; d++) {
    if (d > maxD) break;
    trace.add(v.sublist(offset - d - 1, offset + d + 2));
    for (var k = -d; k <= d; k += 2) {
      int x;
      if (k == -d || (k != d && v[offset + k - 1] < v[offset + k + 1])) {
        x = v[offset + k + 1];
      } else {
        x = v[offset + k - 1] + 1;
      }
      var y = x - k;
      while (x < n && y < m && a[x] == b[y]) {
        x++;
        y++;
      }
      v[offset + k] = x;
      if (x >= n && y >= m) {
        found = true;
        break;
      }
    }
    if (found) break;
  }

  if (!found) {
    return [
      for (var i = 0; i < n; i++) EditStep(DiffOperation.delete, i, 0),
      for (var j = 0; j < m; j++) EditStep(DiffOperation.insert, n, j),
    ];
  }

  final reversed = <EditStep>[];
  var x = n;
  var y = m;
  for (var d = trace.length - 1; d >= 0; d--) {
    final slice = trace[d];
    int at(int k) => slice[k + d + 1];
    final k = x - y;
    final int prevK;
    if (k == -d || (k != d && at(k - 1) < at(k + 1))) {
      prevK = k + 1;
    } else {
      prevK = k - 1;
    }
    final prevX = at(prevK);
    final prevY = prevX - prevK;
    while (x > prevX && y > prevY) {
      reversed.add(EditStep(DiffOperation.equal, x - 1, y - 1));
      x--;
      y--;
    }
    if (d > 0) {
      if (x == prevX) {
        reversed.add(EditStep(DiffOperation.insert, x, y - 1));
      } else {
        reversed.add(EditStep(DiffOperation.delete, x - 1, y));
      }
    }
    x = prevX;
    y = prevY;
  }
  return reversed.reversed.toList();
}

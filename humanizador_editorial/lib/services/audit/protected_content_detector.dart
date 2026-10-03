import '../../core/utils/text_utils.dart';
import '../../models/protected_element.dart';

/// Huella de entidades de un texto, usada por la auditoría para comparar
/// original y versión final. Cada lista conserva el orden de aparición.
class EntityFingerprint {
  EntityFingerprint(this.entries);

  /// Tipo → valores normalizados en orden de aparición.
  final Map<ProtectedType, List<String>> entries;

  List<String> of(ProtectedType type) => entries[type] ?? const [];

  int get total => entries.values.fold(0, (a, l) => a + l.length);
}

/// Módulo ProtectedContent: localiza elementos que no deben alterarse.
///
/// Primera versión basada en expresiones regulares (números, porcentajes,
/// fechas, periodos epidemiológicos, intervalos, tasas, unidades, códigos,
/// siglas, citas, referencias, nombres propios, nombres científicos y
/// términos técnicos del dominio). La interfaz [ProtectedContentExtractor]
/// permite añadir después una extracción semántica mediante el modelo.
abstract interface class ProtectedContentExtractor {
  List<ProtectedElement> detect(String text,
      {List<String> technicalTerms, List<String> eventNames});
}

class ProtectedContentDetector implements ProtectedContentExtractor {
  ProtectedContentDetector();

  // ---------------------------------------------------------------------
  // Patrones base
  // ---------------------------------------------------------------------

  /// Número: miles con punto (1.248 / 100.000), miles con coma (1,248.5)
  /// o entero/decimal simple (51.99 / 11,5 / 2026).
  static const String num = r'(?:\d{1,3}(?:\.\d{3})+(?:,\d+)?'
      r'|\d{1,3}(?:,\d{3})+(?:\.\d+)?'
      r'|\d+(?:[.,]\d+)?)';

  static const String _nb = r'(?<![\p{L}\p{N}])';
  static const String _na = r'(?![\p{L}\p{N}])';
  static const String _numAtom = '$_nb$num(?![\\p{N}])(?![.,]\\d)';

  static const String _months = r'(?:enero|febrero|marzo|abril|mayo|junio|'
      r'julio|agosto|septiembre|setiembre|octubre|noviembre|diciembre)';

  static const String _physicalUnits = r'(?:mg/dL|g/dL|mmol/L|U/L|UI/L|'
      r'mg/kg|µg|mcg|mg|kg|g|mL|ml|dL|L|mmHg|°C|ºC|km²|km|cm|mm|m²|m|'
      r'horas|h|minutos|min|segundos|días|semanas|meses|años|UI|ha|'
      r'hectáreas|toneladas|t)';

  static RegExp _re(String pattern, {bool ci = false}) =>
      RegExp(pattern, unicode: true, caseSensitive: !ci);

  static final _reference = [
    // Sin puntuación final ("…/x." → "…/x").
    _re(r'https?://[^\s)\]]*[^\s)\].,;:]'),
    _re(r'(?<![\p{L}\p{N}])10\.\d{4,9}/[^\s)\]]*[^\s)\].,;:]'),
    _re(r'(?:Ley|Decreto|Resoluci[oó]n|Circular(?:\s+Externa)?|Acuerdo|'
        r'Sentencia|Art[ií]culo|Art\.)\s+(?:[A-Z]{1,2}-)?\d+[\w\-]*'
        r'(?:\s+de\s+\d{4})?'),
  ];

  static final _citation = [
    _re(r"\(\p{Lu}[\p{L}'\-]+(?:\s+(?:et al\.?|y|&|e)\s*(?:\p{Lu}[\p{L}\-]+)?)?"
        r',?\s+(?:19|20)\d{2}[a-z]?(?:\s*[;,]\s*[^()]{1,80})?\)'),
    _re(r'\[\d+(?:\s*[-–,]\s*\d+)*\]'),
  ];

  static final _date = [
    _re(r'(?<!\d)\d{4}-\d{2}-\d{2}(?!\d)'),
    _re(r'(?<!\d)\d{1,2}[/-]\d{1,2}[/-]\d{2,4}(?!\d)'),
    _re('(?<!\\d)\\d{1,2}(?:\\s+(?:y|al|a)\\s+(?:el\\s+)?\\d{1,2})?\\s+de\\s+'
        '$_months(?:\\s+(?:de|del)\\s+\\d{4})?$_na', ci: true),
    _re('$_nb$_months\\s+(?:de\\s+)?\\d{4}(?!\\d)', ci: true),
  ];

  static final _epiPeriod = [
    _re(r'(?:semanas?|periodos?|períodos?)\s+epidemiol[oó]gic[oa]s?\s*'
        r'(?:\(\s*(?:SE|PE)\s*\)\s*)?(?:n\.?\s?[º°o]\s*)?'
        r'(?:\d{1,2}|[IVXL]+(?![\p{L}]))'
        r'(?:\s*(?:a|al|y|-|–)\s*(?:\d{1,2}|[IVXL]+(?![\p{L}])))?'
        r'(?:\s+(?:de|del)\s+(?:año\s+)?\d{4})?', ci: true),
    _re(r'(?<![\p{L}])(?:SE|PE)\s?\d{1,2}(?:\s?[-–]\s?\d{1,2})?(?!\d)'
        r'(?:\s+(?:de|del)\s+\d{4})?'),
  ];

  static final _eventCode = [
    _re(r'(?:c[oó]digo|c[oó]d\.)\s*(?:de\s+(?:evento|notificaci[oó]n)\s*)?'
        r'(?:INS\s*)?(?:n\.?\s?[º°o]\s*)?\d{2,12}(?!\d)', ci: true),
    _re(r'(?<![\p{L}])evento\s+(?:n\.?\s?[º°o]\s*)?\d{3}(?!\d)', ci: true),
  ];

  static final _genericCode = [
    // Alfanuméricos con al menos una mayúscula y un dígito: H1N1, A90,
    // J09.X, COVID-19, SARS-CoV-2, IC95.
    _re(r'(?<![\p{L}\p{N}])(?=[A-Za-z0-9\-.]*\d)(?=[A-Za-z0-9\-.]*[A-Z])'
        r'[A-Za-z0-9]+(?:[-.][A-Za-z0-9]+)*(?![\p{L}\p{N}])'),
    // Secuencias numéricas largas sin separadores (códigos UPGD, radicados).
    _re(r'(?<![\p{N}.,])\d{7,}(?![\p{N}])'),
  ];

  static final _rate = _re(
      '$_nb$num(?:\\s*%)?\\s+(?:[\\p{L}]+\\s+){0,3}?por\\s+(?:cada\\s+)?'
      '$num\\s+[\\p{L}]+(?:\\s+vivos)?',
      ci: true);

  static final _range = [
    _re('IC\\s?\\d{2}\\s?%\\s*:?\\s*\\(?$num\\s*[–—;,-]\\s*$num\\)?'),
    _re('entre\\s+(?:el\\s+)?$num\\s*%?\\s+y\\s+(?:el\\s+)?$num\\s*%?',
        ci: true),
    _re('$_nb$num\\s*%?\\s*[–—]\\s*$num\\s*%?(?![\\p{N}])'),
  ];

  static final _percentage = [
    _re('$_nb$num\\s?%'),
    _re('$_nb$num\\s+por\\s+ciento', ci: true),
  ];

  static final _measurement =
      _re('$_nb$num\\s?$_physicalUnits(?![\\p{L}])');

  static final _ratio = _re('$_nb$num\\s?:\\s?$num(?![\\p{N}])');

  static final _formula = _re(r'(?<![\p{L}])[\p{L}][\p{L}\d_]*\s*=\s*'
      r'[^=\n;]*?[/×*÷][^=\n;]*?(?=;|\n|\.\s|\.$|$)');

  static const String _genera = r'(?:Aedes|Anopheles|Culex|Lutzomyia|'
      r'Plasmodium|Mycobacterium|Salmonella|Shigella|Vibrio|Leptospira|'
      r'Leishmania|Trypanosoma|Escherichia|Neisseria|Streptococcus|'
      r'Staphylococcus|Bordetella|Clostridium|Clostridioides|Rickettsia|'
      r'Treponema|Haemophilus|Listeria|Toxoplasma|Giardia|Cryptosporidium|'
      r'Candida|Klebsiella|Pseudomonas|Acinetobacter|Enterococcus|'
      r'Campylobacter|Brucella|Corynebacterium|Rattus|Triatoma|Rhodnius)';

  static final _scientific = [
    _re('$_genera\\s+(?:[a-z]{3,}|spp?\\.)'),
    _re(r'(?<![\p{L}])(?:Ae|An|Cx|P|M|S|E|V|L|T|K|N|C)\.\s?'
        r'(?:aegypti|albopictus|falciparum|vivax|tuberculosis|aureus|coli|'
        r'cholerae|interrogans|pneumoniae|meningitidis|pertussis|difficile|'
        r'cruzi|typhi|enterica|trachomatis|gonorrhoeae|monocytogenes)'),
  ];

  static const String _institutionHeads = r'(?:Instituto|Ministerio|'
      r'Secretar[ií]a|Superintendencia|Hospital|Cl[ií]nica|Universidad|'
      r'Alcald[ií]a|Gobernaci[oó]n|Organizaci[oó]n|Laboratorio|'
      r'Fundaci[oó]n|Departamento|Direcci[oó]n|Subdirecci[oó]n|Oficina|'
      r'Centro|Empresa\s+Social|Corporaci[oó]n|Agencia|Comit[eé])';

  static final _institution = _re('$_institutionHeads'
      r'(?:\s+(?:(?:de|del|la|las|los|el|y|para)\s+)?\p{Lu}[\p{L}\-]+)+');

  static final _properNameMulti = _re(r'\p{Lu}\p{Ll}+'
      r'(?:\s+(?:(?:de|del|la|las|los|el|y)\s+)?\p{Lu}\p{Ll}+)+');

  /// Palabra capitalizada en mitad de oración (no tras punto).
  static final _properNameSingle =
      _re(r'(?:(?<=[\p{Ll}\p{N},;:)]\s)|(?<=\())\p{Lu}\p{Ll}{2,}');

  static final _acronym = _re(
      r'(?<![\p{L}\p{N}])\p{Lu}{2,}(?:[\p{Lu}\d]){0,8}(?![\p{L}\p{N}])');

  static final _numberAtom = _re(_numAtom);

  /// Palabras que, aun capitalizadas, no son nombres propios.
  static const Set<String> _capitalizedStopwords = {
    'El', 'La', 'Los', 'Las', 'Un', 'Una', 'De', 'Del', 'En', 'Con', 'Por',
    'Para', 'Se', 'Además', 'Sin', 'Este', 'Esta', 'Estos', 'Estas', 'Que',
    'Cabe', 'Es', 'Asimismo', 'También', 'No', 'Al', 'Lo',
  };

  // ---------------------------------------------------------------------
  // API pública
  // ---------------------------------------------------------------------

  /// Detecta elementos protegidos sin solapamiento, ordenados por posición.
  @override
  List<ProtectedElement> detect(
    String text, {
    List<String> technicalTerms = const [],
    List<String> eventNames = const [],
  }) {
    final candidates = <_Candidate>[];
    void addAll(Iterable<RegExp> patterns, ProtectedType type, int priority) {
      for (final p in patterns) {
        for (final m in p.allMatches(text)) {
          final value = m.group(0)!;
          if (value.trim().isEmpty) continue;
          candidates.add(_Candidate(m.start, m.end, type, priority));
        }
      }
    }

    addAll(_reference, ProtectedType.reference, 1);
    addAll(_citation, ProtectedType.citation, 2);
    addAll(_date, ProtectedType.date, 3);
    addAll(_epiPeriod, ProtectedType.epidemiologicalPeriod, 4);
    addAll(_eventCode, ProtectedType.code, 5);
    addAll([_rate], ProtectedType.rate, 6);
    addAll(_range, ProtectedType.range, 7);
    addAll(_percentage, ProtectedType.percentage, 8);
    addAll([_measurement], ProtectedType.measurement, 9);
    addAll([_ratio], ProtectedType.ratio, 10);
    addAll([_formula], ProtectedType.formula, 11);
    addAll(_genericCode, ProtectedType.code, 12);
    addAll(_scientific, ProtectedType.scientificName, 13);
    addAll([_institution], ProtectedType.institution, 14);
    addAll(_termPatterns(eventNames), ProtectedType.eventName, 15);
    addAll(_termPatterns(technicalTerms), ProtectedType.technicalTerm, 16);
    addAll([_acronym], ProtectedType.acronym, 17);
    for (final (start, end) in _properNames(text)) {
      candidates.add(_Candidate(start, end, ProtectedType.properName, 18));
    }
    for (final m in _properNameSingle.allMatches(text)) {
      if (_capitalizedStopwords.contains(m.group(0))) continue;
      candidates.add(_Candidate(m.start, m.end, ProtectedType.properName, 19));
    }
    addAll([_numberAtom], ProtectedType.number, 20);

    candidates.sort((a, b) {
      final byStart = a.start.compareTo(b.start);
      if (byStart != 0) return byStart;
      final byLength = (b.end - b.start).compareTo(a.end - a.start);
      if (byLength != 0) return byLength;
      return a.priority.compareTo(b.priority);
    });

    final selected = <ProtectedElement>[];
    var lastEnd = -1;
    for (final c in candidates) {
      if (c.start < lastEnd) continue;
      final raw = text.substring(c.start, c.end);
      final trimmed = raw.trimRight();
      selected.add(ProtectedElement(
        value: trimmed,
        type: c.type,
        start: c.start,
        end: c.start + trimmed.length,
      ));
      lastEnd = c.end;
    }
    return selected;
  }

  /// Huella para auditoría. A diferencia de [detect], separa entidades
  /// "contenedoras" (fechas, periodos, códigos, citas, referencias) de los
  /// átomos numéricos para que un mismo dato no genere alertas duplicadas.
  EntityFingerprint fingerprint(
    String text, {
    List<String> technicalTerms = const [],
    List<String> eventNames = const [],
  }) {
    final map = <ProtectedType, List<String>>{};
    void put(ProtectedType t, String v) =>
        (map[t] ??= <String>[]).add(normalizeValue(t, v));

    // 1. Contenedores sin solapamiento.
    final containers = <_Candidate>[];
    void collect(Iterable<RegExp> ps, ProtectedType t, int prio) {
      for (final p in ps) {
        for (final m in p.allMatches(text)) {
          containers.add(_Candidate(m.start, m.end, t, prio));
        }
      }
    }

    collect(_reference, ProtectedType.reference, 1);
    collect(_citation, ProtectedType.citation, 2);
    collect(_date, ProtectedType.date, 3);
    collect(_epiPeriod, ProtectedType.epidemiologicalPeriod, 4);
    collect(_eventCode, ProtectedType.code, 5);
    collect(_genericCode, ProtectedType.code, 6);
    containers.sort((a, b) {
      final s = a.start.compareTo(b.start);
      if (s != 0) return s;
      return (b.end - b.start).compareTo(a.end - a.start);
    });
    final masked = StringBuffer();
    var cursor = 0;
    var lastEnd = -1;
    for (final c in containers) {
      if (c.start < lastEnd) continue;
      put(c.type, text.substring(c.start, c.end));
      masked.write(text.substring(cursor, c.start));
      masked.write(' ' * (c.end - c.start));
      cursor = c.end;
      lastEnd = c.end;
    }
    masked.write(text.substring(cursor));
    var rest = masked.toString();

    // 2. Porcentajes, luego números sueltos.
    for (final p in _percentage) {
      rest = rest.replaceAllMapped(p, (m) {
        put(ProtectedType.percentage, m.group(0)!);
        return ' ' * m.group(0)!.length;
      });
    }
    for (final m in _numberAtom.allMatches(rest)) {
      put(ProtectedType.number, m.group(0)!);
    }

    // 3. Cifras con unidad física (para detectar cambios de unidad).
    for (final m in _measurement.allMatches(text)) {
      put(ProtectedType.measurement, m.group(0)!);
    }

    // 4. Elementos léxicos (pueden solaparse con lo anterior).
    for (final m in _acronym.allMatches(text)) {
      put(ProtectedType.acronym, m.group(0)!);
    }
    for (final p in _scientific) {
      for (final m in p.allMatches(text)) {
        put(ProtectedType.scientificName, m.group(0)!);
      }
    }
    for (final m in _institution.allMatches(text)) {
      put(ProtectedType.institution, m.group(0)!);
    }
    for (final p in _termPatterns(eventNames)) {
      for (final m in p.allMatches(text)) {
        put(ProtectedType.eventName, m.group(0)!);
      }
    }
    for (final p in _termPatterns(technicalTerms)) {
      for (final m in p.allMatches(text)) {
        put(ProtectedType.technicalTerm, m.group(0)!);
      }
    }
    for (final (start, end) in _properNames(text)) {
      put(ProtectedType.properName, text.substring(start, end));
    }
    return EntityFingerprint(map);
  }

  /// Normalización mínima para comparar: espacios colapsados; en fechas,
  /// periodos y términos se ignoran mayúsculas; en porcentajes se ignora el
  /// espacio previo a "%". Las cifras se comparan literalmente.
  static String normalizeValue(ProtectedType type, String value) {
    final v = TextUtils.normalizeSpaces(value);
    return switch (type) {
      ProtectedType.date ||
      ProtectedType.epidemiologicalPeriod ||
      ProtectedType.technicalTerm ||
      ProtectedType.eventName =>
        TextUtils.fold(v).replaceAll(RegExp(r'(?<=\p{L})(?:es|s)$',
            unicode: true), ''),
      ProtectedType.percentage => v.replaceAll(' ', ''),
      _ => v,
    };
  }

  /// Valor numérico interpretado (para distinguir cambio de formato de
  /// cambio de valor). Devuelve null si es ambiguo.
  static double? numericValue(String raw) {
    var s = raw.replaceAll(RegExp(r'[^\d.,]'), '');
    if (s.isEmpty) return null;
    if (RegExp(r'^\d{1,3}(\.\d{3})+(,\d+)?$').hasMatch(s)) {
      s = s.replaceAll('.', '').replaceAll(',', '.');
    } else if (RegExp(r'^\d{1,3}(,\d{3})+(\.\d+)?$').hasMatch(s)) {
      s = s.replaceAll(',', '');
    } else {
      s = s.replaceAll(',', '.');
    }
    return double.tryParse(s);
  }

  /// Secuencias de palabras capitalizadas, sin el artículo o conector
  /// inicial ("El Instituto Nacional" → "Instituto Nacional").
  Iterable<(int, int)> _properNames(String text) sync* {
    for (final m in _properNameMulti.allMatches(text)) {
      var start = m.start;
      final value = m.group(0)!;
      final first = RegExp(r'^\S+\s+').firstMatch(value);
      if (first != null &&
          _capitalizedStopwords.contains(first.group(0)!.trim())) {
        start += first.end;
      }
      final rest = text.substring(start, m.end);
      if (!rest.contains(RegExp(r'\s'))) continue; // quedó una sola palabra
      yield (start, m.end);
    }
  }

  final Map<String, List<RegExp>> _termCache = {};

  List<RegExp> _termPatterns(List<String> terms) {
    if (terms.isEmpty) return const [];
    final key = terms.join('|');
    return _termCache.putIfAbsent(key, () {
      final lexical = terms.where((t) => t != t.toUpperCase()).toList()
        ..sort((a, b) => b.length.compareTo(a.length));
      if (lexical.isEmpty) return const [];
      final alternation = lexical.map(RegExp.escape).join('|');
      return [
        _re('(?<![\\p{L}\\p{N}])(?:$alternation)(?:es|s)?(?![\\p{L}\\p{N}])',
            ci: true),
      ];
    });
  }
}

class _Candidate {
  _Candidate(this.start, this.end, this.type, this.priority);
  final int start;
  final int end;
  final ProtectedType type;
  final int priority;
}

/// ANONIMIZACIÓN — arquitectura preparada (prevista para v1.1).
///
/// Módulo independiente de la humanización: detecta datos personales y los
/// reemplaza temporalmente por marcadores reversibles. En esta versión NO se
/// integra al flujo principal; solo existe la interfaz y un detector por
/// reglas, probado de forma aislada.
library;

enum SensitiveType {
  email('Correo electrónico'),
  phone('Teléfono'),
  documentId('Documento de identidad'),
  clinicalRecord('Historia clínica'),
  coordinates('Coordenadas'),
  address('Dirección'),
  personName('Nombre de persona');

  const SensitiveType(this.label);
  final String label;
}

class SensitiveMatch {
  const SensitiveMatch(this.type, this.value, this.start, this.end);
  final SensitiveType type;
  final String value;
  final int start;
  final int end;
}

/// Texto anonimizado + mapa para revertir los marcadores.
class AnonymizedText {
  const AnonymizedText(this.text, this.placeholders);
  final String text;

  /// Marcador → valor original. Solo vive en memoria; nunca se envía.
  final Map<String, String> placeholders;

  String restore(String processed) {
    var out = processed;
    placeholders.forEach((marker, value) {
      out = out.replaceAll(marker, value);
    });
    return out;
  }
}

abstract interface class AnonymizerService {
  List<SensitiveMatch> detect(String text);
  AnonymizedText anonymize(String text);
}

/// Detector por reglas (Colombia). Los nombres de personas requieren
/// extracción semántica y quedan fuera de esta primera aproximación.
class RuleBasedAnonymizer implements AnonymizerService {
  const RuleBasedAnonymizer();

  static final Map<SensitiveType, RegExp> _patterns = {
    SensitiveType.email:
        RegExp(r'[\w.+\-]+@[\w\-]+\.[\w.\-]+', unicode: true),
    SensitiveType.clinicalRecord: RegExp(
        r'(?:historia\s+cl[ií]nica|HC)\s*(?:n\.?\s?[º°o]\s*|:\s*)?\d{5,12}',
        caseSensitive: false),
    SensitiveType.documentId: RegExp(
        r'(?:C\.?\s?C\.?|T\.?\s?I\.?|C\.?\s?E\.?|R\.?\s?C\.?|c[ée]dula|'
        r'documento)\s*(?:n\.?\s?[º°o]\s*|:\s*)?\d{1,3}(?:\.?\d{3}){1,3}',
        caseSensitive: false),
    SensitiveType.phone: RegExp(
        r'(?<!\d)(?:\+57\s?)?(?:3\d{2}[\s\-]?\d{3}[\s\-]?\d{4}|'
        r'60\d[\s\-]?\d{3}[\s\-]?\d{4})(?!\d)'),
    SensitiveType.coordinates: RegExp(
        r'-?\d{1,2}\.\d{4,}\s*,\s*-?\d{1,3}\.\d{4,}'),
    SensitiveType.address: RegExp(
        r'(?:Calle|Carrera|Cra\.?|Cl\.?|Avenida|Av\.?|Diagonal|Transversal|'
        r'Kr)\s*\d+[A-Z]?\s*(?:#|No\.?|N°)\s*\d+[A-Z]?\s*-\s*\d+',
        caseSensitive: false),
  };

  @override
  List<SensitiveMatch> detect(String text) {
    final all = <SensitiveMatch>[];
    _patterns.forEach((type, re) {
      for (final m in re.allMatches(text)) {
        all.add(SensitiveMatch(type, m.group(0)!, m.start, m.end));
      }
    });
    all.sort((a, b) => a.start.compareTo(b.start));
    final result = <SensitiveMatch>[];
    var lastEnd = -1;
    for (final m in all) {
      if (m.start >= lastEnd) {
        result.add(m);
        lastEnd = m.end;
      }
    }
    return result;
  }

  @override
  AnonymizedText anonymize(String text) {
    final matches = detect(text);
    final map = <String, String>{};
    final b = StringBuffer();
    var cursor = 0;
    final counters = <SensitiveType, int>{};
    for (final m in matches) {
      final n = (counters[m.type] ?? 0) + 1;
      counters[m.type] = n;
      final marker = '[${m.type.name.toUpperCase()}_$n]';
      map[marker] = m.value;
      b.write(text.substring(cursor, m.start));
      b.write(marker);
      cursor = m.end;
    }
    b.write(text.substring(cursor));
    return AnonymizedText(b.toString(), map);
  }
}

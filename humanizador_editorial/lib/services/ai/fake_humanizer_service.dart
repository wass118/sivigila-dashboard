import '../../core/utils/text_utils.dart';
import '../../models/humanization_result.dart';
import '../../models/protected_element.dart';
import '../../models/text_analysis.dart';
import '../analysis/local_text_analyzer.dart';
import 'humanizer_service.dart';

/// Servicio SIMULADO para usar la aplicación sin proveedor de IA.
///
/// No usa ningún modelo: aplica reglas locales deterministas y documentadas
/// (eliminar fórmulas vacías, sustituir perífrasis por verbos plenos, variar
/// conectores repetidos). Todo resultado se marca como demostración y
/// "Qué mejoró" describe exactamente las reglas aplicadas. Nunca toca los
/// elementos protegidos.
class FakeHumanizerService implements HumanizerService {
  FakeHumanizerService({
    required this.analyzer,
    this.latency = const Duration(milliseconds: 500),
  });

  final LocalTextAnalyzer analyzer;
  final Duration latency;

  static const String demoNotice = '[DEMOSTRACIÓN] Resultado generado con '
      'reglas locales, no por un modelo de IA.';

  @override
  ProviderDescriptor get descriptor => const ProviderDescriptor(
      label: 'Demostración local (sin IA)', isRemote: false, isDemo: true);

  @override
  Future<TextAnalysis> analyze(AnalysisInput input) async {
    await Future<void>.delayed(latency);
    final analysis = analyzer.toTextAnalysis(input.local,
        audienceLabel: input.context.audience.label, isDemo: true);
    return TextAnalysis(
      detectedDomain: analysis.detectedDomain,
      detectedAudience: analysis.detectedAudience,
      detectedTone: analysis.detectedTone,
      technicalLevel: analysis.technicalLevel,
      formality: analysis.formality,
      purpose: analysis.purpose,
      problems: analysis.problems,
      observations: [demoNotice, ...analysis.observations],
      isDemo: true,
    );
  }

  @override
  Future<HumanizationResult> humanize(HumanizationInput input) async {
    await Future<void>.delayed(latency);
    final local = analyzer.analyze(input.text);
    final analysis = analyzer.toTextAnalysis(local,
        audienceLabel: input.context.audience.label, isDemo: true);
    final recommendations = analyzer.recommendationsFrom(local);

    if (!input.context.intensity.producesRewrite) {
      return HumanizationResult(
        analysis: analysis,
        rewrittenText: null,
        recommendations: recommendations,
        protectedElements: input.protectedElements,
        improvements: const [demoNotice],
        isDemo: true,
        providerLabel: descriptor.label,
      );
    }

    final (text, applied) = DemoRewriteRules.apply(
        input.text, input.protectedElements, input.context.intensity.index);
    return HumanizationResult(
      analysis: analysis,
      rewrittenText: text,
      recommendations: recommendations,
      protectedElements: input.protectedElements,
      improvements: [
        demoNotice,
        if (applied.isEmpty)
          'Las reglas de demostración no encontraron fórmulas que ajustar.',
        ...applied,
      ],
      isDemo: true,
      providerLabel: descriptor.label,
    );
  }

  @override
  Future<HumanizationResult> rewriteFragment(FragmentInput input) async {
    await Future<void>.delayed(latency);
    // Reglas de máxima intensidad sobre el párrafo indicado.
    final (text, applied) =
        DemoRewriteRules.apply(input.fragment, input.protectedElements, 2);
    return HumanizationResult(
      analysis: const TextAnalysis(detectedDomain: '', detectedAudience: '',
          detectedTone: '', technicalLevel: '', isDemo: true),
      rewrittenText: text,
      improvements: [
        demoNotice,
        if (applied.isEmpty) 'Sin cambios aplicables por las reglas demo.',
        ...applied,
      ],
      isDemo: true,
      providerLabel: descriptor.label,
    );
  }
}

/// Reglas de reescritura de la demostración. `level`: 0 conservadora,
/// 1 moderada, 2 profunda.
abstract final class DemoRewriteRules {
  static final List<_Rule> _rules = [
    _Rule(0, r'se llevaron a cabo', 'se realizaron',
        '"se llevaron a cabo" → "se realizaron"'),
    _Rule(0, r'se llevó a cabo', 'se realizó',
        '"se llevó a cabo" → "se realizó"'),
    _Rule(0, r'llevar a cabo', 'realizar', '"llevar a cabo" → "realizar"'),
    _Rule(0, r'con el fin de', 'para', '"con el fin de" → "para"'),
    _Rule(0, r'volver a repetir', 'repetir', 'Redundancia "volver a repetir"'),
    _Rule(0, r'un total de\s+', '', 'Se suprimió "un total de"'),
    _Rule(1, r'(?:es importante (?:destacar|mencionar|resaltar|señalar)|'
        r'cabe (?:mencionar|destacar|resaltar|señalar)) que,?\s*', '',
        'Se suprimió una fórmula genérica ("es importante destacar que", '
            '"cabe mencionar que"...)'),
    _Rule(1, r'en lo que respecta a', 'respecto a',
        '"en lo que respecta a" → "respecto a"'),
    _Rule(1, r'se realizó la verificación de', 'se verificó',
        '"se realizó la verificación de" → "se verificó"'),
    _Rule(1, r'por medio de la presente', 'mediante esta comunicación',
        '"por medio de la presente" → "mediante esta comunicación"'),
    _Rule(2, r'en la actualidad', 'actualmente',
        '"en la actualidad" → "actualmente"'),
    _Rule(2, r'debido al hecho de que', 'porque',
        '"debido al hecho de que" → "porque"'),
    _Rule(2, r'dicho evento', 'este evento', '"dicho evento" → "este evento"'),
  ];

  static const String _capMark = '\u0001';

  static (String, List<String>) apply(
      String text, List<ProtectedElement> protectedElements, int level) {
    final applied = <String, int>{};

    // 1. Enmascarar elementos protegidos con marcadores de uso privado para
    //    que ninguna regla pueda alterarlos.
    final spans = protectedElements
        .where((p) => p.start >= 0 && p.end <= text.length)
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    final originals = <String>[];
    final masked = StringBuffer();
    var cursor = 0;
    for (final p in spans) {
      if (p.start < cursor) continue;
      masked.write(text.substring(cursor, p.start));
      masked.write('\uE000${originals.length}\uE001');
      originals.add(text.substring(p.start, p.end));
      cursor = p.end;
    }
    masked.write(text.substring(cursor));

    // 2. Reglas sobre el texto enmascarado.
    var s = masked.toString();
    for (final rule in _rules) {
      if (rule.level > level) continue;
      s = s.replaceAllMapped(rule.pattern, (m) {
        applied[rule.description] = (applied[rule.description] ?? 0) + 1;
        final before = s.substring(0, m.start);
        final atSentenceStart = RegExp(r'(^|[.!?:]\s*|\n\s*)$').hasMatch(before);
        if (rule.replacement.isEmpty) return atSentenceStart ? _capMark : '';
        return atSentenceStart
            ? TextUtils.capitalizeFirst(rule.replacement)
            : rule.replacement;
      });
    }
    s = _varyRepeatedConnectors(s, level, applied);

    // 3. Mayúscula tras suprimir una fórmula al inicio de oración.
    s = s.replaceAllMapped(RegExp('$_capMark(\\p{Ll})', unicode: true),
        (m) => m.group(1)!.toUpperCase());
    s = s.replaceAll(_capMark, '').replaceAll(RegExp(r'[ \t]{2,}'), ' ');

    // 4. Restaurar elementos protegidos literalmente.
    s = s.replaceAllMapped(RegExp('\uE000(\\d+)\uE001'),
        (m) => originals[int.parse(m.group(1)!)]);

    final descriptions = applied.entries
        .map((e) => e.value > 1 ? '${e.key} (${e.value} veces)' : e.key)
        .toList();
    return (s, descriptions);
  }

  /// "Además, ... Además, ..." → "Además, ... Asimismo, ..." (moderada+).
  static String _varyRepeatedConnectors(
      String text, int level, Map<String, int> applied) {
    if (level < 1) return text;
    const alternatives = ['Asimismo,', 'También'];
    var seen = 0;
    return text.replaceAllMapped(
        RegExp(r'(?<=^|[.!?]\s|\n)Además,', multiLine: true), (m) {
      seen++;
      if (seen == 1) return m.group(0)!;
      const key = 'Se varió el conector repetido "Además"';
      applied[key] = (applied[key] ?? 0) + 1;
      return alternatives[(seen - 2) % alternatives.length];
    });
  }
}

class _Rule {
  _Rule(this.level, String pattern, this.replacement, this.description)
      : pattern = RegExp(pattern, caseSensitive: false, unicode: true);

  final int level;
  final RegExp pattern;
  final String replacement;
  final String description;
}

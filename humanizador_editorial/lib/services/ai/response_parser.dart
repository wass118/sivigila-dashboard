import '../../core/errors/humanizer_failure.dart';
import '../../core/utils/json_sanitizer.dart';
import '../../models/fidelity_warning.dart';
import '../../models/humanization_result.dart';
import '../../models/protected_element.dart';
import '../../models/recommendation.dart';
import '../../models/text_analysis.dart';

/// Valida y convierte la respuesta del modelo en modelos tipados.
///
/// Es tolerante con variaciones menores (listas ausentes, cadenas en lugar
/// de objetos) y estricto con lo esencial: un objeto JSON y, cuando se pidió
/// reescritura, un `rewrittenText` no vacío. Ante incumplimiento lanza
/// [InvalidResponseFailure]; nunca deja escapar otro tipo de excepción.
class ResponseParser {
  const ResponseParser();

  TextAnalysis parseAnalysis(String raw) {
    final json = _decode(raw);
    final node = json['analysis'] is Map
        ? (json['analysis'] as Map).cast<String, dynamic>()
        : json;
    if (!node.containsKey('dominioDetectado') &&
        !node.containsKey('problemas')) {
      throw const InvalidResponseFailure(
          'El diagnóstico no contiene los campos esperados.',
          technicalDetail: 'faltan dominioDetectado/problemas');
    }
    return _safe(() => TextAnalysis.fromJson(node));
  }

  HumanizationResult parseHumanization(String raw,
      {required bool expectRewrite, String providerLabel = ''}) {
    final json = _decode(raw);
    final rewritten = json['rewrittenText'];
    String? text;
    if (rewritten is String && rewritten.trim().isNotEmpty) {
      text = rewritten.trim();
    }
    if (expectRewrite && text == null) {
      throw const InvalidResponseFailure(
          'La respuesta no incluye el texto reescrito.',
          technicalDetail: 'rewrittenText ausente o vacío');
    }
    return _safe(() {
      final analysisNode = json['analysis'];
      final analysis = analysisNode is Map
          ? TextAnalysis.fromJson(analysisNode.cast<String, dynamic>())
          : const TextAnalysis(
              detectedDomain: '',
              detectedAudience: '',
              detectedTone: '',
              technicalLevel: '');
      return HumanizationResult(
        analysis: analysis,
        rewrittenText: expectRewrite ? text : null,
        recommendations: _list(json['recommendations'], (e) {
          if (e is Map) {
            return Recommendation.fromJson(e.cast<String, dynamic>());
          }
          return Recommendation(
              category: RecommendationCategory.clarity,
              problem: e.toString(),
              suggestion: '');
        }),
        fidelityWarnings: parseWarnings(json['fidelityWarnings']),
        protectedElements: _list(json['protectedElements'], (e) {
          if (e is Map) {
            return ProtectedElement.fromJson(e.cast<String, dynamic>());
          }
          return ProtectedElement(
              value: e.toString(),
              type: ProtectedType.technicalTerm,
              source: DetectionSource.model);
        }),
        improvements: _list(json['improvements'], (e) => e.toString()),
        providerLabel: providerLabel,
      );
    });
  }

  /// Fragmento regenerado: devuelve un resultado con el texto del párrafo.
  HumanizationResult parseFragment(String raw, {String providerLabel = ''}) {
    final json = _decode(raw);
    final text = json['rewrittenText'];
    if (text is! String || text.trim().isEmpty) {
      throw const InvalidResponseFailure(
          'La respuesta no incluye el párrafo regenerado.');
    }
    return HumanizationResult(
      analysis: const TextAnalysis(detectedDomain: '', detectedAudience: '',
          detectedTone: '', technicalLevel: ''),
      rewrittenText: text.trim(),
      fidelityWarnings: parseWarnings(json['fidelityWarnings']),
      improvements: _list(json['improvements'], (e) => e.toString()),
      providerLabel: providerLabel,
    );
  }

  List<FidelityWarning> parseWarnings(Object? raw) => _list(raw, (e) {
        if (e is Map) {
          return FidelityWarning.fromJson(e.cast<String, dynamic>());
        }
        return FidelityWarning(
            category: 'Revisión',
            message: e.toString(),
            severity: WarningSeverity.medium,
            origin: WarningOrigin.model);
      });

  Map<String, dynamic> _decode(String raw) {
    if (raw.trim().isEmpty) {
      throw const InvalidResponseFailure('El modelo devolvió una respuesta '
          'vacía.');
    }
    final json = JsonSanitizer.tryDecodeObject(raw);
    if (json == null) {
      throw InvalidResponseFailure(
          'El modelo devolvió un JSON mal formado.',
          technicalDetail: 'longitud=${raw.length}');
    }
    return json;
  }

  static List<T> _list<T>(Object? raw, T Function(Object e) map) {
    if (raw is! List) return const [];
    final out = <T>[];
    for (final e in raw) {
      if (e == null) continue;
      try {
        out.add(map(e));
      } catch (_) {
        // Elemento individual inválido: se descarta sin invalidar el resto.
      }
    }
    return out;
  }

  static T _safe<T>(T Function() build) {
    try {
      return build();
    } on HumanizerFailure {
      rethrow;
    } catch (e) {
      throw InvalidResponseFailure(
          'La estructura del JSON no coincide con el formato esperado.',
          technicalDetail: e.runtimeType.toString());
    }
  }
}

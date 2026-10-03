import 'fidelity_warning.dart';
import 'protected_element.dart';
import 'recommendation.dart';
import 'text_analysis.dart';

/// Resultado estructurado de una operación de humanización.
///
/// Corresponde al contrato JSON pedido al modelo: `analysis`,
/// `rewrittenText`, `recommendations`, `fidelityWarnings`,
/// `protectedElements` y `improvements` ("Qué mejoró").
class HumanizationResult {
  const HumanizationResult({
    required this.analysis,
    required this.rewrittenText,
    this.recommendations = const [],
    this.fidelityWarnings = const [],
    this.protectedElements = const [],
    this.improvements = const [],
    this.isDemo = false,
    this.providerLabel = '',
  });

  final TextAnalysis analysis;

  /// Texto completo generado. `null` en modo "Solo recomendaciones".
  final String? rewrittenText;
  final List<Recommendation> recommendations;

  /// Alertas reportadas por el modelo (la auditoría local añade las suyas).
  final List<FidelityWarning> fidelityWarnings;
  final List<ProtectedElement> protectedElements;

  /// Principales cambios editoriales explicados ("Qué mejoró").
  final List<String> improvements;

  /// Verdadero si lo generó el servicio de demostración.
  final bool isDemo;
  final String providerLabel;

  bool get hasRewrite => rewrittenText != null && rewrittenText!.isNotEmpty;

  HumanizationResult copyWith({
    TextAnalysis? analysis,
    String? rewrittenText,
    List<Recommendation>? recommendations,
    List<FidelityWarning>? fidelityWarnings,
    List<ProtectedElement>? protectedElements,
    List<String>? improvements,
    bool? isDemo,
    String? providerLabel,
  }) =>
      HumanizationResult(
        analysis: analysis ?? this.analysis,
        rewrittenText: rewrittenText ?? this.rewrittenText,
        recommendations: recommendations ?? this.recommendations,
        fidelityWarnings: fidelityWarnings ?? this.fidelityWarnings,
        protectedElements: protectedElements ?? this.protectedElements,
        improvements: improvements ?? this.improvements,
        isDemo: isDemo ?? this.isDemo,
        providerLabel: providerLabel ?? this.providerLabel,
      );

  Map<String, dynamic> toJson() => {
        'analysis': analysis.toJson(),
        'rewrittenText': rewrittenText,
        'recommendations': recommendations.map((r) => r.toJson()).toList(),
        'fidelityWarnings': fidelityWarnings.map((w) => w.toJson()).toList(),
        'protectedElements': protectedElements.map((p) => p.toJson()).toList(),
        'improvements': improvements,
        'demo': isDemo,
        'provider': providerLabel,
      };
}

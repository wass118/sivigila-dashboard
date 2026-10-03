import '../../models/pipeline_models.dart';
import '../../models/recommendation.dart';

/// Construye los textos que se copian al portapapeles.
abstract final class ReportExport {
  static String recommendations(List<Recommendation> items) {
    if (items.isEmpty) return 'Sin recomendaciones.';
    final b = StringBuffer('RECOMENDACIONES EDITORIALES\n');
    for (final r in items) {
      b.writeln('- ${r.toPlainText()}');
    }
    return b.toString();
  }

  static String fullAnalysis({
    required AnalysisOutcome? analysis,
    required PipelineOutput? output,
  }) {
    final b = StringBuffer();
    final demo = (output?.result.isDemo ?? false) ||
        (analysis?.analysis.isDemo ?? false);
    if (demo) {
      b.writeln('[DEMOSTRACIÓN] Resultado de reglas locales, no de un modelo '
          'de IA.\n');
    }
    if (analysis != null) {
      b.writeln(analysis.analysis.toPlainText());
      b.writeln('Elementos protegidos: ${analysis.protectedElements.length}');
      b.writeln();
    }
    if (output != null) {
      if (output.result.improvements.isNotEmpty) {
        b.writeln('QUÉ MEJORÓ');
        for (final i in output.result.improvements) {
          b.writeln('- $i');
        }
        b.writeln();
      }
      b.writeln(output.audit.toPlainText());
      b.writeln();
      b.writeln(recommendations(output.result.recommendations));
      if (output.result.rewrittenText != null) {
        b
          ..writeln()
          ..writeln('TEXTO RESULTANTE')
          ..writeln(output.result.rewrittenText);
      }
    }
    return b.toString();
  }
}

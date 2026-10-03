import 'audit_report.dart';
import 'domain_profile.dart';
import 'editorial_index.dart';
import 'humanization_result.dart';
import 'protected_element.dart';
import 'text_analysis.dart';

/// Fases lógicas del proceso.
enum PipelinePhase {
  analysis('Análisis'),
  protection('Protección de contenido'),
  rewriting('Reescritura'),
  audit('Auditoría de fidelidad');

  const PipelinePhase(this.label);
  final String label;
}

enum PhaseStatus { pending, running, done, skipped, failed }

class PhaseState {
  const PhaseState(this.status, [this.summary = '']);
  final PhaseStatus status;
  final String summary;

  static const pending = PhaseState(PhaseStatus.pending);
}

typedef PhaseCallback = void Function(PipelinePhase phase, PhaseState state);

/// Hallazgos del analizador local (heurísticas deterministas).
class LocalAnalysisReport {
  const LocalAnalysisReport({
    required this.detectedDomainId,
    required this.domainConfidence,
    required this.formality,
    required this.purpose,
    required this.estimatedAudienceId,
    required this.issues,
    required this.index,
  });

  final String detectedDomainId;

  /// 0–1, proporción de la puntuación del dominio ganador.
  final double domainConfidence;
  final String formality;
  final String purpose;
  final String estimatedAudienceId;
  final List<EditorialIssue> issues;
  final EditorialIndex index;
}

/// Salida de las fases 1 y 2.
class AnalysisOutcome {
  const AnalysisOutcome({
    required this.analyzedText,
    required this.analysis,
    required this.local,
    required this.protectedElements,
    required this.effectiveDomain,
    required this.segmentCount,
  });

  /// Texto exacto analizado (permite detectar si el usuario lo editó).
  final String analyzedText;
  final TextAnalysis analysis;
  final LocalAnalysisReport local;
  final List<ProtectedElement> protectedElements;
  final DomainProfile effectiveDomain;
  final int segmentCount;
}

/// Salida de las fases 3 y 4.
class PipelineOutput {
  const PipelineOutput({
    required this.originalText,
    required this.result,
    required this.audit,
    required this.segmentCount,
  });

  final String originalText;
  final HumanizationResult result;
  final AuditReport audit;
  final int segmentCount;

  EditorialIndex? get indexBefore => audit.indexBefore;
  EditorialIndex? get indexAfter => audit.indexAfter;
}

/// Versión de resultado dentro de la sesión (versionado local).
class ResultVersion {
  const ResultVersion({
    required this.number,
    required this.label,
    required this.createdAt,
    required this.output,
  });

  final int number;
  final String label;
  final DateTime createdAt;
  final PipelineOutput output;
}

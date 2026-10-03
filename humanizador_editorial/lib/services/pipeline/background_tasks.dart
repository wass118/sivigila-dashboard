import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/audit_report.dart';
import '../../models/domain_profile.dart';
import '../../models/fidelity_warning.dart';
import '../../models/pipeline_models.dart';
import '../../models/protected_element.dart';
import '../analysis/local_text_analyzer.dart';
import '../audit/fidelity_auditor.dart';
import '../audit/protected_content_detector.dart';

/// Ejecuta trabajo de CPU fuera del hilo de interfaz. En Web, `compute`
/// se ejecuta en el mismo hilo (limitación de la plataforma).
abstract interface class TaskRunner {
  Future<R> run<Q, R>(ComputeCallback<Q, R> callback, Q message);
}

class IsolateTaskRunner implements TaskRunner {
  const IsolateTaskRunner();

  @override
  Future<R> run<Q, R>(ComputeCallback<Q, R> callback, Q message) =>
      compute(callback, message);
}

class InlineTaskRunner implements TaskRunner {
  const InlineTaskRunner();

  @override
  Future<R> run<Q, R>(ComputeCallback<Q, R> callback, Q message) async =>
      await callback(message);
}

// ---------------------------------------------------------------------------
// Trabajos (mensajes y funciones de nivel superior, aptos para isolates)
// ---------------------------------------------------------------------------

class LocalAnalysisJob {
  const LocalAnalysisJob({
    required this.text,
    required this.domains,
    required this.selectedDomainId,
  });

  final String text;
  final List<DomainProfile> domains;

  /// Dominio elegido o [DomainRegistry.autoId].
  final String selectedDomainId;
}

class LocalAnalysisResult {
  const LocalAnalysisResult(this.report, this.protectedElements);
  final LocalAnalysisReport report;
  final List<ProtectedElement> protectedElements;
}

/// Fases 1 (parte local) y 2: heurísticas y detección de protegidos.
LocalAnalysisResult runLocalAnalysis(LocalAnalysisJob job) {
  final registry = DomainRegistry(job.domains);
  final report = LocalTextAnalyzer(domains: registry).analyze(job.text);
  final domain = registry.byId(job.selectedDomainId == DomainRegistry.autoId
      ? report.detectedDomainId
      : job.selectedDomainId);
  final protectedElements = ProtectedContentDetector().detect(job.text,
      technicalTerms: domain.protectedTerms, eventNames: domain.eventNames);
  return LocalAnalysisResult(report, protectedElements);
}

class AuditJob {
  const AuditJob({
    required this.original,
    required this.revised,
    required this.modelWarnings,
    required this.technicalTerms,
    required this.eventNames,
  });

  final String original;
  final String? revised;
  final List<FidelityWarning> modelWarnings;
  final List<String> technicalTerms;
  final List<String> eventNames;
}

/// Fase 4: auditoría de fidelidad.
AuditReport runAudit(AuditJob job) => FidelityAuditor().audit(
      original: job.original,
      revised: job.revised,
      modelWarnings: job.modelWarnings,
      technicalTerms: job.technicalTerms,
      eventNames: job.eventNames,
    );

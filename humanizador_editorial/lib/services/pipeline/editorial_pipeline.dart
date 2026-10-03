import '../../core/config/app_limits.dart';
import '../../core/errors/humanizer_failure.dart';
import '../../core/utils/app_logger.dart';
import '../../models/domain_profile.dart';
import '../../models/audit_report.dart';
import '../../models/editorial_option.dart';
import '../../models/editorial_request.dart';
import '../../models/fidelity_warning.dart';
import '../../models/humanization_result.dart';
import '../../models/intensity.dart';
import '../../models/pipeline_models.dart';
import '../../models/protected_element.dart';
import '../../models/recommendation.dart';
import '../ai/editorial_context.dart';
import '../ai/humanizer_service.dart';
import '../audit/fidelity_auditor.dart';
import '../audit/protected_content_detector.dart';
import 'background_tasks.dart';
import 'text_segmenter.dart';

/// Orquesta las cuatro fases lógicas: análisis, protección de contenido,
/// reescritura y auditoría de fidelidad. No conoce la interfaz ni el
/// proveedor concreto.
class EditorialPipeline {
  EditorialPipeline({
    required this.service,
    required this.domains,
    required this.audiences,
    required this.goals,
    required this.authors,
    ProtectedContentDetector? detector,
    FidelityAuditor? auditor,
    this.segmenter = const TextSegmenter(),
    this.maxDocumentChars = AppLimits.maxDocumentChars,
    this.maxCharsPerRequest = AppLimits.maxCharsPerRequest,
    this.segmentContextChars = AppLimits.segmentContextChars,
    this.segmentationEnabled = true,
    this.runner = const IsolateTaskRunner(),
    this.backgroundThresholdChars = 8000,
  })  : detector = detector ?? ProtectedContentDetector(),
        auditor = auditor ?? FidelityAuditor(detector: detector);

  final HumanizerService service;
  final DomainRegistry domains;
  final OptionCatalog audiences;
  final OptionCatalog goals;
  final OptionCatalog authors;
  final ProtectedContentDetector detector;
  final FidelityAuditor auditor;
  final TextSegmenter segmenter;
  final int maxDocumentChars;
  final int maxCharsPerRequest;
  final int segmentContextChars;
  final bool segmentationEnabled;

  /// Ejecuta análisis local, detección y auditoría fuera del hilo de UI
  /// cuando el texto supera [backgroundThresholdChars] (en un documento de
  /// 60 000 caracteres la auditoría tarda del orden de 1 s).
  final TaskRunner runner;
  final int backgroundThresholdChars;

  TaskRunner _runnerFor(String text) => text.length > backgroundThresholdChars
      ? runner
      : const InlineTaskRunner();

  /// Validación previa a cualquier envío.
  void validate(String text) {
    if (text.trim().isEmpty) throw const EmptyTextFailure();
    if (text.length > maxDocumentChars) {
      throw TextTooLongFailure(length: text.length, limit: maxDocumentChars);
    }
    if (!segmentationEnabled && text.length > maxCharsPerRequest) {
      throw TextTooLongFailure(length: text.length, limit: maxCharsPerRequest);
    }
  }

  EditorialContext resolveContext(EditorialOptions options,
      {String? detectedDomainId}) {
    final domainId = options.domainId == DomainRegistry.autoId
        ? (detectedDomainId ?? DomainRegistry.generalId)
        : options.domainId;
    return EditorialContext(
      domain: domains.byId(domainId),
      audience: audiences.byId(options.audienceId),
      goal: goals.byId(options.goalId),
      author: authors.byId(options.authorProfileId),
      intensity: options.effectiveIntensity,
      extraStyleRules: options.extraStyleRules,
    );
  }

  // ---------------------------------------------------------------------
  // Fases 1 y 2
  // ---------------------------------------------------------------------

  Future<AnalysisOutcome> analyze(EditorialRequest request,
      {PhaseCallback? onPhase}) async {
    final text = request.text;
    validate(text);

    onPhase?.call(PipelinePhase.analysis,
        const PhaseState(PhaseStatus.running, 'Analizando el texto…'));
    final localResult = await _runnerFor(text).run(
        runLocalAnalysis,
        LocalAnalysisJob(
          text: text,
          domains: domains.all,
          selectedDomainId: request.options.domainId,
        ));
    final local = localResult.report;
    final ctx = resolveContext(request.options,
        detectedDomainId: local.detectedDomainId);
    final segments = _segments(text, const []);
    final partial = segments.length > 1;

    final analysis = await _run(PipelinePhase.analysis, onPhase, () =>
        service.analyze(AnalysisInput(
          text: partial ? segments.first.text : text,
          context: ctx,
          local: local,
          partial: partial,
        )));
    onPhase?.call(
        PipelinePhase.analysis,
        PhaseState(PhaseStatus.done,
            '${ctx.domain.label} · ${analysis.problems.length} '
            'problemas${partial ? ' · análisis del primer segmento' : ''}'));

    onPhase?.call(PipelinePhase.protection,
        const PhaseState(PhaseStatus.running, 'Localizando datos…'));
    // Calculados junto con el análisis local (mismo trabajo en segundo plano).
    final protectedElements = localResult.protectedElements;
    final critical = protectedElements.where((p) => p.type.critical).length;
    onPhase?.call(
        PipelinePhase.protection,
        PhaseState(PhaseStatus.done,
            '${protectedElements.length} elementos protegidos '
            '($critical críticos)'));

    AppLogger.info('pipeline', 'analyze chars=${text.length} '
        'protegidos=${protectedElements.length} segmentos=${segments.length}');

    return AnalysisOutcome(
      analyzedText: text,
      analysis: analysis,
      local: local,
      protectedElements: protectedElements,
      effectiveDomain: ctx.domain,
      segmentCount: segments.length,
    );
  }

  // ---------------------------------------------------------------------
  // Fases 3 y 4
  // ---------------------------------------------------------------------

  Future<PipelineOutput> humanize(
    EditorialRequest request,
    AnalysisOutcome analysis, {
    PhaseCallback? onPhase,
  }) async {
    final text = request.text;
    validate(text);
    final ctx = resolveContext(request.options,
        detectedDomainId: analysis.local.detectedDomainId);
    final segments = _segments(text, analysis.protectedElements);

    final results = <HumanizationResult>[];
    for (final segment in segments) {
      onPhase?.call(
          PipelinePhase.rewriting,
          PhaseState(
              PhaseStatus.running,
              ctx.intensity.producesRewrite
                  ? 'Reescribiendo segmento ${segment.index + 1} de '
                      '${segments.length}…'
                  : 'Generando recomendaciones…'));
      final segmentProtected = segments.length == 1
          ? analysis.protectedElements
          : detector.detect(segment.text,
              technicalTerms: ctx.domain.protectedTerms,
              eventNames: ctx.domain.eventNames);
      final result = await _run(PipelinePhase.rewriting, onPhase, () =>
          service.humanize(HumanizationInput(
            text: segment.text,
            context: ctx,
            protectedElements: segmentProtected,
            analysis: analysis.analysis,
            segmentIndex: segment.index,
            segmentCount: segments.length,
            contextBefore: segment.contextBefore,
          )));
      results.add(result);
    }

    final merged = _merge(results, segments, analysis, ctx.intensity);
    onPhase?.call(
        PipelinePhase.rewriting,
        PhaseState(
            PhaseStatus.done,
            merged.hasRewrite
                ? 'Versión generada${segments.length > 1 ? ' en ${segments.length} segmentos' : ''}'
                : '${merged.recommendations.length} recomendaciones'));

    onPhase?.call(PipelinePhase.audit,
        const PhaseState(PhaseStatus.running, 'Comparando entidades…'));
    final report = await _audit(AuditJob(
      original: text,
      revised: merged.rewrittenText,
      modelWarnings: merged.fidelityWarnings,
      technicalTerms: ctx.domain.protectedTerms,
      eventNames: ctx.domain.eventNames,
    ));
    onPhase?.call(PipelinePhase.audit,
        PhaseState(PhaseStatus.done, report.status.label));

    return PipelineOutput(
      originalText: text,
      result: merged,
      audit: report,
      segmentCount: segments.length,
    );
  }

  /// Regenera un único párrafo de la versión actual y vuelve a auditar el
  /// documento completo contra el original.
  Future<PipelineOutput> regenerateParagraph({
    required EditorialRequest request,
    required AnalysisOutcome analysis,
    required PipelineOutput current,
    required int paragraphIndex,
  }) async {
    final rewritten = current.result.rewrittenText;
    if (rewritten == null) {
      throw const UnsupportedFeatureFailure(
          'No hay versión generada para regenerar un párrafo.');
    }
    final parts = ParagraphSplit.of(rewritten);
    if (paragraphIndex < 0 || paragraphIndex >= parts.paragraphs.length) {
      throw const UnexpectedFailure('Párrafo fuera de rango.');
    }
    final originalParts = ParagraphSplit.of(current.originalText);
    final reference =
        originalParts.paragraphs.length == parts.paragraphs.length
            ? originalParts.paragraphs[paragraphIndex]
            : null;
    final ctx = resolveContext(request.options,
        detectedDomainId: analysis.local.detectedDomainId);
    final fragment = parts.paragraphs[paragraphIndex];

    final result = await _run(PipelinePhase.rewriting, null, () =>
        service.rewriteFragment(FragmentInput(
          fragment: fragment,
          originalReference: reference,
          context: ctx,
          protectedElements: detector.detect(fragment,
              technicalTerms: ctx.domain.protectedTerms,
              eventNames: ctx.domain.eventNames),
          contextBefore:
              paragraphIndex > 0 ? parts.paragraphs[paragraphIndex - 1] : '',
          contextAfter: paragraphIndex < parts.paragraphs.length - 1
              ? parts.paragraphs[paragraphIndex + 1]
              : '',
        )));

    final updated = parts.replace(paragraphIndex, result.rewrittenText!);
    final modelWarnings = [
      ...current.result.fidelityWarnings,
      ...result.fidelityWarnings,
    ];
    final report = await _audit(AuditJob(
      original: current.originalText,
      revised: updated,
      modelWarnings: modelWarnings,
      technicalTerms: ctx.domain.protectedTerms,
      eventNames: ctx.domain.eventNames,
    ));
    return PipelineOutput(
      originalText: current.originalText,
      result: current.result.copyWith(
        rewrittenText: updated,
        fidelityWarnings: modelWarnings,
        improvements: [
          ...current.result.improvements,
          'Párrafo ${paragraphIndex + 1} regenerado'
              '${result.improvements.isEmpty ? '' : ': ${result.improvements.where((i) => !i.startsWith('[DEMO')).join('; ')}'}',
        ],
      ),
      audit: report,
      segmentCount: current.segmentCount,
    );
  }

  // ---------------------------------------------------------------------

  List<TextSegment> _segments(
      String text, List<ProtectedElement> protectedSpans) {
    if (!segmentationEnabled || text.length <= maxCharsPerRequest) {
      return [TextSegment(index: 0, text: text, separatorAfter: '',
          contextBefore: '')];
    }
    return segmenter.split(text,
        maxChars: maxCharsPerRequest,
        contextChars: segmentContextChars,
        protectedSpans: protectedSpans);
  }

  Future<AuditReport> _audit(AuditJob job) {
    final runner = _runnerFor(job.original);
    // En línea se reutiliza el auditor inyectado (pruebas, configuraciones).
    if (runner is InlineTaskRunner) {
      return Future.value(auditor.audit(
        original: job.original,
        revised: job.revised,
        modelWarnings: job.modelWarnings,
        technicalTerms: job.technicalTerms,
        eventNames: job.eventNames,
      ));
    }
    return runner.run(runAudit, job);
  }

  HumanizationResult _merge(List<HumanizationResult> results,
      List<TextSegment> segments, AnalysisOutcome analysis,
      Intensity intensity) {
    final first = results.first;
    final rewrite = intensity.producesRewrite;
    String? text;
    if (rewrite) {
      text = results.length == 1
          ? first.rewrittenText
          : segmenter.join(
              segments, results.map((r) => r.rewrittenText ?? '').toList());
    }
    final improvements = <String>[];
    for (final r in results) {
      for (final i in r.improvements) {
        if (!improvements.contains(i)) improvements.add(i);
      }
    }
    return HumanizationResult(
      analysis: analysis.analysis,
      rewrittenText: text,
      recommendations: <Recommendation>[
        for (final r in results) ...r.recommendations
      ],
      fidelityWarnings: <FidelityWarning>[
        for (final r in results) ...r.fidelityWarnings
      ],
      protectedElements: analysis.protectedElements,
      improvements: improvements,
      isDemo: first.isDemo,
      providerLabel: first.providerLabel,
    );
  }

  /// Ejecuta una llamada al servicio garantizando errores tipados y el
  /// aviso de fase fallida.
  Future<T> _run<T>(PipelinePhase phase, PhaseCallback? onPhase,
      Future<T> Function() call) async {
    try {
      return await call();
    } on HumanizerFailure catch (e) {
      onPhase?.call(phase, PhaseState(PhaseStatus.failed, e.title));
      rethrow;
    } catch (e) {
      onPhase?.call(phase, const PhaseState(PhaseStatus.failed,
          'Error inesperado'));
      AppLogger.error('pipeline', 'fallo inesperado ${e.runtimeType}');
      throw UnexpectedFailure('Ocurrió un error inesperado durante '
          '${phase.label.toLowerCase()}.',
          technicalDetail: e.runtimeType.toString());
    }
  }
}

/// División de un texto en párrafos conservando los separadores originales,
/// para poder reemplazar uno sin alterar el resto.
class ParagraphSplit {
  ParagraphSplit._(this.paragraphs, this._leading, this._separators);

  factory ParagraphSplit.of(String text) {
    final paragraphs = <String>[];
    final separators = <String>[];
    final matches = RegExp(r'[^\n]+').allMatches(text).where(
        (m) => m.group(0)!.trim().isNotEmpty).toList();
    if (matches.isEmpty) return ParagraphSplit._([], text, []);
    final leading = text.substring(0, matches.first.start);
    for (var i = 0; i < matches.length; i++) {
      paragraphs.add(matches[i].group(0)!);
      final end = i + 1 < matches.length ? matches[i + 1].start : text.length;
      separators.add(text.substring(matches[i].end, end));
    }
    return ParagraphSplit._(paragraphs, leading, separators);
  }

  final List<String> paragraphs;
  final String _leading;
  final List<String> _separators;

  String replace(int index, String replacement) {
    final b = StringBuffer(_leading);
    for (var i = 0; i < paragraphs.length; i++) {
      b.write(i == index ? replacement.trim() : paragraphs[i]);
      b.write(_separators[i]);
    }
    return b.toString();
  }
}

import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';

import '../../app/app_services.dart';
import '../../core/errors/humanizer_failure.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/text_utils.dart';
import '../../demo/demo_samples.dart';
import '../../models/domain_profile.dart';
import '../../models/editorial_document.dart';
import '../../models/editorial_preset.dart';
import '../../models/editorial_request.dart';
import '../../models/intensity.dart';
import '../../models/pipeline_models.dart';
import '../history/history_controller.dart';
import '../settings/settings_controller.dart';

enum EditorBusy { idle, analyzing, humanizing, regenerating }

/// Estado y flujo principal del editor: texto, opciones, fases, resultados
/// y versiones de la sesión.
class EditorController extends ChangeNotifier {
  EditorController({
    required this.services,
    required this.settingsController,
    required this.historyController,
  });

  final AppServices services;
  final SettingsController settingsController;
  final HistoryController historyController;

  final TextEditingController textController = TextEditingController();

  EditorialOptions _options = const EditorialOptions();
  String? _presetId;
  List<EditorialPreset> _presets = const [];
  final Map<PipelinePhase, PhaseState> _phases = {
    for (final p in PipelinePhase.values) p: PhaseState.pending,
  };
  AnalysisOutcome? _analysis;
  EditorialRequest? _lastRequest;
  final List<ResultVersion> _versions = [];
  int _currentVersion = -1;
  EditorBusy _busy = EditorBusy.idle;
  HumanizerFailure? _failure;
  String? _originalSnapshot;
  bool _remoteConsent = false;
  int _revision = 0;

  // ---- Lectura --------------------------------------------------------

  EditorialOptions get options => _options;
  String? get presetId => _presetId;
  List<EditorialPreset> get presets => _presets;
  Map<PipelinePhase, PhaseState> get phases => Map.unmodifiable(_phases);
  AnalysisOutcome? get analysis => _analysis;
  List<ResultVersion> get versions => List.unmodifiable(_versions);
  int get currentVersionIndex => _currentVersion;
  ResultVersion? get current =>
      _currentVersion >= 0 && _currentVersion < _versions.length
          ? _versions[_currentVersion]
          : null;
  EditorBusy get busy => _busy;
  bool get isBusy => _busy != EditorBusy.idle;
  HumanizerFailure? get failure => _failure;
  String? get originalSnapshot => _originalSnapshot;

  /// Aumenta con cada análisis o resultado nuevo (la vista lo usa para
  /// cambiar de pestaña).
  int get revision => _revision;

  bool get analysisIsStale =>
      _analysis != null && _analysis!.analyzedText != textController.text;

  bool get needsRemoteConsent =>
      settingsController.descriptor.isRemote && !_remoteConsent;

  DomainProfile get effectiveDomain {
    if (_options.domainId != DomainRegistry.autoId) {
      return services.domains.byId(_options.domainId);
    }
    final detected = _analysis?.local.detectedDomainId ??
        services.analyzer
            .detectDomain(TextUtils.fold(textController.text))
            .$1;
    return services.domains.byId(detected);
  }

  // ---- Configuración --------------------------------------------------

  Future<void> loadPresets() async {
    _presets = await services.presetRepository.list();
    notifyListeners();
  }

  void updateOptions(EditorialOptions options) {
    _options = options;
    _presetId = null;
    notifyListeners();
  }

  void applyPreset(EditorialPreset preset) {
    _options = preset.options;
    _presetId = preset.id;
    notifyListeners();
  }

  Future<void> saveCurrentAsPreset(String name) async {
    final preset = EditorialPreset(
        id: 'user_${const Uuid().v4()}', name: name.trim(), options: _options);
    await services.presetRepository.save(preset);
    await loadPresets();
    _presetId = preset.id;
    notifyListeners();
  }

  Future<void> deletePreset(String id) async {
    await services.presetRepository.delete(id);
    if (_presetId == id) _presetId = null;
    await loadPresets();
  }

  void grantRemoteConsent() {
    _remoteConsent = true;
    notifyListeners();
  }

  // ---- Texto ----------------------------------------------------------

  void loadDemo() {
    _setText(DemoSamples.publicHealth);
    final preset = _presets.where((p) => p.id == 'preset_informe_epi');
    if (preset.isNotEmpty) applyPreset(preset.first);
  }

  void clearText() {
    _setText('');
    _resetResults();
  }

  /// Devuelve el editor al texto que se envió por última vez.
  void restoreOriginal() {
    if (_originalSnapshot != null) _setText(_originalSnapshot!);
  }

  /// Usa la versión generada como nuevo texto de trabajo.
  void acceptResult() {
    final text = current?.output.result.rewrittenText;
    if (text != null) _setText(text);
  }

  void loadFromHistory(EditorialDocument doc, {bool useGenerated = false}) {
    _setText(useGenerated && doc.generatedText != null
        ? doc.generatedText!
        : doc.originalText);
    _options = _options.copyWith(
      domainId: services.domains.contains(doc.domainId)
          ? doc.domainId
          : _options.domainId,
      goalId: services.goals.contains(doc.goalId) ? doc.goalId : null,
      intensity: Intensity.fromName(doc.intensityName),
    );
    _presetId = null;
    _resetResults();
  }

  void _setText(String text) {
    textController.value = TextEditingValue(
        text: text, selection: TextSelection.collapsed(offset: text.length));
    _failure = null;
    notifyListeners();
  }

  void _resetResults() {
    _analysis = null;
    _versions.clear();
    _currentVersion = -1;
    _failure = null;
    for (final p in PipelinePhase.values) {
      _phases[p] = PhaseState.pending;
    }
    notifyListeners();
  }

  void dismissFailure() {
    _failure = null;
    notifyListeners();
  }

  // ---- Flujo ----------------------------------------------------------

  /// Fases 1 y 2. Devuelve `true` si terminó correctamente.
  Future<bool> analyze() async {
    if (isBusy) return false;
    final request = _request();
    _beginOperation(EditorBusy.analyzing, resetFrom: PipelinePhase.analysis);
    try {
      final pipeline = await services.buildPipeline(settingsController.settings);
      _analysis = await pipeline.analyze(request, onPhase: _onPhase);
      _lastRequest = request;
      _originalSnapshot = request.text;
      _revision++;
      return true;
    } on HumanizerFailure catch (f) {
      _failure = f;
      return false;
    } catch (e) {
      _failure = UnexpectedFailure('Ocurrió un error inesperado.',
          technicalDetail: e.runtimeType.toString());
      AppLogger.error('editor', 'analyze ${e.runtimeType}');
      return false;
    } finally {
      _endOperation();
    }
  }

  /// Fases 3 y 4 (ejecuta antes 1 y 2 si el análisis falta o está
  /// desactualizado).
  Future<bool> humanize() async {
    if (isBusy) return false;
    if (_analysis == null || analysisIsStale) {
      final ok = await analyze();
      if (!ok) return false;
    }
    final request = _request();
    final analysis = _analysis!;
    _beginOperation(EditorBusy.humanizing, resetFrom: PipelinePhase.rewriting);
    try {
      final pipeline = await services.buildPipeline(settingsController.settings);
      final output =
          await pipeline.humanize(request, analysis, onPhase: _onPhase);
      _lastRequest = request;
      _addVersion(output,
          output.result.hasRewrite ? 'Versión generada' : 'Recomendaciones');
      await _saveHistory(request, output);
      return true;
    } on HumanizerFailure catch (f) {
      _failure = f;
      return false;
    } catch (e) {
      _failure = UnexpectedFailure('Ocurrió un error inesperado.',
          technicalDetail: e.runtimeType.toString());
      AppLogger.error('editor', 'humanize ${e.runtimeType}');
      return false;
    } finally {
      _endOperation();
    }
  }

  Future<bool> regenerateParagraph(int index) async {
    final cur = current;
    final analysis = _analysis;
    final request = _lastRequest;
    if (isBusy || cur == null || analysis == null || request == null) {
      return false;
    }
    _beginOperation(EditorBusy.regenerating);
    try {
      final pipeline = await services.buildPipeline(settingsController.settings);
      final output = await pipeline.regenerateParagraph(
        request: request,
        analysis: analysis,
        current: cur.output,
        paragraphIndex: index,
      );
      _addVersion(output, 'Párrafo ${index + 1} regenerado');
      return true;
    } on HumanizerFailure catch (f) {
      _failure = f;
      return false;
    } catch (e) {
      _failure = UnexpectedFailure('Ocurrió un error inesperado.',
          technicalDetail: e.runtimeType.toString());
      return false;
    } finally {
      _endOperation();
    }
  }

  void selectVersion(int index) {
    if (index < 0 || index >= _versions.length) return;
    _currentVersion = index;
    notifyListeners();
  }

  // ---------------------------------------------------------------------

  EditorialRequest _request() =>
      EditorialRequest(text: textController.text, options: _options);

  void _onPhase(PipelinePhase phase, PhaseState state) {
    _phases[phase] = state;
    notifyListeners();
  }

  void _beginOperation(EditorBusy busy, {PipelinePhase? resetFrom}) {
    _busy = busy;
    _failure = null;
    if (resetFrom != null) {
      for (final p in PipelinePhase.values) {
        if (p.index >= resetFrom.index) _phases[p] = PhaseState.pending;
      }
    }
    if (resetFrom == PipelinePhase.analysis) {
      _versions.clear();
      _currentVersion = -1;
    }
    notifyListeners();
  }

  void _endOperation() {
    _busy = EditorBusy.idle;
    notifyListeners();
  }

  void _addVersion(PipelineOutput output, String label) {
    _versions.add(ResultVersion(
      number: _versions.length + 1,
      label: label,
      createdAt: DateTime.now(),
      output: output,
    ));
    _currentVersion = _versions.length - 1;
    _revision++;
  }

  Future<void> _saveHistory(
      EditorialRequest request, PipelineOutput output) async {
    if (!settingsController.settings.saveHistory) return;
    try {
      await historyController.add(EditorialDocument(
        id: const Uuid().v4(),
        createdAt: DateTime.now(),
        title: TextUtils.titleFrom(request.text),
        domainId: _analysis?.effectiveDomain.id ?? request.options.domainId,
        goalId: request.options.goalId,
        intensityName: request.options.effectiveIntensity.name,
        originalText: request.text,
        generatedText: output.result.rewrittenText,
        auditStatus: output.audit.status.label,
        isDemo: output.result.isDemo,
      ));
    } catch (e) {
      // El historial es secundario: un fallo de almacenamiento no invalida
      // el resultado.
      AppLogger.warning('editor', 'no se pudo guardar historial '
          '(${e.runtimeType})');
    }
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }
}

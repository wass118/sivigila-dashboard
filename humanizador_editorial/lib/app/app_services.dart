import 'package:http/http.dart' as http;

import '../core/config/ai_provider_settings.dart';
import '../core/config/app_environment.dart';
import '../core/config/editorial_catalog.dart';
import '../core/utils/app_logger.dart';
import '../models/domain_profile.dart';
import '../models/editorial_option.dart';
import '../services/ai/humanizer_service_factory.dart';
import '../services/analysis/local_text_analyzer.dart';
import '../services/audit/protected_content_detector.dart';
import '../services/pipeline/editorial_pipeline.dart';
import '../services/storage/history_repository.dart';
import '../services/storage/key_value_store.dart';
import '../services/storage/preset_repository.dart';
import '../services/storage/secret_store.dart';
import '../services/storage/settings_repository.dart';

/// Composición de dependencias (sin framework de inyección: explícito y
/// fácil de sustituir en pruebas).
class AppServices {
  AppServices({
    required this.settingsRepository,
    required this.historyRepository,
    required this.presetRepository,
    required this.serviceFactory,
    required this.domains,
    required this.audiences,
    required this.goals,
    required this.authors,
    required this.analyzer,
    required this.detector,
    required this.mode,
  });

  final SettingsRepository settingsRepository;
  final HistoryRepository historyRepository;
  final PresetRepository presetRepository;
  final HumanizerServiceFactory serviceFactory;
  final DomainRegistry domains;
  final OptionCatalog audiences;
  final OptionCatalog goals;
  final OptionCatalog authors;
  final LocalTextAnalyzer analyzer;
  final ProtectedContentDetector detector;
  final HumanizerMode mode;

  static Future<AppServices> bootstrap({
    HumanizerMode? mode,
    KeyValueStore? store,
    SecretStore? secrets,
    http.Client? httpClient,
    Duration fakeLatency = const Duration(milliseconds: 500),
  }) async {
    AppLogger.enabled = AppEnvironment.logsEnabled;
    final kv = store ?? await SharedPrefsStore.create();
    final secretStore = secrets ?? SecureSecretStore();
    final domains = EditorialCatalog.domainRegistry();
    final analyzer = LocalTextAnalyzer(domains: domains);
    final effectiveMode = mode ?? AppEnvironment.mode;
    AppLogger.info('app', 'inicio modo=${effectiveMode.name}');
    return AppServices(
      settingsRepository: SettingsRepository(store: kv, secrets: secretStore),
      historyRepository: HistoryRepository(kv),
      presetRepository: PresetRepository(kv),
      serviceFactory: HumanizerServiceFactory(
        httpClient: httpClient ?? http.Client(),
        analyzer: analyzer,
        mode: effectiveMode,
        fakeLatency: fakeLatency,
      ),
      domains: domains,
      audiences: EditorialCatalog.audienceCatalog(),
      goals: EditorialCatalog.goalCatalog(),
      authors: EditorialCatalog.authorCatalog(),
      analyzer: analyzer,
      detector: ProtectedContentDetector(),
      mode: effectiveMode,
    );
  }

  /// Construye el pipeline con el proveedor vigente. La clave se lee del
  /// almacenamiento seguro solo en este momento y no se retiene.
  Future<EditorialPipeline> buildPipeline(AiProviderSettings settings) async {
    final apiKey = serviceFactory.usesDemo(settings)
        ? null
        : await settingsRepository.readApiKey(settings.providerType);
    final service = serviceFactory.create(settings, apiKey: apiKey);
    return EditorialPipeline(
      service: service,
      domains: domains,
      audiences: audiences,
      goals: goals,
      authors: authors,
      detector: detector,
      segmentationEnabled: settings.segmentationEnabled,
    );
  }
}

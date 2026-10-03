import 'dart:convert';

import '../../core/config/ai_provider_settings.dart';
import '../../core/utils/app_logger.dart';
import 'key_value_store.dart';
import 'secret_store.dart';

/// Persistencia de la configuración del proveedor y de su clave.
class SettingsRepository {
  SettingsRepository({required this.store, required this.secrets});

  final KeyValueStore store;
  final SecretStore secrets;

  static const String _settingsKey = 'settings.ai_provider.v1';

  /// La clave se guarda por tipo de proveedor para no mezclar credenciales.
  static String secretKeyFor(AiProviderType type) => 'secret.api_key.${type.name}';

  Future<AiProviderSettings> load() async {
    final raw = await store.getString(_settingsKey);
    if (raw == null) return const AiProviderSettings();
    try {
      return AiProviderSettings.fromJson(
          (jsonDecode(raw) as Map).cast<String, dynamic>());
    } catch (e) {
      AppLogger.warning('settings', 'configuración corrupta, se usan '
          'valores por defecto (${e.runtimeType})');
      return const AiProviderSettings();
    }
  }

  Future<void> save(AiProviderSettings settings) =>
      store.setString(_settingsKey, jsonEncode(settings.toJson()));

  Future<void> saveApiKey(AiProviderType type, String key) =>
      secrets.write(secretKeyFor(type), key.trim());

  Future<void> deleteApiKey(AiProviderType type) =>
      secrets.delete(secretKeyFor(type));

  Future<bool> hasApiKey(AiProviderType type) =>
      secrets.contains(secretKeyFor(type));

  /// Uso interno exclusivo de la fábrica de servicios.
  Future<String?> readApiKey(AiProviderType type) =>
      secrets.read(secretKeyFor(type));
}

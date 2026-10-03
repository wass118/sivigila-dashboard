import 'package:flutter/foundation.dart';

import '../../app/app_services.dart';
import '../../core/config/ai_provider_settings.dart';
import '../../services/ai/humanizer_service.dart';

/// Estado de Ajustes. Nunca expone el valor de la clave: solo si existe.
class SettingsController extends ChangeNotifier {
  SettingsController(this._services);

  final AppServices _services;

  AiProviderSettings _settings = const AiProviderSettings();
  bool _hasApiKey = false;
  bool _loaded = false;

  AiProviderSettings get settings => _settings;
  bool get hasApiKey => _hasApiKey;
  bool get loaded => _loaded;

  ProviderDescriptor get descriptor =>
      _services.serviceFactory.describe(_settings);

  bool get demoForcedByEnvironment =>
      _services.serviceFactory.usesDemo(_settings) &&
      _settings.providerType != AiProviderType.demo;

  Future<void> load() async {
    _settings = await _services.settingsRepository.load();
    _hasApiKey =
        await _services.settingsRepository.hasApiKey(_settings.providerType);
    _loaded = true;
    notifyListeners();
  }

  Future<void> save(AiProviderSettings settings) async {
    _settings = settings;
    await _services.settingsRepository.save(settings);
    _hasApiKey =
        await _services.settingsRepository.hasApiKey(settings.providerType);
    notifyListeners();
  }

  Future<bool> hasKeyFor(AiProviderType type) =>
      _services.settingsRepository.hasApiKey(type);

  Future<void> saveApiKey(AiProviderType type, String key) async {
    if (key.trim().isEmpty) return;
    await _services.settingsRepository.saveApiKey(type, key);
    if (type == _settings.providerType) _hasApiKey = true;
    notifyListeners();
  }

  Future<void> deleteApiKey(AiProviderType type) async {
    await _services.settingsRepository.deleteApiKey(type);
    if (type == _settings.providerType) _hasApiKey = false;
    notifyListeners();
  }
}

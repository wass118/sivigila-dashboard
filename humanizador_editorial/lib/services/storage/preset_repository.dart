import 'dart:convert';

import '../../core/config/editorial_catalog.dart';
import '../../core/utils/app_logger.dart';
import '../../models/editorial_preset.dart';
import 'key_value_store.dart';

/// Presets de fábrica + presets guardados por el usuario.
class PresetRepository {
  PresetRepository(this.store);

  final KeyValueStore store;
  static const String _key = 'presets.user.v1';

  Future<List<EditorialPreset>> list() async =>
      [...EditorialCatalog.builtInPresets, ...await _userPresets()];

  Future<void> save(EditorialPreset preset) async {
    if (preset.builtIn) return;
    final items = await _userPresets();
    items.removeWhere((p) => p.id == preset.id);
    items.add(preset);
    await store.setString(
        _key, jsonEncode(items.map((p) => p.toJson()).toList()));
  }

  Future<void> delete(String id) async {
    final items = await _userPresets();
    items.removeWhere((p) => p.id == id);
    await store.setString(
        _key, jsonEncode(items.map((p) => p.toJson()).toList()));
  }

  Future<List<EditorialPreset>> _userPresets() async {
    final raw = await store.getString(_key);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .whereType<Map>()
          .map((m) => EditorialPreset.fromJson(m.cast<String, dynamic>()))
          .where((p) => !p.builtIn)
          .toList();
    } catch (e) {
      AppLogger.warning('presets', 'presets ilegibles (${e.runtimeType})');
      return [];
    }
  }
}

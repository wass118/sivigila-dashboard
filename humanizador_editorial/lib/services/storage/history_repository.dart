import 'dart:convert';

import '../../core/config/app_limits.dart';
import '../../core/utils/app_logger.dart';
import '../../models/editorial_document.dart';
import 'key_value_store.dart';

/// Historial local de documentos procesados. Sin almacenamiento remoto.
class HistoryRepository {
  HistoryRepository(this.store, {this.maxEntries = AppLimits.historyMaxEntries});

  final KeyValueStore store;
  final int maxEntries;

  static const String _key = 'history.documents.v1';

  Future<List<EditorialDocument>> list() async {
    final raw = await store.getString(_key);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded
          .whereType<Map>()
          .map((m) => EditorialDocument.fromJson(m.cast<String, dynamic>()))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      AppLogger.warning('history', 'historial ilegible (${e.runtimeType})');
      return [];
    }
  }

  Future<void> add(EditorialDocument doc) async {
    final items = await list();
    items.removeWhere((d) => d.id == doc.id);
    items.insert(0, doc);
    await _save(items.take(maxEntries).toList());
  }

  Future<void> delete(String id) async {
    final items = await list();
    items.removeWhere((d) => d.id == id);
    await _save(items);
  }

  Future<void> clear() => store.remove(_key);

  Future<void> _save(List<EditorialDocument> items) => store.setString(
      _key, jsonEncode(items.map((d) => d.toJson()).toList()));
}

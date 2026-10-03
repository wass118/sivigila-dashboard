import 'package:flutter/foundation.dart';

import '../../models/editorial_document.dart';
import '../../services/storage/history_repository.dart';

class HistoryController extends ChangeNotifier {
  HistoryController(this._repository);

  final HistoryRepository _repository;
  List<EditorialDocument> _items = const [];

  List<EditorialDocument> get items => _items;

  Future<void> load() async {
    _items = await _repository.list();
    notifyListeners();
  }

  Future<void> add(EditorialDocument doc) async {
    await _repository.add(doc);
    await load();
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    await load();
  }

  Future<void> clear() async {
    await _repository.clear();
    await load();
  }
}

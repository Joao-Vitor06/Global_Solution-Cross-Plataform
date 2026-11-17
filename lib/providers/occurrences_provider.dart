import 'package:flutter/foundation.dart';

import '../models/occurrence.dart';
import '../services/storage_service.dart';

/// Estado global das ocorrências registradas pelos cidadãos (persistidas localmente).
class OccurrencesProvider extends ChangeNotifier {
  OccurrencesProvider(this._storage) : _items = _storage.loadOccurrences() {
    _sort();
  }

  final StorageService _storage;
  List<Occurrence> _items;

  List<Occurrence> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;
  int get count => _items.length;

  int countInZone(String zoneId) => _items.where((o) => o.zoneId == zoneId).length;

  Future<void> add({
    required OccurrenceCategory category,
    required String description,
    required String zoneId,
    required int severity,
  }) async {
    final now = DateTime.now();
    _items = [
      Occurrence(
        id: now.microsecondsSinceEpoch.toString(),
        category: category,
        description: description.trim(),
        zoneId: zoneId,
        severity: severity,
        createdAt: now,
      ),
      ..._items,
    ];
    notifyListeners();
    await _storage.saveOccurrences(_items);
  }

  Future<void> remove(String id) async {
    _items = _items.where((o) => o.id != id).toList();
    notifyListeners();
    await _storage.saveOccurrences(_items);
  }

  Future<void> clear() async {
    _items = [];
    notifyListeners();
    await _storage.saveOccurrences(_items);
  }

  void _sort() => _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
}

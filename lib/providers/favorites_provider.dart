import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/database/database_helper.dart';
import '../data/models/drug_model.dart';
import 'drug_provider.dart';

/// Ordered list — index 0 is the MOST RECENTLY added drug.
class FavoritesNotifier extends StateNotifier<List<int>> {
  FavoritesNotifier() : super([]) {
    _load();
  }

  static const _key = 'favorites_v2';
  static const _migratedKey = 'favorites_migrated_v3';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    state = raw.map(int.parse).toList();
    await _migrateToV3(prefs);
  }

  /// ترحيل المفضّلات من معرّفات قاعدة 2.3 إلى معرّفات قاعدة 3.0.
  ///
  /// قاعدة 2.3 كانت 754 سجلاً بمعرّفات 1..754، وقاعدة 3.0 معرّفاتها مختلفة
  /// تماماً. بدون هذا الترحيل تشير المفضّلة القديمة إلى **دواء آخر**، وهو
  /// أخطر من فقدانها. الخريطة محفوظة في جدول `legacy_id_map` داخل القاعدة.
  Future<void> _migrateToV3(SharedPreferences prefs) async {
    if (prefs.getBool(_migratedKey) == true) return;
    if (state.isEmpty) {
      await prefs.setBool(_migratedKey, true);
      return;
    }
    try {
      final map = await DatabaseHelper.instance.legacyIdMap();
      if (map.isEmpty) return; // قاعدة قديمة — نحاول مرة أخرى لاحقاً

      final migrated = <int>[];
      for (final oldId in state) {
        final newId = map[oldId];
        if (newId != null && !migrated.contains(newId)) {
          migrated.add(newId);
        }
      }
      state = migrated;
      await _save();
      await prefs.setBool(_migratedKey, true);
    } catch (_) {
      // لا نضع علم الترحيل عند الفشل حتى تُعاد المحاولة في التشغيل التالي
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, state.map((e) => e.toString()).toList());
  }

  bool isFavorite(int drugId) => state.contains(drugId);

  Future<void> toggle(int drugId) async {
    if (state.contains(drugId)) {
      state = [for (final id in state) if (id != drugId) id];
    } else {
      // Newest first — prepend
      state = [drugId, ...state];
    }
    await _save();
  }

  Future<void> remove(int drugId) async {
    state = [for (final id in state) if (id != drugId) id];
    await _save();
  }

  Future<void> removeMany(Iterable<int> ids) async {
    final toRemove = ids.toSet();
    state = [for (final id in state) if (!toRemove.contains(id)) id];
    await _save();
  }

  Future<void> removeAll() async {
    state = [];
    await _save();
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, List<int>>(
  (_) => FavoritesNotifier(),
);

/// Returns drugs in favorites order (newest first), resolved from DB.
final favoriteDrugsProvider = FutureProvider<List<Drug>>((ref) async {
  final ids = ref.watch(favoritesProvider);
  if (ids.isEmpty) return [];
  final repo = ref.read(drugRepositoryProvider);
  final results = await Future.wait(ids.map((id) => repo.getById(id)));
  // Keep insertion order, skip nulls
  return results.whereType<Drug>().toList();
});

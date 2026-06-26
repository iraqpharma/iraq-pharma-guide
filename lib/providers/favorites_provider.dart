import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/drug_model.dart';
import 'drug_provider.dart';

/// Ordered list — index 0 is the MOST RECENTLY added drug.
class FavoritesNotifier extends StateNotifier<List<int>> {
  FavoritesNotifier() : super([]) {
    _load();
  }

  static const _key = 'favorites_v2';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    state = raw.map(int.parse).toList();
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

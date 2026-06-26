import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/database_helper.dart';
import '../data/models/drug_model.dart';
import '../data/models/suggestion_item.dart';
import '../data/repositories/drug_repository.dart';

export '../data/models/suggestion_item.dart';

// ── Repository ────────────────────────────────────────────────────────────────
final drugRepositoryProvider = Provider<DrugRepository>(
  (_) => DrugRepository(DatabaseHelper.instance),
);

// ── Raw query typed by user ───────────────────────────────────────────────────
final searchQueryProvider = StateProvider<String>((_) => '');

// ── 300ms debounced query ─────────────────────────────────────────────────────
final _debouncedQueryProvider = StreamProvider<String>((ref) {
  final controller = StreamController<String>();
  Timer? timer;

  final sub = ref.listen<String>(searchQueryProvider, (_, next) {
    timer?.cancel();
    timer = Timer(const Duration(milliseconds: 300), () {
      if (!controller.isClosed) controller.add(next);
    });
  });

  ref.onDispose(() {
    timer?.cancel();
    sub.close();
    controller.close();
  });

  return controller.stream;
});

// ── Full search results (debounced) ──────────────────────────────────────────
final searchResultsProvider = FutureProvider<List<Drug>>((ref) async {
  final qAsync = ref.watch(_debouncedQueryProvider);
  final q = qAsync.valueOrNull ?? '';
  if (q.trim().length < 2) return [];
  return ref.read(drugRepositoryProvider).search(q);
});

// ── Autocomplete suggestions ──────────────────────────────────────────────────
final autocompleteSuggestionsProvider =
    FutureProvider.family<List<SuggestionItem>, String>((ref, q) async {
  final trimmed = q.trim();
  if (trimmed.length < 2) return [];
  return DatabaseHelper.instance.getSuggestions(trimmed);
});

// ── Is search active ──────────────────────────────────────────────────────────
final isSearchActiveProvider = Provider<bool>(
  (ref) => ref.watch(searchQueryProvider).trim().length >= 2,
);

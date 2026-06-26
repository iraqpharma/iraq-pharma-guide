import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/pricing_database_helper.dart';
import '../data/models/local_pricing_entry.dart';

// ── Search query ─────────────────────────────────────────────────────────────
final pricingSearchQueryProvider = StateProvider<String>((_) => '');

// ── All entries (filtered by search query) ───────────────────────────────────
final pricingEntriesProvider =
    FutureProvider<List<LocalPricingEntry>>((ref) async {
  final query = ref.watch(pricingSearchQueryProvider);
  return PricingDatabaseHelper.instance.search(query);
});

// ── Notifier for CRUD mutations ───────────────────────────────────────────────
class PricingNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  PricingNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> add(LocalPricingEntry entry) async {
    await PricingDatabaseHelper.instance.insert(entry);
    _ref.invalidate(pricingEntriesProvider);
  }

  Future<void> edit(LocalPricingEntry entry) async {
    await PricingDatabaseHelper.instance.update(entry);
    _ref.invalidate(pricingEntriesProvider);
  }

  Future<void> remove(int id) async {
    await PricingDatabaseHelper.instance.delete(id);
    _ref.invalidate(pricingEntriesProvider);
  }
}

final pricingNotifierProvider =
    StateNotifierProvider<PricingNotifier, AsyncValue<void>>(
        (ref) => PricingNotifier(ref));

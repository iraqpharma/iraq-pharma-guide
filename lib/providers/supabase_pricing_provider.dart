import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/pricing_entry.dart';
import '../data/repositories/pricing_repository.dart';

final pricingRepoProvider =
    Provider<PricingRepository>((_) => PricingRepository());

final supabasePricingQueryProvider = StateProvider<String>((_) => '');

// StreamProvider — يستمع لتغييرات Supabase مباشرة
final supabasePricingProvider =
    StreamProvider<List<PricingEntry>>((ref) {
  final query = ref.watch(supabasePricingQueryProvider);
  final repo = ref.watch(pricingRepoProvider);
  return query.isEmpty ? repo.watchAll() : repo.watchSearch(query);
});

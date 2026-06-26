import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/database_helper.dart';
import '../data/models/drug_model.dart';

enum QuickFilter {
  safePregnancy('آمن للحمل', 'pregnancy'),
  pediatricDrops('قطرات أطفال', 'drops'),
  refrigerated('مبرد ❄', 'cold'),
  renalCaution('تعديل كلوي', 'renal');

  const QuickFilter(this.label, this.key);
  final String label;
  final String key;
}

final activeFiltersProvider = StateProvider<Set<QuickFilter>>((_) => {});

final filteredDrugsProvider = FutureProvider<List<Drug>>((ref) async {
  final filters = ref.watch(activeFiltersProvider);
  if (filters.isEmpty) return [];
  final keys = filters.map((f) => f.key).toSet();
  return DatabaseHelper.instance.getByFilters(keys);
});

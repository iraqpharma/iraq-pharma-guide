import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/drug_model.dart';
import '../../providers/drug_provider.dart';
import '../../core/l10n/app_strings.dart';

// ── Junk class names that should not be shown as section headers ───────────────
const _junkClasses = {
  'specialty drug', 'cardiovascular drug', 'cns/psychiatry drug',
  'diabetes/endocrine', 'respiratory/allergy drug', 'antibiotic drug',
  'gastro drug', 'endocrine drug', 'other drug', 'drug',
};

bool _isUsefulClass(String cls) {
  if (cls.isEmpty) return false;
  final lower = cls.toLowerCase();
  if (_junkClasses.contains(lower)) return false;
  // Looks like a brand name list (e.g. "Xanax, Alprazolam")
  final words = cls.split(',').map((w) => w.trim()).toList();
  if (words.every((w) => w.isNotEmpty && w[0] == w[0].toUpperCase() && !w.contains(' '))) {
    return false;
  }
  return true;
}

// ── Provider ──────────────────────────────────────────────────────────────────
final _categoryDrugsProvider =
    FutureProvider.family<List<Drug>, String>((ref, key) async {
  return ref.read(drugRepositoryProvider).getByAppCategory(key);
});

// ── Screen ────────────────────────────────────────────────────────────────────
class DrugListScreen extends ConsumerStatefulWidget {
  final String categoryKey;
  const DrugListScreen({super.key, required this.categoryKey});

  @override
  ConsumerState<DrugListScreen> createState() => _DrugListScreenState();
}

class _DrugListScreenState extends ConsumerState<DrugListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = context.s.categoryLabels[widget.categoryKey] ?? widget.categoryKey;
    final drugsAsync = ref.watch(_categoryDrugsProvider(widget.categoryKey));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Search bar ───────────────────────────────────────────────────
          Container(
            color: AppColors.primaryBlue,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '${context.s.searchInCategory} $title...',
                hintStyle: const TextStyle(color: Colors.white60),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withOpacity(0.15),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ── Drug list ────────────────────────────────────────────────────
          Expanded(
            child: drugsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text('${context.s.error}: $e')),
              data: (drugs) {
                // Filter by search query
                final filtered = _query.isEmpty
                    ? drugs
                    : drugs.where((d) {
                        return d.genericName.toLowerCase().contains(_query) ||
                            d.genericNameAr.contains(_query) ||
                            d.tradeNamesList.any(
                                (t) => t.toLowerCase().contains(_query));
                      }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.medication_outlined,
                            size: 56, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          _query.isEmpty
                              ? context.s.noDrugsInCategory
                              : '${context.s.noResultsPrefix}$_query${context.s.noResultsSuffix}',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                // Sort alphabetically
                final sorted = List<Drug>.from(filtered)
                  ..sort((a, b) => a.genericName
                      .toLowerCase()
                      .compareTo(b.genericName.toLowerCase()));

                // Count label
                return Column(
                  children: [
                    // Count bar
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      color: AppColors.primaryLight,
                      child: Text(
                        context.s.drugCount(filtered.length),
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: sorted.length,
                        separatorBuilder: (_, __) => const Divider(
                            height: 1, indent: 72, endIndent: 16),
                        itemBuilder: (ctx, i) =>
                            _DrugTile(drug: sorted[i]),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Drug tile ─────────────────────────────────────────────────────────────────
class _DrugTile extends StatelessWidget {
  final Drug drug;
  const _DrugTile({required this.drug});

  @override
  Widget build(BuildContext context) {
    final cls = drug.drugClass;
    final showClass = _isUsefulClass(cls);

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.medication_rounded,
            color: AppColors.primaryBlue, size: 22),
      ),
      title: Text(
        drug.genericName,
        style: const TextStyle(
            fontWeight: FontWeight.w700, fontSize: 15),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (drug.tradeNamesList.isNotEmpty)
            Text(
              drug.tradeNamesList.take(3).join(' · '),
              style: TextStyle(
                  fontSize: 12, color: Colors.grey.shade600),
            ),
          if (showClass)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  cls,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.primaryBlue.withOpacity(0.75),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
      trailing: drug.pregnancyCategory.isNotEmpty
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _pregColor(drug.pregnancyCategory),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    drug.pregnancyCategory,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            )
          : const Icon(Icons.chevron_left_rounded,
              color: Color(0xFFCCCCCC)),
      onTap: () => context.push('/drug/${drug.id}'),
    );
  }

  Color _pregColor(String cat) {
    switch (cat) {
      case 'A': return Colors.green.shade600;
      case 'B': return Colors.lightGreen.shade600;
      case 'C': return Colors.orange.shade600;
      case 'D': return Colors.deepOrange.shade600;
      case 'X': return Colors.red.shade700;
      default:  return AppColors.primaryBlue;
    }
  }
}

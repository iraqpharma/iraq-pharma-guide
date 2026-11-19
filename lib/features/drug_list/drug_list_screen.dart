import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/category_style.dart';
import '../../data/models/drug_model.dart';
import '../../data/database/database_helper.dart';
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

// ── Providers ─────────────────────────────────────────────────────────────────
/// `all` is a pseudo-category used by the "view all" action on the home
/// screen. It streams the same local SQLite table, so it adds nothing to the
/// app size and stays lazy through the existing ListView.builder.
final _categoryDrugsProvider =
    FutureProvider.family<List<Drug>, String>((ref, key) async {
  if (key == 'all') return DatabaseHelper.instance.getAllDrugs();
  return ref.read(drugRepositoryProvider).getByAppCategory(key);
});

/// أدوية عائلة واحدة داخل قسم — المفتاح `category|family`.
final _familyDrugsProvider =
    FutureProvider.family<List<Drug>, String>((ref, key) async {
  final i = key.indexOf('|');
  return DatabaseHelper.instance
      .getByFamily(key.substring(0, i), key.substring(i + 1));
});

// ── Screen ────────────────────────────────────────────────────────────────────
class DrugListScreen extends ConsumerStatefulWidget {
  final String categoryKey;

  /// عند تمريرها تُعرض أدوية هذه العائلة فقط (Beta blockers مثلاً).
  final String? familyName;

  const DrugListScreen({
    super.key,
    required this.categoryKey,
    this.familyName,
  });

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
    final fam   = widget.familyName;
    final style = CategoryStyle.of(widget.categoryKey);
    final catTitle = widget.categoryKey == 'all'
        ? context.s.allDrugs
        : (context.s.categoryLabels[widget.categoryKey] ?? widget.categoryKey);
    final title = fam ?? catTitle;

    final drugsAsync = fam == null
        ? ref.watch(_categoryDrugsProvider(widget.categoryKey))
        : ref.watch(_familyDrugsProvider('${widget.categoryKey}|$fam'));

    final headColor =
        widget.categoryKey == 'all' ? AppColors.primary : style.color;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 17)),
            if (fam != null)
              Text(catTitle,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w400)),
          ],
        ),
        backgroundColor: headColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Search bar ───────────────────────────────────────────────────
          Container(
            color: headColor,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
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
                          FocusScope.of(context).unfocus();
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

                // الترتيب: المتوفّر محلياً أولاً ثم الأبجدي — الاستعلام يرتّب
                // أصلاً، وهذا يحفظ الترتيب بعد التصفية بالبحث.
                final sorted = List<Drug>.from(filtered)
                  ..sort((a, b) {
                    final r = a.iraqAvailability.compareTo(b.iraqAvailability);
                    if (r != 0) return r;
                    return a.genericName
                        .toLowerCase()
                        .compareTo(b.genericName.toLowerCase());
                  });

                final availableCount =
                    sorted.where((d) => d.isAvailableInIraq).length;

                return Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      color: headColor.withOpacity(0.08),
                      child: Row(children: [
                        Text(
                          context.s.drugCount(filtered.length),
                          style: TextStyle(
                            color: headColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$availableCount متوفّر محلياً',
                          style: const TextStyle(
                            color: AppColors.successGreen,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ]),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: sorted.length,
                        separatorBuilder: (_, __) => const Divider(
                            height: 1, indent: 72, endIndent: 16),
                        itemBuilder: (ctx, i) =>
                            _DrugTile(drug: sorted[i], accent: headColor),
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
  final Color accent;
  const _DrugTile({required this.drug, required this.accent});

  @override
  Widget build(BuildContext context) {
    final cls = drug.drugClass;
    final showClass = _isUsefulClass(cls);
    final scarce = drug.isScarceInIraq;

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: accent.withOpacity(0.10),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(Icons.medication_outlined, color: accent, size: 21),
      ),
      title: Row(children: [
        Flexible(
          child: Text(
            drug.genericName,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: scarce
                  ? Theme.of(context).colorScheme.onSurface.withOpacity(0.72)
                  : null,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (scarce) ...[
          const SizedBox(width: 7),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.warningAmber.withOpacity(0.14),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              drug.iraqAvailability >= 3 ? 'غير متوفّر' : 'نادر',
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF9A6207),
              ),
            ),
          ),
        ],
      ]),
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
                  color: accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  cls,
                  style: TextStyle(
                    fontSize: 10,
                    color: accent.withOpacity(0.85),
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
      default:  return AppColors.primary;
    }
  }
}

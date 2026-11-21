import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/category_style.dart';
import '../../core/l10n/app_strings.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/drug_model.dart';
import '../../providers/drug_provider.dart';

/// عوائل القسم الواحد — فتح «قلب وأوعية» يعرض Beta blockers وACE inhibitors
/// وغيرها، ثم تُفتح العائلة على أدويتها. العائلة الأغنى بالأدوية المتوفّرة
/// في السوق العراقية تتصدّر القائمة.
final familiesProvider =
    FutureProvider.family<List<DrugFamily>, String>((ref, key) async {
  return DatabaseHelper.instance.familiesOf(key);
});

/// كل أدوية القسم — تُستخدم للبحث داخل القسم، فالمستخدم يبحث عن اسم دواء
/// لا عن اسم عائلة، فيجب أن يظهر الدواء نفسه في النتائج مباشرةً.
final categoryAllDrugsProvider =
    FutureProvider.family<List<Drug>, String>((ref, key) async {
  return ref.read(drugRepositoryProvider).getByAppCategory(key);
});

class CategoryFamiliesScreen extends ConsumerStatefulWidget {
  final String categoryKey;
  const CategoryFamiliesScreen({super.key, required this.categoryKey});

  @override
  ConsumerState<CategoryFamiliesScreen> createState() =>
      _CategoryFamiliesScreenState();
}

class _CategoryFamiliesScreenState
    extends ConsumerState<CategoryFamiliesScreen> {
  final _ctrl = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s     = context.s;
    final style = CategoryStyle.of(widget.categoryKey);
    final title = s.categoryLabels[widget.categoryKey] ?? widget.categoryKey;
    final async     = ref.watch(familiesProvider(widget.categoryKey));
    final searching = _q.length >= 2;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: style.color,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Column(
        children: [
          // ── رأس القسم + البحث داخل العوائل ────────────────────────────
          Container(
            width: double.infinity,
            color: style.color,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: TextField(
              controller: _ctrl,
              onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'ابحث عن دواء في $title…',
                hintStyle: const TextStyle(color: Colors.white70, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                suffixIcon: _q.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () {
                          _ctrl.clear();
                          setState(() => _q = '');
                          FocusScope.of(context).unfocus();
                        },
                      ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.16),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ── نتائج البحث: أسماء أدوية، لا أسماء عوائل ─────────────────
          if (searching)
            Expanded(
              child: _DrugSearchResults(
                categoryKey: widget.categoryKey,
                query: _q,
                color: style.color,
              ),
            )
          else
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('${s.error}: $e')),
              data: (families) {
                final list = families;

                final totalDrugs =
                    families.fold<int>(0, (p, f) => p + f.total);

                if (list.isEmpty) {
                  return Center(
                    child: Text('لا توجد عوائل في هذا القسم',
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 26),
                  itemCount: list.length + 1,
                  itemBuilder: (ctx, i) {
                    if (i == 0) {
                      return _AllDrugsTile(
                        count: totalDrugs,
                        color: style.color,
                        icon: style.icon,
                        onTap: () => context.push(
                            '/category/${widget.categoryKey}/all'),
                      );
                    }
                    final f = list[i - 1];
                    return _FamilyTile(
                      family: f,
                      color: style.color,
                      onTap: () => context.push(
                        '/category/${widget.categoryKey}/family'
                        '/${Uri.encodeComponent(f.name)}',
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AllDrugsTile extends StatelessWidget {
  final int count;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _AllDrugsTile({
    required this.count,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text('كل أدوية القسم',
                    style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ),
              Text('$count',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color.withOpacity(0.8))),
              const SizedBox(width: 4),
              Icon(Icons.chevron_left_rounded,
                  color: color.withOpacity(0.6), size: 22),
            ]),
          ),
        ),
      ),
    );
  }
}

class _FamilyTile extends StatelessWidget {
  final DrugFamily family;
  final Color color;
  final VoidCallback onTap;
  const _FamilyTile({
    required this.family,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: isDark ? cs.surface : Colors.white,
        borderRadius: BorderRadius.circular(15),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: color.withOpacity(0.08),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.07)
                    : const Color(0xFFEEF0F3),
              ),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(children: [
                Container(
                  width: 8,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // اسم العائلة بالإنجليزية — المصطلح الدوائي يبقى كما هو
                      // في المراجع، فلا يلتبس على الصيدلاني.
                      Text(
                        family.name,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(children: [
                        Text('${family.total} دواء',
                            style: TextStyle(
                                fontSize: 11.5,
                                color: cs.onSurfaceVariant)),
                        if (family.available > 0) ...[
                          const SizedBox(width: 9),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.successGreen.withOpacity(0.11),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Text(
                              '${family.available} متوفّر محلياً',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.successGreen,
                              ),
                            ),
                          ),
                        ],
                      ]),
                    ],
                  ),
                ),
                Icon(Icons.chevron_left_rounded,
                    color: cs.onSurfaceVariant.withOpacity(0.5), size: 22),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// نتائج البحث داخل القسم — أسماء الأدوية مباشرةً
// ═══════════════════════════════════════════════════════════════════════════════
class _DrugSearchResults extends ConsumerWidget {
  final String categoryKey;
  final String query;
  final Color  color;
  const _DrugSearchResults({
    required this.categoryKey,
    required this.query,
    required this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(categoryAllDrugsProvider(categoryKey));

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (e, _) => Center(child: Text('${context.s.error}: $e')),
      data: (drugs) {
        final q = query.toLowerCase();

        // ترتيب النتائج: ما يبدأ بالكلمة أولاً، ثم المتوفّر محلياً، ثم أبجدياً.
        int rank(Drug d) {
          final g = d.genericName.toLowerCase();
          if (g.startsWith(q)) return 0;
          if (d.tradeNamesList.any((t) => t.toLowerCase().startsWith(q))) {
            return 1;
          }
          if (g.contains(q)) return 2;
          if (d.genericNameAr.contains(query)) return 2;
          if (d.tradeNamesList.any((t) => t.toLowerCase().contains(q))) {
            return 3;
          }
          return 4; // طابق على اسم العائلة فقط
        }

        final hits = drugs.where((d) {
          return d.genericName.toLowerCase().contains(q) ||
              d.genericNameAr.contains(query) ||
              d.tradeNamesList.any((t) => t.toLowerCase().contains(q)) ||
              d.subclassEn.toLowerCase().contains(q);
        }).toList()
          ..sort((a, b) {
            final r = rank(a).compareTo(rank(b));
            if (r != 0) return r;
            final av = a.iraqAvailability.compareTo(b.iraqAvailability);
            if (av != 0) return av;
            return a.genericName
                .toLowerCase()
                .compareTo(b.genericName.toLowerCase());
          });

        if (hits.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off_rounded,
                    size: 52, color: Colors.grey.shade300),
                const SizedBox(height: 10),
                Text('لا يوجد دواء بهذا الاسم في هذا القسم',
                    style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          );
        }

        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              color: color.withOpacity(0.08),
              child: Text('${hits.length} نتيجة',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color)),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: hits.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 70, endIndent: 16),
                itemBuilder: (ctx, i) =>
                    _SearchHitTile(drug: hits[i], color: color),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SearchHitTile extends StatelessWidget {
  final Drug drug;
  final Color color;
  const _SearchHitTile({required this.drug, required this.color});

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final scarce = drug.isScarceInIraq;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(Icons.medication_outlined, color: color, size: 20),
      ),
      title: Row(children: [
        Flexible(
          child: Text(
            drug.genericName,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (!scarce) ...[
          const SizedBox(width: 7),
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
                color: AppColors.successGreen, shape: BoxShape.circle),
          ),
        ],
      ]),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (drug.tradeNamesList.isNotEmpty)
            Text(drug.tradeNamesList.take(3).join(' · '),
                style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          if (drug.subclassEn.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(drug.subclassEn,
                  style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: color.withOpacity(0.85)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
        ],
      ),
      trailing: Icon(Icons.chevron_left_rounded,
          color: cs.onSurfaceVariant.withOpacity(0.5), size: 22),
      onTap: () => context.push('/drug/${drug.id}'),
    );
  }
}

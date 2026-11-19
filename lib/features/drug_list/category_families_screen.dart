import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/category_style.dart';
import '../../core/l10n/app_strings.dart';
import '../../data/database/database_helper.dart';

/// عوائل القسم الواحد — فتح «قلب وأوعية» يعرض Beta blockers وACE inhibitors
/// وغيرها، ثم تُفتح العائلة على أدويتها. العائلة الأغنى بالأدوية المتوفّرة
/// في السوق العراقية تتصدّر القائمة.
final familiesProvider =
    FutureProvider.family<List<DrugFamily>, String>((ref, key) async {
  return DatabaseHelper.instance.familiesOf(key);
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
    final async = ref.watch(familiesProvider(widget.categoryKey));

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
                hintText: 'ابحث في عوائل $title…',
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

          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('${s.error}: $e')),
              data: (families) {
                final list = _q.isEmpty
                    ? families
                    : families
                        .where((f) => f.name.toLowerCase().contains(_q))
                        .toList();

                final totalDrugs =
                    families.fold<int>(0, (p, f) => p + f.total);

                if (list.isEmpty) {
                  return Center(
                    child: Text('لا توجد عائلة بهذا الاسم',
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

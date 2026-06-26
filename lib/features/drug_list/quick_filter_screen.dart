import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/drug_model.dart';
import '../../providers/drug_provider.dart';

// ── Per-key metadata ──────────────────────────────────────────────────────────

class _FilterMeta {
  final String titleAr;
  final String subtitleAr;
  final IconData icon;
  final Color color;
  final bool showSearch;
  final String? bannerText;
  const _FilterMeta({
    required this.titleAr,
    required this.subtitleAr,
    required this.icon,
    required this.color,
    this.showSearch = false,
    this.bannerText,
  });
}

const _metaMap = <String, _FilterMeta>{
  'pregnancy': _FilterMeta(
    titleAr: 'آمن للحمل',
    subtitleAr: 'أدوية فئة A و B',
    icon: Icons.bolt,
    color: Color(0xFF7C3AED),
  ),
  'drops': _FilterMeta(
    titleAr: 'قطرات أطفال',
    subtitleAr: 'أدوية بجرعة قطرات للأطفال',
    icon: Icons.wb_sunny_outlined,
    color: Color(0xFFF97316),
  ),
  'cold': _FilterMeta(
    titleAr: 'أدوية تحتاج تبريداً',
    subtitleAr: 'يجب حفظها في البراد',
    icon: Icons.ac_unit_rounded,
    color: Color(0xFF3B82F6),
    showSearch: true,
    bannerText:
        '❄️  تنبيه: جميع الأدوية أدناه تحتاج إلى حفظها في الثلاجة بين 2–8 °C. '
        'يُرجى التحقق دائماً قبل الصرف.',
  ),
  'renal': _FilterMeta(
    titleAr: 'تعديل كلوي',
    subtitleAr: 'أدوية تستلزم تعديل الجرعة في القصور الكلوي',
    icon: Icons.calculate_outlined,
    color: Color(0xFF10B981),
  ),
};

// ── Provider ──────────────────────────────────────────────────────────────────

final _quickFilterDrugsProvider =
    FutureProvider.family<List<Drug>, String>((ref, key) async {
  return DatabaseHelper.instance.getByFilters({key});
});

final _refrigSearchProvider = StateProvider<String>((_) => '');

// ── Screen ────────────────────────────────────────────────────────────────────

class QuickFilterScreen extends ConsumerStatefulWidget {
  final String filterKey;
  const QuickFilterScreen({super.key, required this.filterKey});

  @override
  ConsumerState<QuickFilterScreen> createState() => _QuickFilterScreenState();
}

class _QuickFilterScreenState extends ConsumerState<QuickFilterScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    // Clear search state when leaving
    Future.microtask(
        () => ref.read(_refrigSearchProvider.notifier).state = '');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final meta = _metaMap[widget.filterKey] ??
        const _FilterMeta(
          titleAr: 'فلتر',
          subtitleAr: '',
          icon: Icons.filter_list,
          color: AppColors.primary,
        );
    final drugsAsync = ref.watch(_quickFilterDrugsProvider(widget.filterKey));
    final searchQ = ref.watch(_refrigSearchProvider).toLowerCase().trim();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Custom header ───────────────────────────────────────────────
          Container(
            color: meta.color,
            padding: EdgeInsets.fromLTRB(
                8, MediaQuery.of(context).padding.top + 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back row
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 20),
                      onPressed: () => context.pop(),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(meta.icon,
                              color: Colors.white, size: 14),
                          const SizedBox(width: 5),
                          Text(meta.subtitleAr,
                              style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 0, 0),
                  child: Text(
                    meta.titleAr,
                    style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                // Search bar — only for refrigerated
                if (meta.showSearch) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _SearchField(
                      controller: _searchCtrl,
                      onChanged: (v) => ref
                          .read(_refrigSearchProvider.notifier)
                          .state = v,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Instruction banner ─────────────────────────────────────────
          if (meta.bannerText != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF90CAF9), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Color(0xFF1565C0), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      meta.bannerText!,
                      style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: const Color(0xFF1565C0),
                          height: 1.5),
                    ),
                  ),
                ],
              ),
            ),

          // ── Drug list ──────────────────────────────────────────────────
          Expanded(
            child: drugsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text('خطأ: $e')),
              data: (drugs) {
                // Apply search filter for refrigerated
                final filtered = searchQ.isEmpty
                    ? drugs
                    : drugs
                        .where((d) =>
                            d.genericName
                                .toLowerCase()
                                .contains(searchQ) ||
                            d.genericNameAr.contains(searchQ) ||
                            d.tradeNamesList.any((t) =>
                                t.toLowerCase().contains(searchQ)))
                        .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.medication_outlined,
                            size: 60,
                            color: AppColors.textSecondary
                                .withOpacity(0.35)),
                        const SizedBox(height: 14),
                        Text(
                          searchQ.isNotEmpty
                              ? 'لا توجد نتائج'
                              : 'لا توجد أدوية في هذا القسم',
                          style: GoogleFonts.cairo(
                              fontSize: 15,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 10),
                  itemBuilder: (ctx, i) =>
                      _DrugCard(drug: filtered[i], accentColor: meta.color),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Search field widget ───────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchField(
      {required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textDirection: TextDirection.rtl,
        style: GoogleFonts.cairo(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'ابحث عن اسم الدواء...',
          hintStyle: GoogleFonts.cairo(
              color: AppColors.textSecondary, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppColors.primary),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close,
                      color: AppColors.textSecondary, size: 18),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

// ── Drug card ─────────────────────────────────────────────────────────────────

class _DrugCard extends StatelessWidget {
  final Drug drug;
  final Color accentColor;
  const _DrugCard({required this.drug, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/drug/${drug.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.medication_outlined,
                  color: accentColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(drug.genericName,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textPrimary)),
                  if (drug.genericNameAr.isNotEmpty)
                    Text(drug.genericNameAr,
                        style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                  if (drug.tradeNamesList.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      drug.tradeNamesList.take(3).join(' · '),
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

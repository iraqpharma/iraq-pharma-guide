import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/drug_model.dart';
import '../../providers/drug_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/interaction_provider.dart';
import '../../providers/favorites_provider.dart';

final _drugDetailProvider =
    FutureProvider.family<Drug?, int>((ref, id) async {
  return ref.read(drugRepositoryProvider).getById(id);
});

class DrugDetailScreen extends ConsumerWidget {
  final int drugId;
  const DrugDetailScreen({super.key, required this.drugId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drugAsync = ref.watch(_drugDetailProvider(drugId));
    return drugAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text('Error: $e'))),
      data: (drug) {
        if (drug == null) {
          return const Scaffold(
              body: Center(child: Text('الدواء غير موجود')));
        }
        return Consumer(builder: (context, ref2, _) {
          final locale = ref2.watch(localeProvider);
          return _DrugDetailView(
              drug: drug, isArabic: locale.languageCode == 'ar');
        });
      },
    );
  }
}

// ─── Main View ────────────────────────────────────────────────────────────────

class _DrugDetailView extends StatelessWidget {
  final Drug drug;
  final bool isArabic;
  const _DrugDetailView({required this.drug, this.isArabic = true});

  String get _note => isArabic && drug.counselingNoteAr.isNotEmpty
      ? drug.counselingNoteAr
      : drug.counselingNote;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          // ── Custom AppBar ────────────────────────────────────────────────
          _DrugAppBar(drug: drug, isArabic: isArabic),

          // ── LASA Banner ──────────────────────────────────────────────────
          if (drug.isLasa) _LasaBanner(names: drug.lasaNames),

          // ── Content ──────────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                // Trade names & class
                _HeaderSection(drug: drug, isArabic: isArabic),
                const SizedBox(height: 12),

                // Pharmacist note
                if (_note.isNotEmpty) _CounselingCard(note: _note),

                // Clinical info tiles
                _InfoTile(
                  icon: Icons.biotech_outlined,
                  color: AppColors.primary,
                  title: 'آلية العمل',
                  content: isArabic && drug.mechanismAr.isNotEmpty
                      ? drug.mechanismAr : drug.mechanism,
                ),
                _InfoTile(
                  icon: Icons.assignment_turned_in_outlined,
                  color: AppColors.successGreen,
                  title: 'الاستطبابات',
                  content: isArabic && drug.indicationsAr.isNotEmpty
                      ? drug.indicationsAr : drug.indications,
                ),
                _InfoTile(
                  icon: Icons.person_outline,
                  color: const Color(0xFF5C6BC0),
                  title: 'جرعة البالغين',
                  content: isArabic && drug.adultDoseAr.isNotEmpty
                      ? drug.adultDoseAr : drug.adultDose,
                ),
                _InfoTile(
                  icon: Icons.child_care_outlined,
                  color: const Color(0xFF8E44AD),
                  title: 'جرعة الأطفال',
                  content: drug.pediatricDose,
                ),
                _InfoTile(
                  icon: Icons.water_drop_outlined,
                  color: const Color(0xFF0097A7),
                  title: 'تعديل القصور الكلوي',
                  content: drug.renalDose,
                ),
                _InfoTile(
                  icon: Icons.local_hospital_outlined,
                  color: AppColors.warningAmber,
                  title: 'تعديل القصور الكبدي',
                  content: drug.hepaticDose,
                ),
                _InfoTile(
                  icon: Icons.block_outlined,
                  color: AppColors.errorRed,
                  title: 'موانع الاستعمال',
                  content: drug.contraindications,
                ),
                _InfoTile(
                  icon: Icons.sick_outlined,
                  color: const Color(0xFFE65100),
                  title: 'الأعراض الجانبية',
                  content: isArabic && drug.sideEffectsAr.isNotEmpty
                      ? drug.sideEffectsAr : drug.sideEffects,
                ),
                _InfoTile(
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.errorRed,
                  title: 'التفاعلات الدوائية',
                  content: isArabic && drug.interactionsAr.isNotEmpty
                      ? drug.interactionsAr : drug.interactions,
                ),

                // IV Reconstitution
                if (drug.ivReconstitution.isNotEmpty)
                  _IvCard(info: drug.ivReconstitution),

                // Pregnancy & Lactation
                _PregnancyLactationSection(drug: drug),

                // Iraq market note
                if (drug.iraqMarketNote.isNotEmpty)
                  _IraqNoteCard(note: drug.iraqMarketNote),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),

      // ── Bottom Action Buttons ─────────────────────────────────────────────
      bottomNavigationBar: _BottomActions(drug: drug),
    );
  }
}

// ─── Custom AppBar ────────────────────────────────────────────────────────────

class _DrugAppBar extends StatelessWidget {
  final Drug drug;
  final bool isArabic;
  const _DrugAppBar({required this.drug, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(top: top),
      child: Column(
        children: [
          // Title row
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white, size: 20),
                  onPressed: () => context.pop(),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        drug.genericName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (drug.genericNameAr.isNotEmpty)
                        Text(
                          drug.genericNameAr,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                          maxLines: 1,
                        ),
                    ],
                  ),
                ),
                if (drug.isRefrigerated)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.ac_unit, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text('مبرد',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Drug class + route chips strip
          if (drug.drugClass.isNotEmpty)
            Container(
              color: AppColors.darkNavy.withOpacity(0.3),
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.category_outlined,
                      color: Colors.white70, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isArabic && drug.drugClassAr.isNotEmpty
                          ? drug.drugClassAr
                          : drug.drugClass,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Header Section (trade names) ─────────────────────────────────────────────

class _HeaderSection extends StatelessWidget {
  final Drug drug;
  final bool isArabic;
  const _HeaderSection({required this.drug, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    if (drug.tradeNamesList.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('الأسماء التجارية',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: drug.tradeNamesList
              .map((name) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Text(name,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary)),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

// ─── LASA Banner ──────────────────────────────────────────────────────────────

class _LasaBanner extends StatelessWidget {
  final String names;
  const _LasaBanner({required this.names});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      color: const Color(0xFFFFF8E1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline,
              color: Color(0xFF856404), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('LASA WARNING',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF664D03),
                        fontSize: 12,
                        letterSpacing: 0.5)),
                const Text(
                    'Look-Alike Sound-Alike: verify spelling and route',
                    style: TextStyle(
                        color: Color(0xFF856404), fontSize: 11)),
                if (names.isNotEmpty)
                  Text('Frequently confused with: $names',
                      style: const TextStyle(
                          color: Color(0xFF856404),
                          fontSize: 11,
                          fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Counseling Card ──────────────────────────────────────────────────────────

class _CounselingCard extends StatelessWidget {
  final String note;
  const _CounselingCard({required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.tips_and_updates,
                color: AppColors.accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('نصيحة الصيدلاني',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 12)),
                const SizedBox(height: 4),
                Text(note,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Clinical Info Tile ───────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String content;
  const _InfoTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    if (content.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: ExpansionTile(
        tilePadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, color: color, size: 18),
        ),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: 14)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 10),
          Text(content,
              style: const TextStyle(
                  height: 1.65,
                  color: AppColors.textPrimary,
                  fontSize: 13)),
        ],
      ),
    );
  }
}

// ─── IV Reconstitution Card ───────────────────────────────────────────────────

class _IvCard extends StatelessWidget {
  final String info;
  const _IvCard({required this.info});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0097A7).withOpacity(0.4)),
      ),
      child: ExpansionTile(
        tilePadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFF0097A7).withOpacity(0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Icon(Icons.vaccines,
              color: Color(0xFF0097A7), size: 18),
        ),
        title: const Text('IV — التحضير والإعطاء',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF0097A7),
                fontSize: 14)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 10),
          Text(info,
              style: const TextStyle(
                  height: 1.65,
                  color: AppColors.textPrimary,
                  fontSize: 13)),
        ],
      ),
    );
  }
}

// ─── Pregnancy & Lactation ────────────────────────────────────────────────────

class _PregnancyLactationSection extends StatelessWidget {
  final Drug drug;
  const _PregnancyLactationSection({required this.drug});

  bool get _has =>
      drug.pregnancyCategory.isNotEmpty || drug.lactationSafety.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (!_has) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF0F4FF),
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: const [
                Icon(Icons.pregnant_woman,
                    color: Color(0xFF5C6BC0), size: 18),
                SizedBox(width: 8),
                Text('الحمل والرضاعة',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5C6BC0),
                        fontSize: 13)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (drug.pregnancyCategory.isNotEmpty)
                  Expanded(
                      child: _PregnancyBadge(
                          category: drug.pregnancyCategory)),
                if (drug.pregnancyCategory.isNotEmpty &&
                    drug.lactationSafety.isNotEmpty)
                  const SizedBox(width: 10),
                if (drug.lactationSafety.isNotEmpty)
                  Expanded(
                      child: _LactationBadge(
                          safety: drug.lactationSafety)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PregnancyBadge extends StatelessWidget {
  final String category;
  const _PregnancyBadge({required this.category});

  static const _info = {
    'A': ('آمن', AppColors.successGreen),
    'B': ('آمن نسبياً', AppColors.accent),
    'C': ('بحذر', AppColors.warningAmber),
    'D': ('خطر', AppColors.errorRed),
    'X': ('ممنوع', AppColors.errorRed),
  };

  @override
  Widget build(BuildContext context) {
    final data = _info[category.toUpperCase()] ??
        ('غير محدد', AppColors.textSecondary);
    final color = data.$2;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(category,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
          ),
          const SizedBox(height: 6),
          const Text('فئة الحمل',
              style: TextStyle(
                  fontSize: 10, color: AppColors.textSecondary)),
          Text(data.$1,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 12)),
        ],
      ),
    );
  }
}

class _LactationBadge extends StatelessWidget {
  final String safety;
  const _LactationBadge({required this.safety});

  Color _color(int l) => switch (l) {
        1 => AppColors.successGreen,
        2 => AppColors.accent,
        3 => AppColors.warningAmber,
        _ => AppColors.errorRed,
      };

  String _label(int l) => switch (l) {
        1 => 'L1 آمن جداً',
        2 => 'L2 آمن',
        3 => 'L3 بحذر',
        4 => 'L4 خطر',
        5 => 'L5 ممنوع',
        _ => 'غير محدد',
      };

  @override
  Widget build(BuildContext context) {
    final m = RegExp(r'L(\d)').firstMatch(safety);
    final level = m != null ? int.tryParse(m.group(1)!) ?? 0 : 0;
    final color = _color(level);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.child_friendly, color: color, size: 28),
          const SizedBox(height: 6),
          const Text('الرضاعة (Hale)',
              style: TextStyle(
                  fontSize: 10, color: AppColors.textSecondary)),
          Text(_label(level),
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 12),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ─── Iraq Market Note ─────────────────────────────────────────────────────────

class _IraqNoteCard extends StatelessWidget {
  final String note;
  const _IraqNoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.successGreen.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: AppColors.successGreen.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.store_outlined,
              color: AppColors.successGreen, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(note,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom Action Buttons ────────────────────────────────────────────────────

class _BottomActions extends ConsumerWidget {
  final Drug drug;
  const _BottomActions({required this.drug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favIds    = ref.watch(favoritesProvider);
    final isFav     = favIds.contains(drug.id);
    final favNotifier = ref.read(favoritesProvider.notifier);

    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          // ── المفضلة — toggles between outlined and filled-red ──────────
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isFav ? const Color(0xFFD32F2F) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isFav
                      ? const Color(0xFFD32F2F)
                      : AppColors.primary,
                ),
              ),
              child: TextButton.icon(
                onPressed: () async {
                  await favNotifier.toggle(drug.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isFav
                              ? 'تم الإزالة من المفضلة'
                              : '${drug.genericName} أُضيف للمفضلة',
                        ),
                        backgroundColor: isFav
                            ? const Color(0xFFD32F2F)
                            : AppColors.primary,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                icon: Icon(
                  isFav ? Icons.bookmark_rounded : Icons.bookmark_border,
                  size: 18,
                  color: isFav ? Colors.white : AppColors.primary,
                ),
                label: Text(
                  'المفضلة',
                  style: TextStyle(
                    fontSize: 13,
                    color: isFav ? Colors.white : AppColors.primary,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // ── التفاعلات ───────────────────────────────────────────────────
          Expanded(
            child: FilledButton.icon(
              onPressed: () {
                ref.read(checkerDrugsProvider.notifier).clear();
                ref.read(checkerDrugsProvider.notifier).add(drug);
                context.push('/interactions');
              },
              icon: const Icon(Icons.warning_amber_rounded, size: 18),
              label: const Text('التفاعلات',
                  style: TextStyle(fontSize: 13)),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

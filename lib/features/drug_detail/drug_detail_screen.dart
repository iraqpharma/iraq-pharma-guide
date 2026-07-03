import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/drug_model.dart';
import '../../providers/drug_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/interaction_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../core/l10n/app_strings.dart';

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
          return Scaffold(
              body: Center(child: Builder(builder: (ctx) => Text(ctx.s.drugNotFound))));
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

  String get _note => drug.counselingNote;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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

                // Dosage form & route
                if (drug.dosageForm.isNotEmpty) _DosageFormCard(text: drug.dosageForm),

                // Available doses
                if (drug.availableDoses.isNotEmpty) _AvailableDosesCard(text: drug.availableDoses),

                // Pharmacist note
                if (_note.isNotEmpty) _CounselingCard(note: _note),

                // Clinical info tiles
                _InfoTile(
                  icon: Icons.biotech_outlined,
                  color: AppColors.primary,
                  title: context.s.mechanism,
                  content: drug.mechanism,
                ),
                _InfoTile(
                  icon: Icons.assignment_turned_in_outlined,
                  color: AppColors.successGreen,
                  title: context.s.indications,
                  content: drug.indications,
                ),
                _InfoTile(
                  icon: Icons.person_outline,
                  color: const Color(0xFF5C6BC0),
                  title: context.s.adultDose,
                  content: drug.adultDose,
                ),
                _InfoTile(
                  icon: Icons.child_care_outlined,
                  color: const Color(0xFF8E44AD),
                  title: context.s.pediatricDose,
                  content: drug.pediatricDose,
                ),
                _InfoTile(
                  icon: Icons.water_drop_outlined,
                  color: const Color(0xFF0097A7),
                  title: context.s.renalDose,
                  content: drug.renalDose,
                ),
                _InfoTile(
                  icon: Icons.local_hospital_outlined,
                  color: AppColors.warningAmber,
                  title: context.s.hepaticDose,
                  content: drug.hepaticDose,
                ),
                _InfoTile(
                  icon: Icons.block_outlined,
                  color: AppColors.errorRed,
                  title: context.s.contraindications,
                  content: drug.contraindications,
                ),
                _InfoTile(
                  icon: Icons.sick_outlined,
                  color: const Color(0xFFE65100),
                  title: context.s.sideEffects,
                  content: drug.sideEffects,
                ),
                _InfoTile(
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.errorRed,
                  title: context.s.drugInteractions,
                  content: drug.interactions,
                ),

                // Administration notes
                if (drug.administrationNotes.isNotEmpty)
                  _InfoTile(
                    icon: Icons.medication_liquid_outlined,
                    color: const Color(0xFF00897B),
                    title: context.s.administrationTitle,
                    content: drug.administrationNotes,
                  ),

                // Monitoring
                if (drug.monitoringNotes.isNotEmpty)
                  _InfoTile(
                    icon: Icons.monitor_heart_outlined,
                    color: const Color(0xFF5C6BC0),
                    title: context.s.monitoringTitle,
                    content: drug.monitoringNotes,
                  ),

                // Black box warning
                if (drug.blackBox.isNotEmpty)
                  _BlackBoxCard(text: drug.blackBox),

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

void _shareDrug(BuildContext context, Drug drug) {
  final buf = StringBuffer();
  buf.writeln('💊 ${drug.genericName}');
  if (drug.genericNameAr.isNotEmpty) buf.writeln('${drug.genericNameAr}');
  if (drug.drugClass.isNotEmpty) buf.writeln('📂 ${drug.drugClass}');
  if (drug.availableDoses.isNotEmpty) buf.writeln('\n🔹 الجرع المتوفرة:\n${drug.availableDoses}');
  if (drug.adultDose.isNotEmpty) buf.writeln('\n👤 جرعة البالغين:\n${drug.adultDose}');
  buf.writeln('\n🔗 Iraq Pharma Guide');
  Share.share(buf.toString(), subject: drug.genericName);
}

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
                IconButton(
                  icon: const Icon(Icons.share_rounded,
                      color: Colors.white, size: 22),
                  onPressed: () => _shareDrug(context, drug),
                  tooltip: 'مشاركة',
                ),
                if (drug.isRefrigerated)
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
                        const Icon(Icons.ac_unit, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(context.s.refrigeratedLabel,
                            style: const TextStyle(
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
                      drug.drugClass,
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
        Text(context.s.tradeNames,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Text(name,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface)),
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

// ─── Dosage Form Card ─────────────────────────────────────────────────────────

class _DosageFormCard extends StatelessWidget {
  final String text;
  const _DosageFormCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1976D2).withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF1976D2).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.medication_outlined,
                color: Color(0xFF1976D2), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('شكل الدواء وطريقة الإعطاء',
                    style: GoogleFonts.ibmPlexSansArabic(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1976D2),
                        fontSize: 12)),
                const SizedBox(height: 4),
                Text(text,
                    style: const TextStyle(
                        fontSize: 13,
                        height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Available Doses Card ─────────────────────────────────────────────────────

class _AvailableDosesCard extends StatelessWidget {
  final String text;
  const _AvailableDosesCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF7B1FA2).withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF7B1FA2).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.local_pharmacy_outlined,
                color: Color(0xFF7B1FA2), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الجرع المتوفرة',
                    style: GoogleFonts.ibmPlexSansArabic(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF7B1FA2),
                        fontSize: 12)),
                const SizedBox(height: 4),
                Text(text,
                    style: const TextStyle(
                        fontSize: 13,
                        height: 1.5)),
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
        color: Theme.of(context).colorScheme.surface,
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
                Text(context.s.pharmacistNote,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 12)),
                const SizedBox(height: 4),
                Text(note,
                    style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface,
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
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
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 10),
          Text(content,
              style: TextStyle(
                  height: 1.65,
                  color: Theme.of(context).colorScheme.onSurface,
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
        color: Theme.of(context).colorScheme.surface,
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
        title: Text(context.s.ivTitle,
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
              style: TextStyle(
                  height: 1.65,
                  color: Theme.of(context).colorScheme.onSurface,
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.pregnant_woman,
                    color: Color(0xFF5C6BC0), size: 18),
                const SizedBox(width: 8),
                Text(context.s.pregnancyLactation,
                    style: const TextStyle(
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

  Map<String, (String, Color)> _info(AppStrings s) => {
    'A': (s.pregSafe,     AppColors.successGreen),
    'B': (s.pregRelSafe,  AppColors.accent),
    'C': (s.pregCaution,  AppColors.warningAmber),
    'D': (s.pregRisk,     AppColors.errorRed),
    'X': (s.pregContra,   AppColors.errorRed),
  };

  @override
  Widget build(BuildContext context) {
    final data = _info(context.s)[category.toUpperCase()] ??
        (context.s.unknown, AppColors.textSecondary);
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
          Text(context.s.pregnancyCat,
              style: TextStyle(
                  fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
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

  String _label(int l, AppStrings s) => switch (l) {
        1 => s.lactL1,
        2 => s.lactL2,
        3 => s.lactL3,
        4 => s.lactL4,
        5 => s.lactL5,
        _ => s.unknown,
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
          Text(context.s.lactationHale,
              style: TextStyle(
                  fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Text(_label(level, context.s),
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
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ─── Black Box Warning Card ───────────────────────────────────────────────────
class _BlackBoxCard extends StatelessWidget {
  final String text;
  const _BlackBoxCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFB71C1C).withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB71C1C).withOpacity(0.5)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Row(children: [
          const Spacer(),
          Text(context.s.blackBoxWarning,
              style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 13, fontWeight: FontWeight.bold,
                  color: const Color(0xFFB71C1C))),
          const SizedBox(width: 8),
          const Icon(Icons.warning_rounded,
              color: Color(0xFFB71C1C), size: 18),
        ]),
        const SizedBox(height: 8),
        Text(text,
            textAlign: TextAlign.right,
            style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 13, color: const Color(0xFFB71C1C), height: 1.6)),
      ]),
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
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
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
                              ? context.s.removedFromFav
                              : context.s.addedToFavMsg(drug.genericName),
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
                  context.s.favorites,
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
              label: Text(context.s.interactions,
                  style: const TextStyle(fontSize: 13)),
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

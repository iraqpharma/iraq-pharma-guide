import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/l10n/app_strings.dart';
import '../../data/models/otc_condition.dart';

class OtcConditionDetailsScreen extends StatelessWidget {
  final OtcCondition condition;
  final Color accentColor;
  const OtcConditionDetailsScreen({
    super.key,
    required this.condition,
    this.accentColor = const Color(0xFF00897B),
  });

  @override
  Widget build(BuildContext context) {
    final c = accentColor;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(slivers: [

        // ── App bar — NO FlexibleSpaceBar title to avoid overlap ────────────
        SliverAppBar(
          expandedHeight: 170,
          pinned: true,
          backgroundColor: c,
          foregroundColor: Colors.white,
          elevation: 0,
          // Show title only when collapsed (LayoutBuilder approach)
          title: _CollapsingTitle(condition: condition, color: c),
          flexibleSpace: FlexibleSpaceBar(
            // We do NOT set title here — handled by SliverAppBar.title above
            collapseMode: CollapseMode.parallax,
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [c.withOpacity(0.85), c],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 54, height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(condition.icon, color: Colors.white, size: 26),
                      ),
                      const SizedBox(height: 10),
                      Text(condition.nameAr,
                          style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      Text(condition.nameEn,
                          style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.80))),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── Drug count banner ─────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: c.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.withOpacity(0.15)),
            ),
            child: Row(children: [
              Icon(Icons.medication_rounded, color: c, size: 18),
              const SizedBox(width: 8),
              Text(
                context.s.otcDrugsFor(condition.drugs.length,
                    context.s.isAr ? condition.nameAr : condition.nameEn),
                style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: c),
              ),
            ]),
          ),
        ),

        // ── Drug cards ─────────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _DrugCard(
                  drug: condition.drugs[i],
                  accentColor: c,
                  index: i),
              childCount: condition.drugs.length,
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Title only appears when the SliverAppBar is collapsed ─────────────────────
class _CollapsingTitle extends StatelessWidget {
  final OtcCondition condition;
  final Color color;
  const _CollapsingTitle({required this.condition, required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      // If we're in the app bar (narrow), show; otherwise transparent
      final appBarWidth = MediaQuery.of(context).size.width;
      final isCollapsed = constraints.maxWidth < appBarWidth * 0.9;
      return AnimatedOpacity(
        opacity: isCollapsed ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 150),
        child: Text(condition.nameAr,
            style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      );
    });
  }
}

// ─── Drug card ─────────────────────────────────────────────────────────────────
class _DrugCard extends StatefulWidget {
  final OtcDrug drug;
  final Color accentColor;
  final int index;
  const _DrugCard(
      {required this.drug, required this.accentColor, required this.index});

  @override
  State<_DrugCard> createState() => _DrugCardState();
}

class _DrugCardState extends State<_DrugCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.accentColor;
    final drug = widget.drug;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Header (always visible) ──────────────────────────────────────
        InkWell(
          borderRadius: BorderRadius.vertical(
            top: const Radius.circular(18),
            bottom: _expanded ? Radius.zero : const Radius.circular(18),
          ),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              // Index badge
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                    color: c.withOpacity(0.12), shape: BoxShape.circle),
                child: Center(
                  child: Text('${widget.index + 1}',
                      style: TextStyle(
                          color: c,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(drug.brandName,
                    style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 2),
                Text(drug.activeIngredient,
                    style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 11.5, color: Colors.grey.shade500)),
              ])),
              // Route badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: c.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(drug.route,
                    style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 10, color: c,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              AnimatedRotation(
                turns: _expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(Icons.keyboard_arrow_down_rounded,
                    color: c, size: 24),
              ),
            ]),
          ),
        ),

        // ── Expanded details ─────────────────────────────────────────────
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Column(children: [
            Divider(height: 1, color: Theme.of(context).dividerColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // Warning
                if (drug.warning != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.red.shade700, size: 16),
                        const SizedBox(width: 6),
                        Expanded(child: Text(drug.warning!,
                            style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 11.5,
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w500))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                _InfoRow(icon: Icons.timelapse_rounded,
                    label: context.s.dosage_, value: drug.dosage, color: c),
                const SizedBox(height: 10),
                // Counseling
                Row(children: [
                  Icon(Icons.record_voice_over_rounded, color: c, size: 16),
                  const SizedBox(width: 6),
                  Text(context.s.pharmacistCounseling,
                      style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: c)),
                ]),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(drug.counseling,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 12.5,
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.7)),
                ),
              ]),
            ),
          ]),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
        ),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _InfoRow(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 15),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 10.5,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 13,
                color: const Color(0xFF2D3748),
                fontWeight: FontWeight.w600)),
      ])),
    ]);
  }
}

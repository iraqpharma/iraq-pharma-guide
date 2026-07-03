import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/l10n/app_strings.dart';
import '../../data/models/otc_condition.dart';
import 'otc_condition_details_screen.dart';

class OtcCategoryScreen extends StatelessWidget {
  final OtcCategory category;
  const OtcCategoryScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final c = category.color;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(slivers: [

        // ── App bar ─────────────────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 168,
          pinned: true,
          backgroundColor: c,
          foregroundColor: Colors.white,
          elevation: 0,
          flexibleSpace: LayoutBuilder(
            builder: (ctx, constraints) {
              final isCollapsed =
                  constraints.maxHeight <= kToolbarHeight + 20;
              return FlexibleSpaceBar(
                centerTitle: true,
                titlePadding: const EdgeInsets.only(bottom: 14),
                title: isCollapsed
                    ? Text(category.nameAr,
                        style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white))
                    : const SizedBox.shrink(),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        c.withOpacity(0.85),
                        c,
                        c.withOpacity(0.9),
                      ],
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
                            width: 50, height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.22),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(category.icon,
                                color: Colors.white, size: 24),
                          ),
                          const SizedBox(height: 10),
                          Text(category.nameAr,
                              style: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          Text(
                              context.s.nConditions(category.conditions.length),
                              style: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.80))),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // ── Section label ────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
            child: Text(
              context.s.chooseCondition,
              textAlign: TextAlign.right,
              style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ),

        // ── Condition pills ──────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _ConditionPill(
                condition: category.conditions[i],
                accentColor: c,
                onTap: () => Navigator.push(
                  ctx,
                  MaterialPageRoute(
                    builder: (_) => OtcConditionDetailsScreen(
                      condition: category.conditions[i],
                      accentColor: c,
                    ),
                  ),
                ),
              ),
              childCount: category.conditions.length,
            ),
          ),
        ),
      ]),
    );
  }
}

// ─── Condition pill ────────────────────────────────────────────────────────────
class _ConditionPill extends StatelessWidget {
  final OtcCondition condition;
  final Color accentColor;
  final VoidCallback onTap;
  const _ConditionPill({
    required this.condition,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = accentColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: c.withOpacity(0.10),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(children: [
          Icon(Icons.arrow_forward_ios_rounded,
              color: c.withOpacity(0.35), size: 14),
          const Spacer(),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(condition.nameAr,
                style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface)),
            Text(context.s.nDrugsAvail(condition.drugs.length),
                style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 11.5, color: Colors.grey.shade500)),
          ]),
          const SizedBox(width: 14),
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: c.withOpacity(0.11),
              shape: BoxShape.circle,
            ),
            child: Icon(condition.icon, color: c, size: 22),
          ),
        ]),
      ),
    );
  }
}

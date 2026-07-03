import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_strings.dart';
import '../../data/models/otc_condition.dart';
import '../../services/auth_service.dart';
import 'otc_category_screen.dart';

class OtcScreen extends StatefulWidget {
  const OtcScreen({super.key});
  @override
  State<OtcScreen> createState() => _OtcScreenState();
}

class _OtcScreenState extends State<OtcScreen> {
  final _searchCtrl = TextEditingController();
  List<OtcCategory> _filtered = kOtcCategories;

  @override
  void initState() {
    super.initState();
    AuthService.instance.incrementToolUsage();
    _searchCtrl.addListener(_onSearch);
  }

  void _onSearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? kOtcCategories
          : kOtcCategories.where((cat) =>
              cat.nameAr.toLowerCase().contains(q) ||
              cat.nameEn.toLowerCase().contains(q) ||
              cat.conditions.any((c) =>
                  c.nameAr.toLowerCase().contains(q) ||
                  c.drugs.any((d) => d.brandName.toLowerCase().contains(q)))).toList();
    });
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearch);
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(children: [
        _buildHeader(),
        _buildSearchBar(),
        Expanded(
          child: _filtered.isEmpty
              ? _buildEmpty()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) =>
                      _CategoryPill(category: _filtered[i]),
                ),
        ),
      ]),
    );
  }

  Widget _buildHeader() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF003D33), Color(0xFF00897B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: SafeArea(bottom: false, child: Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 16, 20),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: 42),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(context.s.otcTitle,
              style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 18, fontWeight: FontWeight.bold,
                  color: Colors.white)),
          Text(context.s.otcChooseSectionHint,
              style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 11, color: Colors.white.withOpacity(0.78))),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(context.s.nSections(_filtered.length),
              style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 12, color: Colors.white,
                  fontWeight: FontWeight.w600)),
        ),
      ]),
    )),
  );

  Widget _buildSearchBar() => Container(
    color: Theme.of(context).colorScheme.surface,
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
    child: TextField(
      controller: _searchCtrl,
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      style: GoogleFonts.ibmPlexSansArabic(fontSize: 14),
      decoration: InputDecoration(
        hintText: context.s.otcSearchHint,
        hintStyle: GoogleFonts.ibmPlexSansArabic(
            color: Colors.grey.shade400, fontSize: 13),
        prefixIcon: _searchCtrl.text.isEmpty
            ? const Icon(Icons.search_rounded, color: Color(0xFF00897B))
            : IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.grey),
                onPressed: _searchCtrl.clear,
              ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF00897B), width: 1.5)),
      ),
    ),
  );

  Widget _buildEmpty() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFF00897B).withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.search_off_rounded,
            size: 38, color: Color(0xFF00897B)),
      ),
      const SizedBox(height: 16),
      Text(context.s.noResults,
          style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 15, fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface)),
    ]),
  );
}

// ─── Category pill card ───────────────────────────────────────────────────────
class _CategoryPill extends StatelessWidget {
  final OtcCategory category;
  const _CategoryPill({required this.category});

  @override
  Widget build(BuildContext context) {
    final c = category.color;
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(
              builder: (_) => OtcCategoryScreen(category: category))),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(50), // full pill/capsule shape
          boxShadow: [
            BoxShadow(
              color: c.withOpacity(0.13),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(children: [
          // Arrow on far left
          Icon(Icons.arrow_forward_ios_rounded,
              color: c.withOpacity(0.4), size: 15),
          const Spacer(),
          // Text block
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(category.nameAr,
                style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 3),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Text(context.s.nConditions(category.conditions.length),
                  style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 11.5, color: Colors.grey.shade500)),
              const SizedBox(width: 6),
              Container(
                width: 4, height: 4,
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: Colors.grey.shade300),
              ),
              const SizedBox(width: 6),
              Text(category.nameEn,
                  style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 11, color: Colors.grey.shade400)),
            ]),
          ]),
          const SizedBox(width: 16),
          // Icon circle
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: c.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(category.icon, color: c, size: 26),
          ),
        ]),
      ),
    );
  }
}

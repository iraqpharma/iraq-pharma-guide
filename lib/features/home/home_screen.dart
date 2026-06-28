import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/drug_provider.dart';
import '../../providers/filter_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../data/models/drug_model.dart';
import '../../shared/widgets/app_drawer.dart';
import '../../shared/widgets/ad_carousel.dart';
import '../profile/profile_screen.dart';
import '../../shared/widgets/notification_bell_widget.dart';
import 'widgets/search_bar_widget.dart';
import '../drug_list/drug_list_screen.dart' show categoryClassMap, categoryLabelMap;

const _priceGuideColor = Color(0xFFF59E0B);

// ── Bottom-nav selected index ─────────────────────────────────────────────────
final _bottomIndexProvider = StateProvider<int>((ref) => 2); // 2 = home

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idx = ref.watch(_bottomIndexProvider);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      body: _bodyForIndex(idx, ref),
      bottomNavigationBar: _BottomNavBar(
        selectedIndex: idx,
        onTap: (i) {
          if (i == 2) {
            // Home — clear search & filters
            ref.read(searchQueryProvider.notifier).state = '';
            ref.read(activeFiltersProvider.notifier).state = {};
          }
          ref.read(_bottomIndexProvider.notifier).state = i;
        },
      ),
    );
  }

  Widget _bodyForIndex(int idx, WidgetRef ref) {
    switch (idx) {
      case 0: // المفضلة
        return const _FavoritesBody();
      case 1: // الأدوات
        return _ToolsBody();
      case 3: // بحث
        return _SearchBody();
      case 4: // حسابي
        return const ProfileScreen();
      default: // 2 = الرئيسية
        return _HomeBody();
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// HOME BODY
// ═══════════════════════════════════════════════════════════════════════════════

class _HomeBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // ── Teal Header (pinned — يثبت عند التمرير) ──────────────────────
        SliverPersistentHeader(
          pinned: true,
          delegate: _TealHeaderDelegate(),
        ),

        // ── Ad Carousel (Supabase Realtime) ──────────────────────────────
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(0, 14, 0, 4),
            child: AdCarousel(),
          ),
        ),

        // ── Categories Section ────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
            child: _SectionHeader(
              title: 'استعراض حسب الفصيلة',
              actionLabel: 'عرض الكل',
              onAction: () {},
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _CategoryCard(cat: _categories[i]),
              childCount: _categories.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
          ),
        ),

        // ── Quick Tools Section ───────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
            child: _SectionHeader(title: 'أدوات سريعة'),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _QuickToolCard(tool: _quickTools[i]),
              childCount: _quickTools.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
          ),
        ),

        // ── Commercial Price Guide Banner ─────────────────────────────────
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 28),
          sliver: SliverToBoxAdapter(child: _PriceGuideBanner()),
        ),
      ],
    );
  }
}

// ── SliverPersistentHeader delegate for TealHeader ───────────────────────────
class _TealHeaderDelegate extends SliverPersistentHeaderDelegate {
  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return _TealHeader();
  }

  @override
  double get maxExtent => _kHeaderHeight;

  @override
  double get minExtent => _kHeaderHeight;

  @override
  bool shouldRebuild(_TealHeaderDelegate old) => false;
}

// ارتفاع الهيدر الثابت
double get _kHeaderHeight {
  // top padding (status bar) + padding داخلي + Row height + bottom padding
  // نستخدم قيمة ثابتة معقولة — MediaQuery غير متاح هنا
  return 100;
}

// ── Full-width price guide banner ─────────────────────────────────────────────
class _PriceGuideBanner extends StatelessWidget {
  const _PriceGuideBanner();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/price-guide'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: [Color(0xFF92400E), _priceGuideColor],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _priceGuideColor.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Icon backdrop ────────────────────────────────────────────
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.price_check_rounded,
                  color: Colors.white, size: 30),
            ),
            const SizedBox(width: 16),
            // ── Text ─────────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'دليل الأسعار التجاري',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'تكلفة • بيع • هامش الربح',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
            // ── Arrow ────────────────────────────────────────────────────
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white, size: 15),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TEAL HEADER
// ═══════════════════════════════════════════════════════════════════════════════

class _TealHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 12, 20, 16),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── Start: Hamburger (RTL → RIGHT side) ──────────────────────
          Builder(
            builder: (ctx) => _HeaderIconBtn(
              icon: Icons.menu_rounded,
              onTap: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),

          // ── Center: Title ─────────────────────────────────────────────
          Column(
            children: [
              Text(
                'دليل الصيدلة العراقي',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                'Iraq Pharma Guide',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),

          // ── End: Bell with live unread badge ─────────────────────────
          Builder(
            builder: (ctx) => NotificationBellWidget(
              onTap: () => context.push('/notifications'),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool badge;
  const _HeaderIconBtn({
    required this.icon,
    required this.onTap,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            if (badge)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF5252),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// AD BANNER
// ═══════════════════════════════════════════════════════════════════════════════

class _AdBanner extends StatelessWidget {
  const _AdBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      // IAB standard leaderboard: 728×90 → we use full-width × 90px
      child: SizedBox(
        height: 90,
        child: Stack(
          children: [
            Align(
              alignment: AlignmentDirectional.topEnd,
              child: Text(
                'إعلان',
                style: GoogleFonts.cairo(
                    fontSize: 10, color: AppColors.textSecondary),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.campaign_outlined,
                      color: AppColors.textSecondary.withOpacity(0.35),
                      size: 28),
                  const SizedBox(height: 4),
                  Text(
                    'مساحة إعلانية',
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SECTION HEADER
// ═══════════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    // RTL: index-0 renders on the RIGHT → title first, action last
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CATEGORY DATA & CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _CatItem {
  final String ar, en, routeKey;
  final IconData icon;
  final Color color;
  const _CatItem(this.ar, this.en, this.icon, this.color, this.routeKey);
}

const _categories = [
  // RTL index 0 → RIGHT column
  _CatItem('قلب وأوعية',       'Cardiovascular',
      Icons.favorite_rounded,       AppColors.catCardio,      'cardiovascular'),
  // RTL index 1 → LEFT column
  _CatItem('مضادات حيوية',     'Antibiotics & Antivirals',
      Icons.coronavirus_outlined,   AppColors.catAntibiotics, 'antibiotics'),
  // RTL index 2 → RIGHT column
  _CatItem('سكري',             'Antidiabetics & Glucose',
      Icons.all_inclusive,          AppColors.catDiabetes,    'diabetes'),
  // RTL index 3 → LEFT column
  _CatItem('مسكنات وألم',      'Analgesics & pain',
      Icons.do_not_disturb_alt,     AppColors.catPain,        'analgesics'),
  // RTL index 4 → RIGHT column
  _CatItem('جهاز هضمي',        'Gastroenterology',
      Icons.adjust,                 AppColors.catGastro,      'gastrointestinal'),
  // RTL index 5 → LEFT column
  _CatItem('أعصاب ونفسية',     'Neurology & Psychiatry',
      Icons.lightbulb_outline_rounded, AppColors.catNeuro,   'neurology'),
  // RTL index 6 → RIGHT column
  _CatItem('فيتامينات ومقويات', 'Vitamins & Supplements',
      Icons.egg_alt_outlined,       AppColors.catVitamins,    'vitamins'),
  // RTL index 7 → LEFT column
  _CatItem('كوزمتك وجلدية',    'Cosmetic & Dermatology',
      Icons.face_retouching_natural, AppColors.catCosmetic,   'cosmetic'),
];

class _CategoryCard extends StatelessWidget {
  final _CatItem cat;
  const _CategoryCard({required this.cat});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/category/${cat.routeKey}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: cat.color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(cat.icon, color: cat.color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              cat.ar,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              cat.en,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// QUICK TOOLS DATA & CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _ToolItem {
  final String ar, en;
  final IconData icon;
  final Color color;
  final QuickFilter? filter;
  const _ToolItem(this.ar, this.en, this.icon, this.color, [this.filter]);
}

const _quickTools = [
  // RTL index 0 → RIGHT column
  _ToolItem('آمن للحمل',   'Safe for Pregnancy',
      Icons.bolt,                AppColors.toolPregnancy, QuickFilter.safePregnancy),
  // RTL index 1 → LEFT column
  _ToolItem('قطرات أطفال', 'Pediatric Drops',
      Icons.wb_sunny_outlined,   AppColors.toolPediatric, QuickFilter.pediatricDrops),
  // RTL index 2 → RIGHT column
  _ToolItem('تعديل كلوي',  'Renal Adjustment',
      Icons.calculate_outlined,  AppColors.toolRenal,     QuickFilter.renalCaution),
  // RTL index 3 → LEFT column
  _ToolItem('مبرّد',        'Refrigerated',
      Icons.info_outline_rounded, AppColors.toolCold,     QuickFilter.refrigerated),
];

class _QuickToolCard extends StatelessWidget {
  final _ToolItem tool;
  const _QuickToolCard({required this.tool});

  @override
  Widget build(BuildContext context, ) {
    return GestureDetector(
      onTap: () {
        if (tool.filter == null) return;
        context.push('/quick-filter/${tool.filter!.key}');
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.transparent),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: tool.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(tool.icon, color: tool.color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              tool.ar,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              tool.en,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SEARCH BODY
// ═══════════════════════════════════════════════════════════════════════════════

class _SearchBody extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(searchResultsProvider);
    final isSearching = ref.watch(isSearchActiveProvider);
    final query = ref.watch(searchQueryProvider);

    return Column(
      children: [
        // ── Teal header + search bar ───────────────────────────────────────
        Container(
          color: AppColors.primary,
          padding: EdgeInsets.fromLTRB(
              16, MediaQuery.of(context).padding.top + 16, 16, 16),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('بحث عن دواء',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const PharmaSearchBar(),
            ],
          ),
        ),

        // ── Body ──────────────────────────────────────────────────────────
        Expanded(
          child: !isSearching
              ? _SearchIdleState()
              : results.when(
                  loading: () => const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary)),
                  error: (e, _) => Center(
                      child: Text('خطأ: $e',
                          style: GoogleFonts.cairo(
                              color: AppColors.textSecondary))),
                  data: (drugs) => drugs.isEmpty
                      ? _NoResultsState(query: query)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                          itemCount: drugs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (ctx, i) =>
                              _DrugListCard(drug: drugs[i]),
                        ),
                ),
        ),
      ],
    );
  }
}

// ── Idle state (no query typed yet) ──────────────────────────────────────────
class _SearchIdleState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_rounded,
              size: 72,
              color: AppColors.textSecondary.withOpacity(0.25)),
          const SizedBox(height: 14),
          Text('ابحث عن اسم الدواء',
              style: GoogleFonts.cairo(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text('بالاسم العلمي أو التجاري أو عن طريق مسح الباركود',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                  color: AppColors.textSecondary.withOpacity(0.7),
                  fontSize: 12)),
        ],
      ),
    );
  }
}

// ── No results empty state ────────────────────────────────────────────────────
class _NoResultsState extends StatelessWidget {
  final String query;
  const _NoResultsState({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.medication_outlined,
                  size: 56, color: AppColors.primary),
            ),
            const SizedBox(height: 22),

            // Title
            Text(
              'عذراً، لم نعثر على هذا الدواء',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),

            // Subtitle with query
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(children: [
                TextSpan(
                    text: 'لم يتم العثور على نتائج لـ "',
                    style: GoogleFonts.cairo(
                        fontSize: 13, color: AppColors.textSecondary)),
                TextSpan(
                    text: query,
                    style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold)),
                TextSpan(
                    text: '"',
                    style: GoogleFonts.cairo(
                        fontSize: 13, color: AppColors.textSecondary)),
              ]),
            ),
            const SizedBox(height: 10),
            Text(
              'تحقق من الإملاء أو جرب اسماً مختلفاً',
              style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: AppColors.textSecondary.withOpacity(0.7)),
            ),
            const SizedBox(height: 32),

            // CTA button → Notebook
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/notebook'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.add_circle_outline_rounded,
                    color: Colors.white, size: 20),
                label: Text('إضافته إلى النواقص',
                    style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
              ),
            ),
            const SizedBox(height: 12),

            // Secondary hint
            Text(
              'سيُحفظ في دفتر الصيدلاني للمتابعة لاحقاً',
              style: GoogleFonts.cairo(
                  fontSize: 11,
                  color: AppColors.textSecondary.withOpacity(0.65)),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TOOLS BODY (الأدوات tab)
// ═══════════════════════════════════════════════════════════════════════════════

class _ToolsBody extends StatelessWidget {
  // Full-width banner tools (top 2)
  static const _bannerTools = [
    _NavToolItem('حاسبة الجرعة', 'احسب الجرعة للأطفال والبالغين بدقة',
        Icons.calculate_outlined, Color(0xFF5C6BC0), '/calc'),
    _NavToolItem('حاسبة CrCl', 'تصفية الكرياتينين — معادلة Cockcroft-Gault',
        Icons.monitor_heart_outlined, Color(0xFF0097A7), '/renal-calc'),
  ];
  // Square-grid tools
  static const _gridTools = [
    _NavToolItem('فاحص التفاعلات', 'Drug Interactions',
        Icons.science_outlined, Color(0xFFE65100), '/interactions'),
    _NavToolItem('دفتر الصيدلاني', 'Missing Drugs',
        Icons.edit_note_outlined, Color(0xFF2E7D32), '/notebook'),
    _NavToolItem('حاسبة التسعير', 'Smart Pricing Calculator',
        Icons.price_change_outlined, Color(0xFF6A1B9A), '/pricing-calc'),
    _NavToolItem('الباحث عن البدائل', 'Smart Substitution',
        Icons.swap_horiz_rounded, Color(0xFF0097A7), '/substitution'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Teal header ────────────────────────────────────────────────────
        Container(
          color: AppColors.primary,
          padding: EdgeInsets.fromLTRB(
              16, MediaQuery.of(context).padding.top + 16, 16, 20),
          child: Row(
            children: [
              Text('الأدوات السريرية',
                  style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        // ── Scrollable content ─────────────────────────────────────────────
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Banner cards
              ..._bannerTools.map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _BannerToolCard(tool: t),
                  )),
              const SizedBox(height: 4),
              // 2-column grid for remaining tools
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.05,
                ),
                itemCount: _gridTools.length,
                itemBuilder: (ctx, i) =>
                    _NavToolCard(tool: _gridTools[i]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NavToolItem {
  final String ar, en, route;
  final IconData icon;
  final Color color;
  const _NavToolItem(this.ar, this.en, this.icon, this.color, this.route);
}

// ── Full-width horizontal banner card (for the top 2 tools) ─────────────────

class _BannerToolCard extends StatelessWidget {
  final _NavToolItem tool;
  const _BannerToolCard({required this.tool});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(tool.route),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            // ── Coloured icon backdrop ─────────────────────────────────
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: tool.color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(tool.icon, color: tool.color, size: 30),
            ),
            const SizedBox(width: 16),
            // ── Text block ────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tool.ar,
                      style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(tool.en,
                      style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w400),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            // ── Arrow ─────────────────────────────────────────────────
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: tool.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_forward_ios_rounded,
                  color: tool.color, size: 15),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Square grid card (for the bottom 2 tools) ───────────────────────────────

class _NavToolCard extends StatelessWidget {
  final _NavToolItem tool;
  const _NavToolCard({required this.tool});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(tool.route),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: tool.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(tool.icon, color: tool.color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(tool.ar,
                style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
                textAlign: TextAlign.center),
            Text(tool.en,
                style: GoogleFonts.inter(
                    fontSize: 10, color: AppColors.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// FAVORITES BODY
// ═══════════════════════════════════════════════════════════════════════════════

class _FavoritesBody extends StatefulWidget {
  const _FavoritesBody();
  @override
  State<_FavoritesBody> createState() => _FavoritesBodyState();
}

class _FavoritesBodyState extends State<_FavoritesBody> {
  final Set<int> _selected = {};
  bool _selecting = false;

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _enterSelectMode() => setState(() => _selecting = true);

  void _toggleSelect(int drugId) {
    if (!_selecting) return;
    setState(() {
      _selected.contains(drugId)
          ? _selected.remove(drugId)
          : _selected.add(drugId);
      if (_selected.isEmpty) _selecting = false;
    });
  }

  void _cancelSelect() =>
      setState(() { _selected.clear(); _selecting = false; });

  // ── Dialogs ────────────────────────────────────────────────────────────────

  Future<void> _confirmDeleteSelected(
      BuildContext context, WidgetRef ref, List<Drug> all) async {
    final count = _selected.length;
    final names = all
        .where((d) => _selected.contains(d.id))
        .map((d) => '• ${d.genericName}')
        .join('\n');

    final ok = await _showConfirmDialog(
      context,
      title: 'إزالة $count ${count == 1 ? "دواء" : "أدوية"}',
      body: 'سيتم إزالة:\n$names\nمن المفضلة. هل أنت متأكد؟',
      confirmLabel: 'إزالة',
    );
    if (ok && context.mounted) {
      for (final id in _selected) {
        await ref.read(favoritesProvider.notifier).remove(id);
      }
      _cancelSelect();
    }
  }

  Future<void> _confirmDeleteAll(
      BuildContext context, WidgetRef ref) async {
    final ok = await _showConfirmDialog(
      context,
      title: 'إزالة الكل',
      body: 'سيتم مسح جميع الأدوية من المفضلة. هل أنت متأكد؟',
      confirmLabel: 'إزالة الكل',
    );
    if (ok && context.mounted) {
      final ids = Set<int>.from(ref.read(favoritesProvider));
      for (final id in ids) {
        await ref.read(favoritesProvider.notifier).remove(id);
      }
      _cancelSelect();
    }
  }

  Future<void> _confirmDeleteSingle(
      BuildContext context, WidgetRef ref, Drug drug) async {
    final ok = await _showConfirmDialog(
      context,
      title: 'إزالة من المفضلة',
      body: 'هل تريد إزالة "${drug.genericName}" من المفضلة؟',
      confirmLabel: 'إزالة',
    );
    if (ok && context.mounted) {
      await ref.read(favoritesProvider.notifier).remove(drug.id);
    }
  }

  Future<bool> _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String body,
    required String confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Text(body, style: GoogleFonts.cairo(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء',
                style: GoogleFonts.cairo(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel,
                style: GoogleFonts.cairo(
                    color: const Color(0xFFD32F2F),
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return result == true;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final favAsync = ref.watch(favoriteDrugsProvider);

        return Column(
          children: [
            // ── Header ───────────────────────────────────────────────────
            _buildHeader(context, ref, favAsync.valueOrNull ?? []),

            // ── List ─────────────────────────────────────────────────────
            Expanded(
              child: favAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('خطأ: $e')),
                data: (drugs) => drugs.isEmpty
                    ? _emptyState()
                    : _buildList(context, ref, drugs),
              ),
            ),

            // ── Selection action bar ──────────────────────────────────────
            if (_selecting) _buildActionBar(context, ref,
                favAsync.valueOrNull ?? []),
          ],
        );
      },
    );
  }

  // ── Header (changes in select-mode) ────────────────────────────────────────

  Widget _buildHeader(
      BuildContext context, WidgetRef ref, List<Drug> drugs) {
    final allSelected = drugs.isNotEmpty && _selected.length == drugs.length;

    return Container(
      color: _selecting ? const Color(0xFF37474F) : AppColors.primary,
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 12, 16, 14),
      child: Row(
        children: [
          if (_selecting) ...[
            // ── وضع التحديد ───────────────────────────────────────────
            // Cancel
            _HeaderChip(
              label: 'إلغاء',
              onTap: _cancelSelect,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _selected.isEmpty
                    ? 'اختر الأدوية'
                    : 'تم تحديد ${_selected.length}',
                style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold),
              ),
            ),
            // تحديد الكل / إلغاء الكل
            _HeaderChip(
              label: allSelected ? 'إلغاء الكل' : 'تحديد الكل',
              onTap: () => setState(() {
                if (allSelected) {
                  _selected.clear();
                } else {
                  _selected
                    ..clear()
                    ..addAll(drugs.map((d) => d.id));
                }
              }),
            ),
          ] else ...[
            // ── وضع العرض العادي ──────────────────────────────────────
            const Icon(Icons.bookmark_rounded,
                color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text('المفضلة',
                  style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
            ),
            // زر "تحديد" صغير — يدخل وضع التحديد فقط
            if (drugs.isNotEmpty)
              _HeaderChip(
                label: 'تحديد',
                icon: Icons.checklist_rounded,
                onTap: _enterSelectMode,
              ),
          ],
        ],
      ),
    );
  }

  // ── List — grouped by therapeutic CATEGORY (سكري, قلب...) ───────────────

  /// Returns the Arabic category label for a drug using categoryClassMap.
  String _categoryLabel(Drug drug) {
    for (final entry in categoryClassMap.entries) {
      if (entry.value.contains(drug.drugClass)) {
        return categoryLabelMap[entry.key] ?? entry.key;
      }
    }
    return 'أخرى';
  }

  Widget _buildList(
      BuildContext context, WidgetRef ref, List<Drug> drugs) {
    // Group by therapeutic category, preserving insertion order of categories
    final Map<String, List<Drug>> groups = {};
    for (final drug in drugs) {
      final label = _categoryLabel(drug);
      groups.putIfAbsent(label, () => []).add(drug);
    }

    // Flatten into a list of header + card items
    final List<_FavListItem> items = [];
    for (final entry in groups.entries) {
      items.add(_FavListItem.header(entry.key));
      for (final drug in entry.value) {
        items.add(_FavListItem.drug(drug));
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final item = items[i];
        if (item.isHeader) {
          return Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              item.header!,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.4,
              ),
            ),
          );
        }
        final drug = item.drug!;
        final isSelected = _selected.contains(drug.id);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _FavDrugCard(
            drug: drug,
            isSelecting: _selecting,
            isSelected: isSelected,
            onTap: () {
              if (_selecting) {
                _toggleSelect(drug.id);
              } else {
                context.push('/drug/${drug.id}');
              }
            },
            onRemove: () => _confirmDeleteSingle(context, ref, drug),
          ),
        );
      },
    );
  }

  // ── Bottom action bar (shown when items are selected) ──────────────────────

  Widget _buildActionBar(
      BuildContext context, WidgetRef ref, List<Drug> all) {
    final count = _selected.length;
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 12, offset: Offset(0, -2))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              count == 0
                  ? 'لم يتم تحديد شيء'
                  : 'تم تحديد $count ${count == 1 ? "دواء" : "أدوية"}',
              style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: count == 0
                ? null
                : () => _confirmDeleteSelected(context, ref, all),
            icon: const Icon(Icons.delete_rounded, size: 18),
            label: Text('إزالة المحدد',
                style: GoogleFonts.cairo(fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_outline_rounded,
              size: 72,
              color: AppColors.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('لا توجد أدوية محفوظة',
              style: GoogleFonts.cairo(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text('افتح أي دواء واضغط "المفضلة" لحفظه',
              style: GoogleFonts.cairo(
                  fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Card with selection support ─────────────────────────────────────────────

// ── Simple helper item for the grouped list ─────────────────────────────────

class _FavListItem {
  final String? header;
  final Drug? drug;
  const _FavListItem.header(this.header) : drug = null;
  const _FavListItem.drug(this.drug) : header = null;
  bool get isHeader => header != null;
}

// ── Small chip used in the header bar ───────────────────────────────────────

class _HeaderChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  const _HeaderChip({required this.label, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 14),
              const SizedBox(width: 4),
            ],
            Text(label,
                style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ── Favorites card ───────────────────────────────────────────────────────────

class _FavDrugCard extends StatelessWidget {
  final Drug drug;
  final bool isSelecting;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _FavDrugCard({
    required this.drug,
    required this.isSelecting,
    required this.isSelected,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFFEBEE)
              : AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFD32F2F)
                : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            // ── Checkbox / Icon ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(right: 4, left: 4),
              child: isSelecting
                  ? Checkbox(
                      value: isSelected,
                      onChanged: (_) => onTap(),
                      activeColor: const Color(0xFFD32F2F),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5)),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(10),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.medication_outlined,
                            color: AppColors.primary, size: 24),
                      ),
                    ),
            ),

            // ── Drug info ────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    isSelecting ? 0 : 0, 14, 0, 14),
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
                    if (drug.drugClass.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(drug.drugClass,
                            style: GoogleFonts.inter(
                                fontSize: 10,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Trailing: arrow (normal) or nothing (select mode) ────────
            if (!isSelecting) ...[
              Container(width: 1, height: 60, color: AppColors.divider),
              IconButton(
                onPressed: onRemove,
                tooltip: 'إزالة من المفضلة',
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Color(0xFFD32F2F), size: 22),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
            ] else
              const Padding(
                padding: EdgeInsets.only(left: 14, right: 14),
                child: Icon(Icons.chevron_right,
                    color: AppColors.textSecondary, size: 18),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PLACEHOLDER BODY
// ═══════════════════════════════════════════════════════════════════════════════

class _PlaceholderBody extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback? onTap;
  const _PlaceholderBody({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppColors.primary,
          padding: EdgeInsets.fromLTRB(
              16, MediaQuery.of(context).padding.top + 16, 16, 20),
          child: Row(
            children: [
              Text(title,
                  style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 72, color: AppColors.textSecondary.withOpacity(0.35)),
                const SizedBox(height: 16),
                Text(title,
                    style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Text(subtitle,
                    style: GoogleFonts.cairo(
                        fontSize: 13, color: AppColors.textSecondary),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED DRUG LIST CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _DrugListCard extends StatelessWidget {
  final Drug drug;
  const _DrugListCard({required this.drug});

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
            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.medication_outlined,
                  color: AppColors.primary, size: 26),
            ),
            const SizedBox(width: 14),
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
                  if (drug.drugClass.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(drug.drugClass,
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// NOTIFICATIONS DRAWER  (slides from the LEFT in RTL = endDrawer)
// ═══════════════════════════════════════════════════════════════════════════════

class _NotificationsDrawer extends StatelessWidget {
  const _NotificationsDrawer();

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.82,
      backgroundColor: AppColors.background,
      child: Column(
        children: [
          // ── Header ───────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, top + 20, 20, 20),
            color: AppColors.primary,
            child: Row(
              children: [
                const Icon(Icons.notifications_rounded,
                    color: Colors.white, size: 24),
                const SizedBox(width: 10),
                Text('الإشعارات',
                    style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white70, size: 22),
                ),
              ],
            ),
          ),
          // ── Empty state ───────────────────────────────────────────────────
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_off_outlined,
                      color: AppColors.primary,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('لا توجد إشعارات',
                      style: GoogleFonts.cairo(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  Text('ستظهر هنا الإشعارات والتنبيهات الجديدة',
                      style: GoogleFonts.cairo(
                          fontSize: 13, color: AppColors.textSecondary),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CUSTOM BOTTOM NAVIGATION BAR
// ═══════════════════════════════════════════════════════════════════════════════

class _BottomNavBar extends ConsumerWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  const _BottomNavBar({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomPad),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 16,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // ── المفضلة ───────────────────────────────────────────────
            _NavItem(
              icon: Icons.bookmark_outline_rounded,
              activeIcon: Icons.bookmark_rounded,
              label: 'المفضلة',
              isActive: selectedIndex == 0,
              onTap: () => onTap(0),
            ),
            // ── الأدوات ───────────────────────────────────────────────
            _NavItem(
              icon: Icons.apps_outlined,
              activeIcon: Icons.apps_rounded,
              label: 'الأدوات',
              isActive: selectedIndex == 1,
              onTap: () => onTap(1),
            ),

            // ── CENTER HOME FAB ────────────────────────────────────────
            GestureDetector(
              onTap: () => onTap(2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.home_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 4),
                  Text('الرئيسية',
                      style: GoogleFonts.cairo(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: selectedIndex == 2
                              ? AppColors.primary
                              : AppColors.textSecondary)),
                ],
              ),
            ),

            // ── بحث ──────────────────────────────────────────────────
            _NavItem(
              icon: Icons.search_rounded,
              activeIcon: Icons.search_rounded,
              label: 'بحث',
              isActive: selectedIndex == 3,
              onTap: () => onTap(3),
            ),
            // ── حسابي ─────────────────────────────────────────────────
            _NavItem(
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: 'حسابي',
              isActive: selectedIndex == 4,
              onTap: () => onTap(4),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

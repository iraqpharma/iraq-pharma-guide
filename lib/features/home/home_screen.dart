import 'dart:io' show Platform;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/drug_provider.dart';
import '../../providers/filter_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/recent_searches_provider.dart';
import '../../data/models/drug_model.dart';
import '../../shared/widgets/app_drawer.dart';
import '../../shared/widgets/ad_carousel.dart';
import '../../shared/widgets/compact_app_header.dart';
import '../../shared/widgets/rating_modal.dart';
import '../../services/rating_service.dart';
import '../profile/profile_screen.dart';
import '../../shared/widgets/notification_bell_widget.dart';
import '../../shared/widgets/ios_glass_nav_bar.dart';
import '../../shared/widgets/educational_tool_notice.dart';
import '../../shared/widgets/swipe_to_remove.dart';
import 'widgets/search_bar_widget.dart';
import '../../core/l10n/app_strings.dart';

const _priceGuideColor = Color(0xFFF59E0B);

// ── Bottom-nav selected index ─────────────────────────────────────────────────
final _bottomIndexProvider = StateProvider<int>((ref) => 2); // 2 = home

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _scheduleRatingCheck();
  }

  void _scheduleRatingCheck() {
    Future.delayed(const Duration(seconds: 5), () async {
      if (!mounted) return;
      final config = await RatingService.instance.shouldShow();
      if (!mounted || config == null) return;
      await RatingModal.show(context, config: config);
    });
  }

  @override
  Widget build(BuildContext context) {
    final idx = ref.watch(_bottomIndexProvider);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      // Without this the body stops at the bar's top edge, so the frosted
      // bar had nothing behind it to blur and looked opaque.
      extendBody: Platform.isIOS,
      drawer: const AppDrawer(),
      body: _bodyForIndex(idx),
      bottomNavigationBar: _BottomNavBar(
        selectedIndex: idx,
        onTap: (i) {
          if (i == 2) {
            ref.read(searchQueryProvider.notifier).state = '';
            ref.read(activeFiltersProvider.notifier).state = {};
          }
          ref.read(_bottomIndexProvider.notifier).state = i;
        },
      ),
    );
  }

  Widget _bodyForIndex(int idx) {
    switch (idx) {
      case 0: return const _FavoritesBody();
      case 1: return _ToolsBody();
      case 3: return _SearchBody();
      case 4: return const ProfileScreen();
      default: return _HomeBody();
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// HOME BODY
// ═══════════════════════════════════════════════════════════════════════════════

class _HomeBody extends StatefulWidget {
  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody> {
  final ScrollController _ctrl = ScrollController();

  /// 0 while the page is at rest, 1 once it has scrolled past the header.
  /// Drives the teal→glass transition; the header never changes height, so
  /// nothing below it (the ad carousel) ever moves.
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      final p = (_ctrl.offset / 56).clamp(0.0, 1.0);
      if ((p - _progress).abs() > 0.01 || p == 0 || p == 1) {
        setState(() => _progress = p);
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: _ctrl,
      slivers: [
        // ── Teal Header (pinned — يثبت عند التمرير) ──────────────────────
        SliverPersistentHeader(
          pinned: true,
          delegate: _TealHeaderDelegate(
            topPadding: MediaQuery.of(context).padding.top,
            progress: Platform.isIOS ? _progress : 0,
          ),
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
              title: context.s.browseByCategory,
              actionLabel: context.s.viewAll,
              onAction: () => context.push('/category/all'),
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
            child: Builder(builder: (ctx) => _SectionHeader(title: ctx.s.quickTools)),
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

        // ── OTC Banner ────────────────────────────────────────────────────
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
          sliver: SliverToBoxAdapter(child: _OtcBanner()),
        ),

        // ── Commercial Price Guide Banner ─────────────────────────────────
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 28),
          sliver: SliverToBoxAdapter(child: _PriceGuideBanner()),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: Platform.isIOS ? 88 : 0),
        ),
      ],
    );
  }
}

// ── SliverPersistentHeader delegate for TealHeader ───────────────────────────
class _TealHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double topPadding;
  final double progress;
  _TealHeaderDelegate({required this.topPadding, this.progress = 0});

  // ارتفاع الهيدر يُحسب من safe-area الفعلي للجهاز + مساحة كافية
  // لعنوانين (العربي + الإنجليزي) — كان ثابتاً على 100 بدون مراعاة
  // اختلاف حجم الـ Dynamic Island/notch بين الأجهزة، فكان ينقطع النص
  // على الأجهزة ذات safe-area أكبر (آيفون 14/15/16 Pro مثلاً).
  //
  // الارتفاع ثابت عمداً: الانتقال بصري بحت (لون → زجاج) فلا يتحرك
  // أي شيء تحته.
  double get _height => topPadding + 12 + 46 + 20; // == appHeaderHeight()

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return _TealHeader(progress: progress);
  }

  @override
  double get maxExtent => _height;

  @override
  double get minExtent => _height;

  @override
  bool shouldRebuild(covariant _TealHeaderDelegate old) =>
      old.topPadding != topPadding || old.progress != progress;
}




// ── OTC Banner ────────────────────────────────────────────────────────────────
class _OtcBanner extends StatelessWidget {
  const _OtcBanner();

  static const _teal = Color(0xFF00897B);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/otc'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(children: [
          // ── Icon backdrop (يسار مثل دليل الأسعار) ──────────────────
          const SizedBox(width: 58),
          const SizedBox(width: 16),
          // ── Text block (وسط) ────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.s.otcMedicines,
                    style: GoogleFonts.cairo(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 3),
                Text(context.s.otcSubtitle,
                    style: GoogleFonts.cairo(
                        fontSize: 12.5,
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 8),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: _teal.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(context.s.otcSections,
                        style: GoogleFonts.cairo(
                            fontSize: 11, color: _teal,
                            fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(context.s.otcDrugs,
                        style: GoogleFonts.cairo(
                            fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600)),
                  ),
                ]),
              ],
            ),
          ),
          // ── Arrow (يمين) ────────────────────────────────────────────
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: _teal.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_forward_ios_rounded,
                color: _teal, size: 15),
          ),
        ]),
      ),
    );
  }
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
                    context.s.priceGuide,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.s.priceGuideSubtitle,
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
  /// 0 = solid teal at rest, 1 = frosted glass with dark glyphs once the
  /// page has scrolled under it. Height never changes, only the material.
  final double progress;
  const _TealHeader({this.progress = 0});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final p = progress.clamp(0.0, 1.0);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // White on teal → near-black on glass.
    final ink = Color.lerp(
      Colors.white,
      isDark ? Colors.white : const Color(0xFF10221F),
      p,
    )!;
    final radius = Radius.circular(Platform.isIOS ? 38 : 32);

    return ClipRRect(
      borderRadius: BorderRadius.only(bottomLeft: radius, bottomRight: radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22 * p, sigmaY: 22 * p),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, top + 12, 20, 20),
          decoration: BoxDecoration(
            // Fading the teal out is what lets the blurred page show through.
            color: Color.lerp(
              AppColors.primary,
              (isDark ? Colors.black : cs.surface).withOpacity(0.55),
              p,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ── Start: Hamburger (RTL → RIGHT side) ──────────────────
              // Stays fully opaque and tappable at every scroll position.
              Builder(
                builder: (ctx) => _HeaderIconBtn(
                  icon: Icons.menu_rounded,
                  color: ink,
                  progress: p,
                  onTap: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),

              // ── Center: Title — stays, just changes colour ───────────
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'دليل الصيدلة العراقي',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        color: ink,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      'Iraq Pharma Guide',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: ink.withOpacity(0.75),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // ── End: Bell with live unread badge ────────────────────
              Builder(
                builder: (ctx) => NotificationBellWidget(
                  glyphColor: ink,
                  bubbleOpacity: 0.18 - 0.11 * p,
                  onTap: () => context.push('/notifications'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool badge;
  final Color color;
  final double progress;
  const _HeaderIconBtn({
    required this.icon,
    required this.onTap,
    this.badge = false,
    this.color = Colors.white,
    this.progress = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.18 - 0.11 * progress),
          // iOS conventions favour circular glyph buttons.
          borderRadius: BorderRadius.circular(Platform.isIOS ? 24 : 14),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: color, size: 22),
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
        color: Theme.of(context).colorScheme.surface,
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
                    fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.campaign_outlined,
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.35),
                      size: 28),
                  const SizedBox(height: 4),
                  Text(
                    'مساحة إعلانية',
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
            color: Theme.of(context).colorScheme.onSurface,
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
  // RTL index 8 → RIGHT column
  _CatItem('أدوية مخدرة',       'Controlled & Narcotics',
      Icons.warning_amber_rounded,   AppColors.catNarcotics,  'narcotics'),
  // RTL index 9 → LEFT column
  _CatItem('أخرى',              'Other',
      Icons.category_outlined,       AppColors.catOther,      'other'),
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
          color: Theme.of(context).colorScheme.surface,
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
              context.s.isAr ? cat.ar : cat.en,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
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
  // RTL index 1 → LEFT column (was قطرات أطفال, now مبرّد)
  _ToolItem('مبرّد',        'Refrigerated',
      Icons.info_outline_rounded, AppColors.toolCold,     QuickFilter.refrigerated),
  // RTL index 2 → RIGHT column
  _ToolItem('تعديل كلوي',  'Renal Adjustment',
      Icons.calculate_outlined,  AppColors.toolRenal,     QuickFilter.renalCaution),
  // RTL index 3 → LEFT column (was مبرّد, now قطرات أطفال)
  _ToolItem('قطرات أطفال', 'Pediatric Drops',
      Icons.wb_sunny_outlined,   AppColors.toolPediatric, QuickFilter.pediatricDrops),
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
          color: Theme.of(context).colorScheme.surface,
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
              context.s.isAr ? tool.ar : tool.en,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
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
        // ── Compact header + search bar ────────────────────────────────────
        // Header is identical to every other tab; the field is its own
        // element on the page below it, always visible and never collapsed.
        CompactAppHeader(title: context.s.searchDrug),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: PharmaSearchBar(),
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
                      child: Text('${context.s.error}: $e',
                          style: GoogleFonts.cairo(
                              color: AppColors.textSecondary))),
                  data: (drugs) => drugs.isEmpty
                      ? _NoResultsState(query: query)
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(
                              16, 16, 16, Platform.isIOS ? 108 : 32),
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
class _SearchIdleState extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentSearchesProvider);
    final cs = Theme.of(context).colorScheme;

    if (recent.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_rounded,
                size: 72, color: cs.onSurfaceVariant.withOpacity(0.25)),
            const SizedBox(height: 14),
            Text(context.s.searchHint,
                style: GoogleFonts.cairo(
                    color: cs.onSurfaceVariant,
                    fontSize: 15,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Text(context.s.searchSubHint,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                    color: cs.onSurfaceVariant.withOpacity(0.7), fontSize: 12)),
          ],
        ),
      );
    }

    // Stored on the device only — never attached to the account.
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 20, 16, Platform.isIOS ? 120 : 32),
      children: [
        Row(
          children: [
            Icon(Icons.history_rounded,
                size: 17, color: cs.onSurfaceVariant),
            const SizedBox(width: 7),
            Text(context.s.recentSearches,
                style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant)),
            const Spacer(),
            GestureDetector(
              onTap: () => ref.read(recentSearchesProvider.notifier).clear(),
              child: Text(context.s.clearAll,
                  style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: recent
              .map((q) => _RecentChip(
                    query: q,
                    onTap: () =>
                        ref.read(searchQueryProvider.notifier).state = q,
                    onRemove: () =>
                        ref.read(recentSearchesProvider.notifier).remove(q),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _RecentChip extends StatelessWidget {
  final String query;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  const _RecentChip({
    required this.query,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outline.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(query,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                      fontSize: 12.5, color: cs.onSurface)),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRemove,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close_rounded,
                    size: 14, color: cs.onSurfaceVariant.withOpacity(0.7)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── No results empty state ────────────────────────────────────────────────────
class _NoResultsState extends StatelessWidget {
  final String query;
  const _NoResultsState({required this.query});

  void _openRequestSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DrugRequestSheet(initialName: query),
    );
  }

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
              context.s.noResultsTitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 8),

            // Subtitle with query
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(children: [
                TextSpan(
                    text: context.s.noResultsPrefix,
                    style: GoogleFonts.cairo(
                        fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                TextSpan(
                    text: query,
                    style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold)),
                TextSpan(
                    text: context.s.noResultsSuffix,
                    style: GoogleFonts.cairo(
                        fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ]),
            ),
            const SizedBox(height: 10),
            Text(
              context.s.noResultsHint,
              style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7)),
            ),
            const SizedBox(height: 32),

            // CTA button → Request drug
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openRequestSheet(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 20),
                label: Text(context.s.suggestDrugBtn,
                    style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
              ),
            ),
            const SizedBox(height: 12),

            // Secondary hint
            Text(
              context.s.suggestDrugHint,
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
  List<_NavToolItem> _getBannerTools(BuildContext context) => [
    _NavToolItem(context.s.doseCalc,    context.s.doseCalcSub, Icons.calculate_outlined,     const Color(0xFF5C6BC0), '/calc'),
    _NavToolItem(context.s.crcl,        context.s.crclSub,     Icons.monitor_heart_outlined,  const Color(0xFF0097A7), '/renal-calc'),
  ];
  List<_NavToolItem> _getGridTools(BuildContext context) => [
    _NavToolItem(context.s.interactions,  context.s.interactionsSub, Icons.science_outlined,      const Color(0xFFE65100), '/interactions'),
    _NavToolItem(context.s.notebook,      context.s.notebookSub,     Icons.edit_note_outlined,    const Color(0xFF2E7D32), '/notebook'),
    _NavToolItem(context.s.pricingCalc,   context.s.pricingCalcSub,  Icons.price_change_outlined, const Color(0xFF6A1B9A), '/pricing-calc'),
    _NavToolItem(context.s.substitution,  context.s.substitutionSub, Icons.swap_horiz_rounded,    const Color(0xFF0097A7), '/substitution'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CompactAppHeader(title: context.s.clinicalTools),
        // ── Scrollable content ─────────────────────────────────────────────
        Expanded(
          child: Builder(builder: (ctx) {
            final bannerTools = _getBannerTools(ctx);
            final gridTools   = _getGridTools(ctx);
            return ListView(
              padding: EdgeInsets.fromLTRB(
                  16, 16, 16, Platform.isIOS ? 104 : 16),
              children: [
                // Banner cards
                ...bannerTools.map((t) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _BannerToolCard(tool: t),
                    )),
                const SizedBox(height: 4),
                // 2-column grid for remaining tools
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, crossAxisSpacing: 12,
                    mainAxisSpacing: 12, childAspectRatio: 1.05,
                  ),
                  itemCount: gridTools.length,
                  itemBuilder: (c, i) => _NavToolCard(tool: gridTools[i]),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}

/// Calculators are teaching aids, so the educational notice is shown before
/// they open (once, unless the user ticks "don't show again").
Future<void> _openTool(BuildContext context, _NavToolItem tool) async {
  const gated = {'/calc': 'dose', '/renal-calc': 'crcl'};
  final toolId = gated[tool.route];
  if (toolId != null) {
    final ok = await EducationalToolNotice.ensureAcknowledged(
      context,
      toolId: toolId,
    );
    if (!ok || !context.mounted) return;
  }
  if (context.mounted) context.push(tool.route);
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
      onTap: () => _openTool(context, tool),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
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
                          color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 4),
                  Text(tool.en,
                      style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
      onTap: () => _openTool(context, tool),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
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
                    color: Theme.of(context).colorScheme.onSurface),
                textAlign: TextAlign.center),
            Text(tool.en,
                style: GoogleFonts.inter(
                    fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
      title: context.s.removeNDrugs(count),
      body: context.s.willRemove(names),
      confirmLabel: context.s.remove,
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
      title: context.s.removeAll,
      body: context.s.removeAllConfirm,
      confirmLabel: context.s.removeAll,
    );
    if (ok && context.mounted) {
      final ids = Set<int>.from(ref.read(favoritesProvider));
      for (final id in ids) {
        await ref.read(favoritesProvider.notifier).remove(id);
      }
      _cancelSelect();
    }
  }

  Future<bool> _confirmDeleteSingle(
      BuildContext context, WidgetRef ref, Drug drug) async {
    final ok = await _showConfirmDialog(
      context,
      title: context.s.removeFromFav,
      body: context.s.removeDrug(drug.genericName),
      confirmLabel: context.s.remove,
    );
    if (ok && context.mounted) {
      await ref.read(favoritesProvider.notifier).remove(drug.id);
      return true;
    }
    return false;
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
            child: Text(context.s.cancel,
                style: GoogleFonts.cairo(color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
                error: (e, _) => Center(child: Text('${context.s.error}: $e')),
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
      height: appHeaderHeight(context),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _selecting ? const Color(0xFF37474F) : AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(Platform.isIOS ? 30 : 22),
          bottomRight: Radius.circular(Platform.isIOS ? 30 : 22),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 12, 16, 20),
      child: Row(
        children: [
          if (_selecting) ...[
            // ── وضع التحديد ───────────────────────────────────────────
            // Cancel
            _HeaderChip(
              label: context.s.cancel,
              onTap: _cancelSelect,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _selected.isEmpty
                    ? context.s.chooseDrugs
                    : context.s.selectedCount(_selected.length),
                style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold),
              ),
            ),
            // تحديد الكل / إلغاء الكل
            _HeaderChip(
              label: allSelected ? context.s.deselectAll : context.s.selectAll,
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
            // ── وضع العرض العادي — compact header style ───────────────
            Builder(
              builder: (ctx) => GestureDetector(
                onTap: () => Scaffold.of(ctx).openDrawer(),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(Platform.isIOS ? 20 : 12),
                  ),
                  child: const Icon(Icons.menu_rounded, color: Colors.white, size: 22),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(context.s.favorites,
                  style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (drugs.isNotEmpty)
                  _HeaderChip(
                    label: context.s.select,
                    icon: Icons.checklist_rounded,
                    onTap: _enterSelectMode,
                  ),
                const SizedBox(width: 6),
                NotificationBellWidget(
                  onTap: () => context.push('/notifications'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── List — grouped by therapeutic CATEGORY (سكري, قلب...) ───────────────

  /// Returns the localized category label for a drug using app_category field.
  String _categoryLabel(Drug drug, BuildContext context) {
    return context.s.categoryLabels[drug.appCategory] ?? context.s.other;
  }

  Widget _buildList(
      BuildContext context, WidgetRef ref, List<Drug> drugs) {
    // Group by therapeutic category, preserving insertion order of categories
    final Map<String, List<Drug>> groups = {};
    for (final drug in drugs) {
      final label = _categoryLabel(drug, context);
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
      padding: EdgeInsets.fromLTRB(16, 16, 16, Platform.isIOS ? 150 : 80),
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
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: 0.4,
              ),
            ),
          );
        }
        final drug = item.drug!;
        final isSelected = _selected.contains(drug.id);
        final card = _FavDrugCard(
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
        );

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          // No swiping while multi-selecting — the two gestures would fight.
          child: _selecting
              ? card
              : SwipeToRemove(
                  key: ValueKey('fav_${drug.id}'),
                  label: context.s.remove,
                  // Confirmation is required for the button and for the
                  // full swipe alike — deleting must never be one gesture.
                  onRemove: () => _confirmDeleteSingle(context, ref, drug),
                  child: card,
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
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 12, offset: Offset(0, -2))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              count == 0
                  ? context.s.nothingSelected
                  : context.s.selectedCount(count),
              style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: count == 0
                ? null
                : () => _confirmDeleteSelected(context, ref, all),
            icon: const Icon(Icons.delete_rounded, size: 18),
            label: Text(context.s.removeSelected,
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
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Layered rings behind the mark — softer than a lone grey icon.
                SizedBox(
                  width: 148,
                  height: 148,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withOpacity(0.04),
                        ),
                      ),
                      Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withOpacity(0.07),
                        ),
                      ),
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cs.surface,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.12),
                              blurRadius: 22,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.bookmark_border_rounded,
                            size: 32, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  context.s.noFavorites,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  context.s.noFavoritesSub,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 13.5,
                    height: 1.9,
                    color: cs.onSurfaceVariant.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: 26),
                // A way out instead of a dead end.
                TextButton.icon(
                  onPressed: () => context.push('/category/all'),
                  icon: const Icon(Icons.search_rounded, size: 18),
                  label: Text(
                    context.s.allDrugs,
                    style: GoogleFonts.cairo(
                        fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    backgroundColor: AppColors.primary.withOpacity(0.08),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
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
              : Theme.of(context).colorScheme.surface,
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
                            color: Theme.of(context).colorScheme.onSurface)),
                    if (drug.genericNameAr.isNotEmpty)
                      Text(drug.genericNameAr,
                          style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant)),
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

            // Deleting is a swipe now (see _SwipeToRemove), so the card
            // itself carries no destructive button.
            if (!isSelecting)
              Padding(
                padding: const EdgeInsets.only(left: 14, right: 14),
                child: Icon(Icons.chevron_left_rounded,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withOpacity(0.4),
                    size: 20),
              )
            else
              Padding(
                padding: const EdgeInsets.only(left: 14, right: 14),
                child: Icon(Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onSurfaceVariant, size: 18),
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
          color: Theme.of(context).colorScheme.surface,
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
                          color: Theme.of(context).colorScheme.onSurface)),
                  if (drug.genericNameAr.isNotEmpty)
                    Text(drug.genericNameAr,
                        style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
    final s = context.s;
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.82,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                Text(s.notifications,
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
                  Text(s.noNotifications,
                      style: GoogleFonts.cairo(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 8),
                  Text(s.noNotificationsSub,
                      style: GoogleFonts.cairo(
                          fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
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

    // iOS gets a frosted floating tab bar; Android keeps the original one.
    if (Platform.isIOS) {
      return IosGlassNavBar(
        selectedIndex: selectedIndex,
        onTap: onTap,
        items: [
          IosNavItem(
            icon: Icons.bookmark_outline_rounded,
            activeIcon: Icons.bookmark_rounded,
            label: context.s.navFavorites,
          ),
          IosNavItem(
            icon: Icons.apps_outlined,
            activeIcon: Icons.apps_rounded,
            label: context.s.navTools,
          ),
          IosNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: context.s.navHome,
          ),
          IosNavItem(
            icon: Icons.search_rounded,
            activeIcon: Icons.search_rounded,
            label: context.s.navSearch,
          ),
          IosNavItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: context.s.navAccount,
          ),
        ],
      );
    }

    return Container(
      padding: EdgeInsets.only(bottom: bottomPad),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: const [
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
              label: context.s.navFavorites,
              isActive: selectedIndex == 0,
              onTap: () => onTap(0),
            ),
            // ── الأدوات ───────────────────────────────────────────────
            _NavItem(
              icon: Icons.apps_outlined,
              activeIcon: Icons.apps_rounded,
              label: context.s.navTools,
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
                  Text(context.s.navHome,
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
              label: context.s.navSearch,
              isActive: selectedIndex == 3,
              onTap: () => onTap(3),
            ),
            // ── حسابي ─────────────────────────────────────────────────
            _NavItem(
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: context.s.navAccount,
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
              color: isActive ? AppColors.primary : Theme.of(context).colorScheme.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? AppColors.primary : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DRUG REQUEST BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════════════════════

class _DrugRequestSheet extends StatefulWidget {
  final String initialName;
  const _DrugRequestSheet({required this.initialName});

  @override
  State<_DrugRequestSheet> createState() => _DrugRequestSheetState();
}

class _DrugRequestSheetState extends State<_DrugRequestSheet> {
  final _formKey    = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  String? _category;
  bool    _sending  = false;
  bool    _sent     = false;
  String? _error;

  List<String> _getCategories(BuildContext context) => context.s.drugCategories;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _sending = true; _error = null; });
    try {
      final user = Supabase.instance.client.auth.currentUser;
      await Supabase.instance.client.from('drug_requests').insert({
        'drug_name': _nameCtrl.text.trim(),
        'category' : _category!,
        'user_id'  : user?.id,
      });
      if (mounted) setState(() { _sent = true; _sending = false; });
    } catch (e) {
      if (mounted) setState(() { _error = context.s.errorRetry; _sending = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),

        if (_sent) ...[
          const Icon(Icons.check_circle_rounded,
              color: Color(0xFF00897B), size: 64),
          const SizedBox(height: 16),
          Text(context.s.requestSent,
              style: GoogleFonts.cairo(fontSize: 18,
                  fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 8),
          Text(context.s.requestSentSub,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              child: Text(context.s.ok, style: GoogleFonts.cairo(
                  color: Colors.white, fontWeight: FontWeight.bold,
                  fontSize: 15)),
            ),
          ),
        ] else ...[
          Text(context.s.suggestDrug,
              style: GoogleFonts.cairo(fontSize: 17,
                  fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 4),
          Text(context.s.suggestDrugSub,
              style: GoogleFonts.cairo(fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 20),

          Form(key: _formKey, child: Column(children: [
            TextFormField(
              controller: _nameCtrl,
              style: GoogleFonts.cairo(fontSize: 14),
              decoration: InputDecoration(
                labelText: context.s.drugName,
                labelStyle: GoogleFonts.cairo(color: Theme.of(context).colorScheme.onSurfaceVariant),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceVariant,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? context.s.enterDrugName : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _category,
              isExpanded: true,
              hint: Text(context.s.chooseCat, style: GoogleFonts.cairo(
                  color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14)),
              decoration: InputDecoration(
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceVariant,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5)),
              ),
              items: _getCategories(context).map((c) => DropdownMenuItem(
                value: c,
                child: Text(c, style: GoogleFonts.cairo(fontSize: 14)),
              )).toList(),
              onChanged: (v) => setState(() => _category = v),
              validator: (v) => v == null ? context.s.chooseCatValidate : null,
            ),
          ])),

          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: GoogleFonts.cairo(
                color: Colors.red, fontSize: 12)),
          ],

          const SizedBox(height: 20),
          SizedBox(width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _sending ? null : _submit,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              icon: _sending
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 18),
              label: Text(_sending ? context.s.sending : context.s.sendRequest,
                  style: GoogleFonts.cairo(color: Colors.white,
                      fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ]),
    );
  }
}

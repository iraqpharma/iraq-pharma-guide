import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/advertisement_provider.dart';
import '../../data/models/advertisement.dart';

class AdCarousel extends ConsumerWidget {
  const AdCarousel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(advertisementsProvider);

    return async.when(
      loading: () => const _ShimmerCard(),
      error:   (_, __) => const SizedBox.shrink(),
      data: (ads) {
        if (ads.isEmpty) return const SizedBox.shrink();
        return _CarouselBody(ads: ads);
      },
    );
  }
}

// ── Carousel body ─────────────────────────────────────────────────────────────
class _CarouselBody extends StatefulWidget {
  final List<Advertisement> ads;
  const _CarouselBody({required this.ads});

  @override
  State<_CarouselBody> createState() => _CarouselBodyState();
}

class _CarouselBodyState extends State<_CarouselBody> {
  late final PageController _page;
  Timer? _timer;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _page = PageController(viewportFraction: 0.92);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || widget.ads.isEmpty) return;
      final next = (_current + 1) % widget.ads.length;
      _page.animateToPage(next,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _page.dispose();
    super.dispose();
  }

  Future<void> _open(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardH = (MediaQuery.of(context).size.width * 0.92) / 3;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: cardH,
          child: PageView.builder(
            controller: _page,
            itemCount: widget.ads.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (ctx, i) => _AdCard(
              ad:       widget.ads[i],
              isActive: i == _current,
              onTap:    () => _open(widget.ads[i].actionUrl),
            ),
          ),
        ),

        // Dots
        if (widget.ads.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.ads.length, (i) {
              final active = i == _current;
              return GestureDetector(
                onTap: () => _page.animateToPage(i,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOutCubic),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width:  active ? 24 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.primary
                        : AppColors.primary.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

// ── Single ad card ────────────────────────────────────────────────────────────
class _AdCard extends StatelessWidget {
  final Advertisement ad;
  final bool isActive;
  final VoidCallback onTap;

  const _AdCard({
    required this.ad,
    required this.isActive,
    required this.onTap,
  });

  void _showAdInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 80),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // هيدر
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.campaign_rounded,
                          color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('المساحة الإعلانية',
                          style: GoogleFonts.cairo(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.07),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 15, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),

              // المحتوى
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'اعرض منتجاتك أو خدماتك أمام أكثر من',
                      style: GoogleFonts.cairo(
                          fontSize: 14, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('5,000 صيدلاني',
                              style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                        const SizedBox(width: 8),
                        Text('في العراق',
                            style: GoogleFonts.cairo(
                                fontSize: 14, color: AppColors.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('للتواصل والاستفسار:',
                              style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.phone_rounded,
                                  size: 18, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text('07861071077',
                                  style: GoogleFonts.ibmPlexMono(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          final uri = Uri.parse('tel:07861071077');
                          await launchUrl(uri);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.phone_rounded, size: 18),
                        label: Text('اتصل الآن',
                            style: GoogleFonts.cairo(
                                fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale:    isActive ? 1.0 : 0.95,
      duration: const Duration(milliseconds: 400),
      curve:    Curves.easeInOutCubic,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ── الصورة ────────────────────────────────────────────────
                CachedNetworkImage(
                  imageUrl:       ad.imageUrl,
                  fit:            BoxFit.cover,
                  fadeInDuration: const Duration(milliseconds: 400),
                  placeholder: (_, __) => Container(
                    color: AppColors.primaryLight,
                    child: const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary, strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.primaryLight,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.broken_image_outlined,
                            color: AppColors.primary, size: 28),
                        const SizedBox(height: 6),
                        Text('تعذّر تحميل الصورة',
                            style: GoogleFonts.cairo(
                                fontSize: 11, color: AppColors.primary)),
                      ],
                    ),
                  ),
                ),

                // ── شارة "إعلان" ──────────────────────────────────────────
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.88),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.black.withOpacity(0.18), width: 1),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.10),
                            blurRadius: 4,
                            offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 11,
                            color: Colors.black.withOpacity(0.55)),
                        const SizedBox(width: 4),
                        Text('إعلان',
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.black.withOpacity(0.75),
                            )),
                      ],
                    ),
                  ),
                ),

                // ── حدود خضراء للإعلان النشط ─────────────────────────────
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: isActive ? 1.0 : 0.0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                          width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shimmer ───────────────────────────────────────────────────────────────────
class _ShimmerCard extends StatefulWidget {
  const _ShimmerCard();
  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.35, end: 0.85)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width - 32;
    final h = w / 3;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Container(
          width: w, height: h,
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withOpacity(_anim.value),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

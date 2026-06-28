import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../services/notification_permission_service.dart';

class NotificationPermissionScreen extends StatefulWidget {
  const NotificationPermissionScreen({super.key});

  @override
  State<NotificationPermissionScreen> createState() =>
      _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState
    extends State<NotificationPermissionScreen>
    with TickerProviderStateMixin {

  late final AnimationController _bellCtrl;
  late final AnimationController _entryCtrl;
  late final Animation<double>   _bellRock;
  late final Animation<double>   _fadeSide;
  late final Animation<Offset>   _slideUp;

  bool _loading = false;

  @override
  void initState() {
    super.initState();

    // Bell rocking animation (loops)
    _bellCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _bellRock = Tween<double>(begin: -0.12, end: 0.12).animate(
      CurvedAnimation(parent: _bellCtrl, curve: Curves.easeInOut),
    );

    // Entry fade + slide
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeSide = CurvedAnimation(parent: _entryCtrl, curve: const Interval(0.3, 1.0));
    _slideUp  = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut),
    );
    _entryCtrl.forward();

    // Skip if permission already decided
    _checkAndMaybeSkip();
  }

  Future<void> _checkAndMaybeSkip() async {
    final show = await NotificationPermissionService.instance.shouldShowScreen();
    if (!mounted) return;
    if (!show) context.go('/home');
  }

  @override
  void dispose() {
    _bellCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _onEnable() async {
    setState(() => _loading = true);
    await NotificationPermissionService.instance.requestPermission();
    if (mounted) context.go('/home');
  }

  Future<void> _onSkip() async {
    await NotificationPermissionService.instance.deny();
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFDDF3F0), Color(0xFFEEF8F7), Color(0xFFF4FAFA)],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── Animated Bell ─────────────────────────────────────────────
              AnimatedBuilder(
                animation: _bellCtrl,
                builder: (_, child) => Transform.rotate(
                  angle: _bellRock.value,
                  child: child,
                ),
                child: _BellIcon(size: size.width * 0.44),
              ),

              const SizedBox(height: 48),

              // ── Title & subtitle ──────────────────────────────────────────
              SlideTransition(
                position: _slideUp,
                child: FadeTransition(
                  opacity: _fadeSide,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 36),
                    child: Column(
                      children: [
                        Text(
                          'تفعيل التنبيهات',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A3A38),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'كن أول من يعلم بآخر تحديثات الأدوية،\nتغييرات الأسعار، والتنبيهات الطبية الهامة.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 15,
                            color: const Color(0xFF4A7070),
                            height: 1.75,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 3),

              // ── Buttons ───────────────────────────────────────────────────
              FadeTransition(
                opacity: _fadeSide,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Enable button
                      SizedBox(
                        height: 58,
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _onEnable,
                          icon: _loading
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5))
                              : const Icon(Icons.check_rounded, size: 20),
                          label: Text(
                            _loading ? 'جارٍ التفعيل…' : 'تفعيل الآن',
                            style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 17, fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18)),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Skip
                      GestureDetector(
                        onTap: _loading ? null : _onSkip,
                        child: Center(
                          child: Text(
                            'ليس الآن',
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF4A7070),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Brand footer ──────────────────────────────────────────────
              Text(
                'PHARMAGUIDE IRAQ',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 11,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4A7070).withOpacity(0.45),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bell icon widget ──────────────────────────────────────────────────────────
class _BellIcon extends StatelessWidget {
  final double size;
  const _BellIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size, height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          Container(
            width: size, height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.08),
            ),
          ),
          // Inner white card circle
          Container(
            width: size * 0.76, height: size * 0.76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.12),
                  blurRadius: 24, offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.notifications_active_outlined,
              size: size * 0.38,
              color: AppColors.primary,
            ),
          ),
          // Small pharmacy badge (top-right)
          Positioned(
            top: size * 0.10,
            right: size * 0.10,
            child: Container(
              width: size * 0.17, height: size * 0.17,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                Icons.add_rounded,
                size: size * 0.10,
                color: Colors.white,
              ),
            ),
          ),
          // Sound waves (decorative arcs)
          CustomPaint(
            size: Size(size, size),
            painter: _WavesPainter(color: AppColors.primary.withOpacity(0.18)),
          ),
        ],
      ),
    );
  }
}

class _WavesPainter extends CustomPainter {
  final Color color;
  const _WavesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Left waves
    for (int i = 1; i <= 2; i++) {
      final r = size.width * (0.45 + i * 0.07);
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        math.pi * 0.75, math.pi * 0.5,
        false, paint,
      );
    }
    // Right waves
    for (int i = 1; i <= 2; i++) {
      final r = size.width * (0.45 + i * 0.07);
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        math.pi * 1.75, math.pi * 0.5,
        false, paint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

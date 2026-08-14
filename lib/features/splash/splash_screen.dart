import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/app_strings.dart';
import '../../services/auth_service.dart';
import '../../services/profile_completion_service.dart';
import '../../services/session_service.dart';
import '../../services/version_checker_service.dart';
import '../../shared/widgets/force_update_dialog.dart';
import '../../shared/widgets/soft_update_dialog.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  static const _deepBlue = Color(0xFF0B3A70);
  static const _teal     = Color(0xFF2BB5B1);
  // Gold/amber pulse — replaces teal glow
  static const _glowColor = Color(0xFFE8A020);

  // 1. Logo + text entrance
  late final AnimationController _entryCtrl;
  late final Animation<double>   _logoFade;
  late final Animation<double>   _logoScale;
  late final Animation<double>   _textFade;
  late final Animation<Offset>   _textSlide;

  // 2. Pulsing glow (after 2 s)
  late final AnimationController _glowCtrl;
  late final Animation<double>   _glowBlur;
  late final Animation<double>   _glowOpacity;

  // 3. Sweep arc ring
  late final AnimationController _sweepCtrl;

  // 4. Full-screen fade-out before navigate
  late final AnimationController _exitCtrl;
  late final Animation<double>   _exitFade;

  bool _showGlow = false;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();

    // Status bar: light icons on white background
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    // ── Entrance ─────────────────────────────────────────────────────────────
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));

    _logoFade = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _entryCtrl,
            curve: const Interval(0.0, 0.65, curve: Curves.easeOut)));

    _logoScale = Tween(begin: 0.82, end: 1.0).animate(
        CurvedAnimation(parent: _entryCtrl,
            curve: const Interval(0.0, 0.70, curve: Curves.easeOutBack)));

    _textFade = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _entryCtrl,
            curve: const Interval(0.50, 1.0, curve: Curves.easeOut)));

    _textSlide = Tween<Offset>(
            begin: const Offset(0, 0.30), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl,
            curve: const Interval(0.50, 1.0, curve: Curves.easeOutCubic)));

    _entryCtrl.forward();

    // ── Glow pulse ────────────────────────────────────────────────────────────
    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800));

    _glowBlur    = Tween(begin: 16.0, end: 44.0).animate(
        CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
    _glowOpacity = Tween(begin: 0.20, end: 0.55).animate(
        CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    // ── Sweep ring ────────────────────────────────────────────────────────────
    _sweepCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200));

    // ── Exit fade ─────────────────────────────────────────────────────────────
    _exitCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _exitFade = Tween(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn));

    // Activate glow after 2 s
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted || _navigating) return;
      setState(() => _showGlow = true);
      _glowCtrl.repeat(reverse: true);
      _sweepCtrl.repeat();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _glowCtrl.dispose();
    _sweepCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final versionResult = await VersionCheckerService.instance.check();
    if (!mounted) return;

    if (versionResult.forceUpdate) {
      await ForceUpdateDialog.show(context,
          currentVersion: versionResult.currentVersion,
          minVersion:     versionResult.minVersion);
      return _init();
    }

    // Stop glow animations before exit
    setState(() => _navigating = true);
    _glowCtrl.stop();
    _sweepCtrl.stop();

    // Fade out the splash
    await _exitCtrl.forward();
    if (!mounted) return;

    // Navigate
    if (AuthService.instance.isLoggedIn) {
      final valid = await SessionService.instance.isSessionStillValid();
      if (!mounted) return;
      if (valid) {
        // The notification-permission screen is a one-time, post-login step.
        // Routing here on every cold start made it flash on screen each time
        // the app opened. Returning users go straight into the app.
        final showProfileCompletion =
            await ProfileCompletionService.instance.shouldShowScreen();
        if (!mounted) return;
        context.go(showProfileCompletion ? '/complete-profile' : '/home');
      } else {
        await AuthService.instance.signOut();
        await SessionService.instance.clear();
        if (mounted) context.go('/login');
      }
    } else {
      context.go('/login');
    }

    if (versionResult.showUpdateDialog && mounted) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        await SoftUpdateDialog.show(context,
            updateMessage: versionResult.updateMessage,
            latestVersion: versionResult.latestVersion);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _exitFade,
      builder: (_, child) => Opacity(opacity: _exitFade.value, child: child!),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFFFFF), Color(0xFFF0F6FF)],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [

                // ── Subtle decorative circles ───────────────────────────────
                Positioned(
                  top: -60, right: -60,
                  child: _DecorCircle(size: 220,
                      color: _deepBlue.withOpacity(0.04)),
                ),
                Positioned(
                  bottom: 80, left: -80,
                  child: _DecorCircle(size: 280,
                      color: _teal.withOpacity(0.045)),
                ),

                // ── Main content ────────────────────────────────────────────
                Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [

                            // ── Logo ─────────────────────────────────────────
                            AnimatedBuilder(
                              animation: _entryCtrl,
                              builder: (_, child) => Transform.scale(
                                scale: _logoScale.value,
                                child: Opacity(
                                  opacity: _logoFade.value.clamp(0.0, 1.0),
                                  child: child,
                                ),
                              ),
                              child: _LogoArea(
                                showGlow:    _showGlow,
                                glowCtrl:    _glowCtrl,
                                glowBlur:    _glowBlur,
                                glowOpacity: _glowOpacity,
                                sweepCtrl:   _sweepCtrl,
                                glowColor:   _glowColor,
                                teal:        _teal,
                              ),
                            ),

                            const SizedBox(height: 40),

                            // ── Text ─────────────────────────────────────────
                            AnimatedBuilder(
                              animation: _entryCtrl,
                              builder: (_, child) => SlideTransition(
                                position: _textSlide,
                                child: FadeTransition(
                                    opacity: _textFade, child: child!),
                              ),
                              child: Column(children: [
                                Text(
                                  'IRAQ PHARMA GUIDE',
                                  style: TextStyle(
                                    color: _deepBlue,
                                    fontSize: 21,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 3.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  context.s.splashTitle,
                                  style: TextStyle(
                                    color: _teal,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                // Decorative divider
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(width: 30, height: 1.5,
                                        color: _teal.withOpacity(0.25)),
                                    Container(
                                      width: 6, height: 6,
                                      margin: const EdgeInsets.symmetric(horizontal: 8),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _teal.withOpacity(0.5),
                                      ),
                                    ),
                                    Container(width: 30, height: 1.5,
                                        color: _teal.withOpacity(0.25)),
                                  ],
                                ),
                              ]),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Footer ───────────────────────────────────────────────
                    AnimatedBuilder(
                      animation: _textFade,
                      builder: (_, child) =>
                          Opacity(opacity: _textFade.value, child: child!),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Text(
                          '© 2026 Iraq Pharma Guide',
                          style: TextStyle(
                            color: _deepBlue.withOpacity(0.30),
                            fontSize: 11.5,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Logo + animations wrapper ─────────────────────────────────────────────────
class _LogoArea extends StatelessWidget {
  final bool showGlow;
  final AnimationController glowCtrl;
  final Animation<double> glowBlur;
  final Animation<double> glowOpacity;
  final AnimationController sweepCtrl;
  final Color glowColor;
  final Color teal;

  const _LogoArea({
    required this.showGlow,
    required this.glowCtrl,
    required this.glowBlur,
    required this.glowOpacity,
    required this.sweepCtrl,
    required this.glowColor,
    required this.teal,
  });

  @override
  Widget build(BuildContext context) {
    const s = 170.0; // logo size

    return SizedBox(
      width: s + 70,
      height: s + 70,
      child: Stack(alignment: Alignment.center, children: [

        // Pulsing golden glow behind logo
        if (showGlow)
          AnimatedBuilder(
            animation: glowCtrl,
            builder: (_, __) => Container(
              width: s + 10,
              height: s + 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withOpacity(glowOpacity.value),
                    blurRadius: glowBlur.value * 1.8,
                    spreadRadius: glowBlur.value * 0.15,
                  ),
                  BoxShadow(
                    color: glowColor.withOpacity(glowOpacity.value * 0.3),
                    blurRadius: glowBlur.value * 3.5,
                    spreadRadius: 0,
                  ),
                ],
              ),
            ),
          ),

        // Sweep arc
        if (showGlow)
          AnimatedBuilder(
            animation: sweepCtrl,
            builder: (_, __) => CustomPaint(
              size: const Size(s + 50, s + 50),
              painter: _SweepPainter(
                  progress: sweepCtrl.value, color: glowColor),
            ),
          ),

        // Logo image (no rounded clip — show full logo shape)
        Image.asset(
          'assets/images/logo.png',
          width:  s,
          height: s,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _FallbackLogo(size: s, teal: teal),
        ),
      ]),
    );
  }
}

// ─── Sweep arc painter ─────────────────────────────────────────────────────────
class _SweepPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _SweepPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 3;

    // Ghost ring
    canvas.drawCircle(c, r, Paint()
      ..color = color.withOpacity(0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8);

    // Moving arc (120°)
    final start = progress * 2 * math.pi - math.pi / 2;
    const span  = math.pi * 0.67;

    final arcPaint = Paint()
      ..shader = SweepGradient(
        startAngle: start,
        endAngle:   start + span,
        colors: [
          color.withOpacity(0.0),
          color.withOpacity(0.55),
          color,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: c, radius: r))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
        Rect.fromCircle(center: c, radius: r), start, span, false, arcPaint);

    // Bright tip dot
    final tx = c.dx + r * math.cos(start + span);
    final ty = c.dy + r * math.sin(start + span);
    canvas.drawCircle(Offset(tx, ty), 3.5, Paint()
      ..color = color.withOpacity(0.85)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    canvas.drawCircle(Offset(tx, ty), 2.0, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_SweepPainter o) => o.progress != progress;
}

// ─── Decorative background circle ─────────────────────────────────────────────
class _DecorCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _DecorCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

// ─── Fallback if logo asset missing ───────────────────────────────────────────
class _FallbackLogo extends StatelessWidget {
  final double size;
  final Color teal;
  const _FallbackLogo({required this.size, required this.teal});

  @override
  Widget build(BuildContext context) => Icon(
        Icons.local_pharmacy_outlined,
        size: size * 0.65,
        color: teal,
      );
}

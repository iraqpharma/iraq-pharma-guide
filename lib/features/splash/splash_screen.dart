import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/session_service.dart';
import '../../services/version_checker_service.dart';
import '../../shared/widgets/force_update_dialog.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _scale = Tween(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade  = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0.3, 1.0)));
    _ctrl.forward();

    // Run all init checks after the first frame so context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _init() async {
    // Wait for the splash animation to look good
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // ── 1. Force-update check ────────────────────────────────────────────────
    final versionResult = await VersionCheckerService.instance.check();
    if (!mounted) return;

    if (versionResult.forceUpdate) {
      // Show non-dismissible dialog — execution halts here until user updates
      await ForceUpdateDialog.show(
        context,
        currentVersion: versionResult.currentVersion,
        minVersion:     versionResult.minVersion,
      );
      // If somehow dismissed (shouldn't happen), just show it again
      return _init();
    }

    // ── 2. Auth + session check ──────────────────────────────────────────────
    if (AuthService.instance.isLoggedIn) {
      final valid = await SessionService.instance.isSessionStillValid();
      if (!mounted) return;
      if (valid) {
        context.go('/notification-permission');
      } else {
        await AuthService.instance.signOut();
        await SessionService.instance.clear();
        if (mounted) context.go('/login');
      }
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.darkNavy, AppColors.primaryBlue, AppColors.accentTeal],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scale,
                child: Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.medication, size: 56, color: Colors.white),
                ),
              ),
              const SizedBox(height: 24),
              FadeTransition(
                opacity: _fade,
                child: Column(children: [
                  const Text(
                    'Iraq Pharma Guide',
                    style: TextStyle(
                        color: Colors.white, fontSize: 26,
                        fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'دليل الدواء العراقي',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 28, height: 28,
                    child: CircularProgressIndicator(
                      color: Colors.white.withOpacity(0.6),
                      strokeWidth: 2.5,
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

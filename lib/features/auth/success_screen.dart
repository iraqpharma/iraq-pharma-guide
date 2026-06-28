import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';

class RegistrationSuccessScreen extends StatefulWidget {
  const RegistrationSuccessScreen({super.key});

  @override
  State<RegistrationSuccessScreen> createState() => _RegistrationSuccessScreenState();
}

class _RegistrationSuccessScreenState extends State<RegistrationSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _scale;
  late final Animation<double>   _fade;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade  = CurvedAnimation(parent: _ctrl, curve: const Interval(0.3, 1.0));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFFE0F7F5), Color(0xFFF0FAFA), Color(0xFFEAF5F5)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Animated checkmark card
              ScaleTransition(
                scale: _scale,
                child: Container(
                  width: 160, height: 160,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(36),
                    boxShadow: [
                      BoxShadow(color: AppColors.primary.withOpacity(0.15),
                          blurRadius: 30, offset: const Offset(0, 12)),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Big checkmark circle
                      Container(
                        width: 100, height: 100,
                        decoration: const BoxDecoration(
                          color: AppColors.primary, shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 56),
                      ),
                      // Small pharmacy badge top-right
                      Positioned(
                        top: 14, right: 14,
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.local_pharmacy_outlined,
                              color: AppColors.primary, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // Text
              FadeTransition(
                opacity: _fade,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      Text('تم إنشاء الحساب بنجاح!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 26, fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A3A38))),
                      const SizedBox(height: 14),
                      Text(
                        'أهلاً بك في مجتمع الصيادلة في العراق.\nيمكنك الآن البدء باستكشاف دليل الأدوية والأدوات السريرية.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 15, color: const Color(0xFF4A7070), height: 1.7),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // Button
              FadeTransition(
                opacity: _fade,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: SizedBox(
                    width: double.infinity, height: 58,
                    child: ElevatedButton.icon(
                      onPressed: () {
              // If user is logged in (auto-confirmed) → notification permission → home
              // Otherwise → login screen
              if (AuthService.instance.isLoggedIn) {
                context.go('/notification-permission');
              } else {
                context.go('/login');
              }
            },
                      icon: const Icon(Icons.arrow_back_rounded, size: 20),
                      label: Text('ابدأ الآن',
                          style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 17, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Footer brand
              FadeTransition(
                opacity: _fade,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 6),
                    Text('Iraq Pharma Guide',
                        style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 12, color: const Color(0xFF4A7070).withOpacity(0.6))),
                  ],
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

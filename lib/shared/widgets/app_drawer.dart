import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          _DrawerHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // ── الأدوات السريرية ──────────────────────────────────
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 10, 20, 6),
                  child: _SectionLabel('الأدوات السريرية'),
                ),
                _DrawerTile(
                  icon: Icons.calculate_outlined,
                  color: Color(0xFF5C6BC0),
                  title: 'حاسبة الجرعة',
                  subtitle: 'للأطفال والبالغين',
                  onTap: () { Navigator.pop(context); context.push('/calc'); },
                ),
                _DrawerTile(
                  icon: Icons.monitor_heart_outlined,
                  color: Color(0xFF0097A7),
                  title: 'حاسبة CrCl',
                  subtitle: 'Cockcroft-Gault',
                  onTap: () { Navigator.pop(context); context.push('/renal-calc'); },
                ),
                _DrawerTile(
                  icon: Icons.science_outlined,
                  color: Color(0xFFE65100),
                  title: 'فاحص التفاعلات',
                  subtitle: 'تفاعلات الأدوية المتعددة',
                  onTap: () { Navigator.pop(context); context.push('/interactions'); },
                ),
                _DrawerTile(
                  icon: Icons.edit_note_outlined,
                  color: Color(0xFF2E7D32),
                  title: 'دفتر الصيدلاني',
                  subtitle: 'الأدوية المفقودة والملاحظات',
                  onTap: () { Navigator.pop(context); context.push('/notebook'); },
                ),
                _DrawerTile(
                  icon: Icons.price_change_outlined,
                  color: Color(0xFF6A1B9A),
                  title: 'حاسبة التسعير الذكي',
                  subtitle: 'تكلفة الوحدة وسعر البيع',
                  onTap: () { Navigator.pop(context); context.push('/pricing-calc'); },
                ),
                _DrawerTile(
                  icon: Icons.swap_horiz_rounded,
                  color: Color(0xFF0097A7),
                  title: 'الباحث عن البدائل',
                  subtitle: 'البدائل المباشرة والعلاجية',
                  onTap: () { Navigator.pop(context); context.push('/substitution'); },
                ),

                // ── دليل الأسعار ──────────────────────────────────────
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 6),
                  child: _SectionLabel('الأسعار'),
                ),
                _DrawerTile(
                  icon: Icons.price_check_outlined,
                  color: Color(0xFFF59E0B),
                  title: 'دليل الأسعار التجاري',
                  subtitle: 'تكلفة وبيع وهامش الربح',
                  onTap: () { Navigator.pop(context); context.push('/price-guide'); },
                ),
              ],
            ),
          ),
          const _DrawerFooter(),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.ibmPlexSansArabic(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 20,
          bottom: 20,
          left: 20,
          right: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.darkNavy, AppColors.primary],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.local_pharmacy_outlined,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Iraq Pharma Guide',
                  style: GoogleFonts.ibmPlexSansArabic(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 3),
              Text('دليل الدواء العراقي',
                  style: GoogleFonts.ibmPlexSansArabic(
                      color: Colors.white70, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title,
          style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 15, fontWeight: FontWeight.w600,
              color: AppColors.textPrimary)),
      subtitle: Text(subtitle,
          style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 12, color: AppColors.textSecondary)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}

class _DrawerFooter extends StatelessWidget {
  const _DrawerFooter();

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottom + 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Column(
        children: [
          // Legal links
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            children: [
              _legalLink(context, 'سياسة الخصوصية', '/legal/privacy'),
              Text('·', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
              _legalLink(context, 'شروط الاستخدام', '/legal/terms'),
              Text('·', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
              _legalLink(context, 'إخلاء المسؤولية', '/legal/disclaimer'),
            ],
          ),
          const SizedBox(height: 8),
          // App name + version
          Text(
            'Iraq Pharma Guide ® 2026',
            style: GoogleFonts.ibmPlexSansArabic(
                color: AppColors.textSecondary, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _legalLink(BuildContext context, String label, String route) {
    return GestureDetector(
      onTap: () { Navigator.pop(context); context.push(route); },
      child: Text(
        label,
        style: GoogleFonts.ibmPlexSansArabic(
          fontSize: 11,
          color: AppColors.primary,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.primary,
        ),
      ),
    );
  }
}

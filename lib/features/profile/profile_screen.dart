import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/session_service.dart';
// ignore: unused_import
import 'interactive_reference_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _profile;
  bool _loading  = true;
  bool _darkMode = false;

  late final AnimationController _avatarCtrl;
  late final Animation<double>   _avatarScale;

  @override
  void initState() {
    super.initState();
    _avatarCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _avatarScale = CurvedAnimation(parent: _avatarCtrl, curve: Curves.elasticOut);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final data = await AuthService.instance.getProfile();
    if (!mounted) return;
    setState(() { _profile = data; _loading = false; });
    _avatarCtrl.forward();
  }

  @override
  void dispose() { _avatarCtrl.dispose(); super.dispose(); }

  String _formatStat(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }

  String get _fullName => _profile?['full_name'] as String? ?? '—';
  String get _username => _profile?['username']  as String? ?? '—';
  String get _role     => _profile?['role']       as String? ?? '—';
  int get _drugSearches   => (_profile?['drug_search_count']  as int?) ?? 0;
  int get _toolUsage      => (_profile?['tool_usage_count']   as int?) ?? 0;

  String _initials(String name) {
    final parts = name.trim().split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '؟';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  // Adds a thin space between each character of the name for display
  String _spacedName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.join('  ');
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.logout_rounded, color: Colors.red, size: 22),
          const SizedBox(width: 10),
          Text('تسجيل الخروج',
              style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold, fontSize: 17)),
        ]),
        content: Text('هل أنت متأكد من تسجيل الخروج؟',
            style: GoogleFonts.ibmPlexSansArabic(fontSize: 14, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء',
                style: GoogleFonts.ibmPlexSansArabic(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text('خروج', style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await AuthService.instance.signOut();
      await SessionService.instance.clear();
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F4F8),
        body: _loading ? _buildLoader() : _buildBody(),
      ),
    );
  }

  Widget _buildLoader() => const Center(
    child: CircularProgressIndicator(color: AppColors.primary),
  );

  Widget _buildBody() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildAppHeader(),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildUserCard(),
                const SizedBox(height: 16),
                _buildStatsRow(),
                const SizedBox(height: 16),
                _buildCard(children: [
                  _buildNavTile(
                    icon: Icons.manage_accounts_outlined,
                    color: AppColors.primary,
                    title: 'تعديل البيانات الشخصية',
                    onTap: () async {
                      await context.push('/edit-profile');
                      _loadProfile(); // refresh after edit
                    },
                  ),
                  _divider(),
                  _buildNavTile(
                    icon: Icons.menu_book_outlined,
                    color: const Color(0xFF5C6BC0),
                    title: 'المرجع التفاعلي',
                    onTap: () => context.push('/interactive-reference'),
                  ),
                ]),
                const SizedBox(height: 12),
                _buildCard(children: [
                  _buildNavTile(
                    icon: Icons.settings_outlined,
                    color: const Color(0xFF546E7A),
                    title: 'الإعدادات',
                    onTap: () => context.push('/settings'),
                  ),
                  _divider(),
                  _buildNavTile(
                    icon: Icons.language_rounded,
                    color: const Color(0xFF00897B),
                    title: 'لغة التطبيق',
                    trailing: _LangBadge(),
                    onTap: () {},
                  ),
                  _divider(),
                  _buildSwitchTile(
                    icon: Icons.dark_mode_outlined,
                    color: const Color(0xFF5E35B1),
                    title: 'المظهر الداكي',
                    value: _darkMode,
                    onChanged: (v) => setState(() => _darkMode = v),
                  ),
                ]),
                const SizedBox(height: 12),
                // Support & Suggestions card
                _buildCard(children: [
                  _buildNavTile(
                    icon: Icons.help_outline_rounded,
                    color: const Color(0xFF00897B),
                    title: 'قسم الدعم',
                    onTap: () => context.push('/support'),
                  ),
                  _divider(),
                  _buildNavTile(
                    icon: Icons.lightbulb_outline_rounded,
                    color: const Color(0xFFF57C00),
                    title: 'إرسال اقتراح',
                    onTap: () => context.push('/suggestion'),
                  ),
                ]),
                const SizedBox(height: 12),
                // Legal links
                _buildLegalCard(),
                const SizedBox(height: 12),
                _buildLogoutCard(),
                const SizedBox(height: 28),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── App Header (gradient with logo) ──────────────────────────────────────
  SliverAppBar _buildAppHeader() {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.darkNavy,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.darkNavy, AppColors.primary],
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: kToolbarHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.local_pharmacy_outlined, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Iraq Pharma Guide',
                        style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('دليل الصيدلة العراقي',
                        style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 11, color: Colors.white.withOpacity(0.75))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── User card ─────────────────────────────────────────────────────────────
  Widget _buildUserCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          // Gradient strip
          Container(
            height: 72,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              gradient: LinearGradient(
                colors: [AppColors.darkNavy, AppColors.primary.withOpacity(0.85)],
                begin: Alignment.centerRight, end: Alignment.centerLeft,
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -44),
            child: Column(
              children: [
                ScaleTransition(
                  scale: _avatarScale,
                  child: _Avatar(initials: _initials(_fullName)),
                ),
                const SizedBox(height: 10),
                // Name — large, spaced
                Text(
                  _spacedName(_fullName),
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.5,
                    wordSpacing: 6,
                  ),
                ),
                const SizedBox(height: 6),
                // Username chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.alternate_email_rounded, size: 13, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(_username,
                          style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Role badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_role,
                      style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats row (real data) ─────────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _StatCard(
          icon: Icons.search_rounded,
          color: AppColors.primary,
          value: _formatStat(_drugSearches),
          label: 'بحث دواء',
        )),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(
          icon: Icons.build_outlined,
          color: const Color(0xFF5C6BC0),
          value: _formatStat(_toolUsage),
          label: 'استخدام الأدوات',
        )),
      ],
    );
  }

  Widget _buildCard({required List<Widget> children}) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
      ],
    ),
    child: Column(children: children),
  );

  Widget _divider() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Divider(height: 1, color: Colors.grey.shade100),
  );

  Widget _buildNavTile({
    required IconData icon, required Color color,
    required String title, Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            const Icon(Icons.chevron_left_rounded, size: 20, color: Color(0xFFCCCCCC)),
            const Spacer(),
            if (trailing != null) ...[trailing, const SizedBox(width: 10)],
            Text(title,
                style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
            const SizedBox(width: 14),
            _IconBadge(icon: icon, color: color),
          ]),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon, required Color color,
    required String title, required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        Switch(value: value, onChanged: onChanged, activeColor: AppColors.primary),
        const Spacer(),
        Text(title,
            style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        const SizedBox(width: 14),
        _IconBadge(icon: icon, color: color),
      ]),
    );
  }

  Widget _buildLegalCard() => _buildCard(children: [
    _buildNavTile(
      icon: Icons.privacy_tip_outlined,
      color: AppColors.primary,
      title: 'سياسة الخصوصية',
      onTap: () => context.push('/legal/privacy'),
    ),
    _divider(),
    _buildNavTile(
      icon: Icons.gavel_rounded,
      color: const Color(0xFF5C6BC0),
      title: 'شروط الاستخدام',
      onTap: () => context.push('/legal/terms'),
    ),
    _divider(),
    _buildNavTile(
      icon: Icons.warning_amber_rounded,
      color: const Color(0xFFF57C00),
      title: 'إخلاء المسؤولية',
      onTap: () => context.push('/legal/disclaimer'),
    ),
  ]);

  Widget _buildLogoutCard() => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: _confirmLogout,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.red.shade100),
          boxShadow: [
            BoxShadow(color: Colors.red.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.logout_rounded, color: Colors.red.shade400, size: 20),
            ),
            const SizedBox(width: 12),
            Text('تسجيل الخروج',
                style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 15, fontWeight: FontWeight.w600, color: Colors.red.shade400)),
          ],
        ),
      ),
    ),
  );

  Widget _buildFooter() => Column(children: [
    Text('IRAQ PHARMA GUIDE',
        style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 10, letterSpacing: 2.5, fontWeight: FontWeight.w700,
            color: AppColors.textSecondary.withOpacity(0.5))),
    const SizedBox(height: 2),
    Text('v2.1.0',
        style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 10, color: AppColors.textSecondary.withOpacity(0.4))),
  ]);
}

// ── Avatar ────────────────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String initials;
  const _Avatar({required this.initials});
  @override
  Widget build(BuildContext context) => Stack(children: [
    Container(
      width: 96, height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.darkNavy, AppColors.primary],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Center(child: Text(initials,
          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold))),
    ),
    Positioned(
      bottom: 2, left: 2,
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          color: AppColors.primary, shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 15),
      ),
    ),
  ]);
}

// ── Stat card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon; final Color color;
  final String value; final String label;
  const _StatCard({required this.icon, required this.color, required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
    ),
    child: Row(children: [
      Container(
        width: 42, height: 42,
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 22),
      ),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        Text(label, style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 12, color: AppColors.textSecondary)),
      ]),
    ]),
  );
}

// ── Icon badge ────────────────────────────────────────────────────────────────
class _IconBadge extends StatelessWidget {
  final IconData icon; final Color color;
  const _IconBadge({required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    width: 38, height: 38,
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(11)),
    child: Icon(icon, color: color, size: 20),
  );
}

// ── Language badge ────────────────────────────────────────────────────────────
class _LangBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(20)),
    child: Text('عربية / English',
        style: GoogleFonts.ibmPlexSansArabic(fontSize: 11, color: const Color(0xFF2E7D32), fontWeight: FontWeight.w500)),
  );
}

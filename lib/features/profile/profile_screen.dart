import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/admin_access_service.dart';
import '../../services/auth_service.dart';
import '../../services/avatar_service.dart';
import '../../services/notification_permission_service.dart';
import '../../services/session_service.dart';
import '../../shared/widgets/app_drawer.dart';
import '../../shared/widgets/compact_app_header.dart';
import '../../core/l10n/app_strings.dart';
// ignore: unused_import
import 'interactive_reference_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _profile;
  bool    _loading         = true;
  bool    _uploadingAvatar = false;
  String? _avatarUrl;
  bool    _isSuperAdmin    = false;
  bool    _pushEnabled     = true;
  bool    _pushBusy        = false;
  bool    _deleting        = false;
  String  _appVersion      = '';

  late final AnimationController _avatarCtrl;
  late final Animation<double>   _avatarScale;

  @override
  void initState() {
    super.initState();
    _avatarCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _avatarScale = CurvedAnimation(parent: _avatarCtrl, curve: Curves.elasticOut);
    _loadProfile();
    _loadAdminAccess();
    _loadPushState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _appVersion = info.version);
    } catch (_) {}
  }

  Future<void> _loadPushState() async {
    final enabled = await NotificationPermissionService.instance.isEnabled();
    if (mounted) setState(() => _pushEnabled = enabled);
  }

  /// Kept deliberately quiet in the UI — App Store 5.1.1(v) requires the
  /// option to be findable, not prominent. Confirmation is typed, not tapped.
  Future<void> _confirmDeleteAccount() async {
    if (_deleting) return;
    final cs = Theme.of(context).colorScheme;
    final word = context.s.deleteAccountConfirmWord;
    final ctrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dCtx) => StatefulBuilder(
        builder: (dCtx, setLocal) {
          final matches = ctrl.text.trim() == word;
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Row(children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.red, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(context.s.deleteAccount,
                    style: GoogleFonts.ibmPlexSansArabic(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ]),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.s.deleteAccountBody,
                    style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 13, height: 1.7,
                        color: cs.onSurfaceVariant)),
                const SizedBox(height: 14),
                TextField(
                  controller: ctrl,
                  onChanged: (_) => setLocal(() {}),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: word,
                    isDense: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dCtx, false),
                child: Text(context.s.cancel,
                    style: GoogleFonts.ibmPlexSansArabic(
                        color: cs.onSurfaceVariant)),
              ),
              ElevatedButton(
                onPressed: matches ? () => Navigator.pop(dCtx, true) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: cs.outline.withOpacity(0.3),
                  elevation: 0,
                ),
                child: Text(context.s.deleteAccountConfirm,
                    style: GoogleFonts.ibmPlexSansArabic(
                        fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    final ok = await AuthService.instance.deleteAccount();
    if (!mounted) return;
    setState(() => _deleting = false);

    if (ok) {
      context.go('/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.deleteAccountFailed)),
      );
    }
  }

  Future<void> _togglePush() async {
    if (_pushBusy) return;
    setState(() => _pushBusy = true);
    final target = !_pushEnabled;
    bool result = _pushEnabled;
    try {
      result = await NotificationPermissionService.instance.setEnabled(target);
    } catch (e) {
      debugPrint('Push toggle failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    } finally {
      // Always clear the busy flag, even on error, so the switch never
      // gets stuck unresponsive.
      if (mounted) setState(() => _pushBusy = false);
    }
    if (!mounted) return;
    setState(() => _pushEnabled = result);
    if (target && !result) {
      // User tried to enable but OS-level permission is denied.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.enableNotifFromSettings)),
      );
    }
  }

  Future<void> _loadProfile() async {
    final data = await AuthService.instance.getProfile();
    if (!mounted) return;
    setState(() {
      _profile   = data;
      _loading   = false;
      _avatarUrl = data?['avatar_url'] as String?;
    });
    _avatarCtrl.forward();
  }

  Future<void> _loadAdminAccess() async {
    final access = await AdminAccessService.instance.hasAccess();
    if (mounted) setState(() => _isSuperAdmin = access);
  }

  Future<void> _pickAvatar() async {
    setState(() => _uploadingAvatar = true);
    final url = await AvatarService.instance.pickAndUpload();
    if (!mounted) return;
    setState(() {
      _uploadingAvatar = false;
      if (url != null) _avatarUrl = url;
    });
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

  void _showLangDialog(BuildContext ctx, WidgetRef ref, bool isArabic) {
    final cs = Theme.of(ctx).colorScheme;
    showModalBottomSheet(
      context: ctx,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: cs.outline,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text(context.s.langDialogTitle,
                style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 16, fontWeight: FontWeight.bold,
                    color: cs.onSurface)),
            const SizedBox(height: 12),
            _LangOption(
              label: 'العربية', sublabel: 'Arabic', flag: '🇮🇶',
              selected: isArabic,
              onTap: () {
                ref.read(localeProvider.notifier).setLocale(const Locale('ar'));
                Navigator.pop(_);
              },
            ),
            _LangOption(
              label: 'English', sublabel: 'الإنجليزية', flag: '🇬🇧',
              selected: !isArabic,
              onTap: () {
                ref.read(localeProvider.notifier).setLocale(const Locale('en'));
                Navigator.pop(_);
              },
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '؟';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  String _spacedName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.join('  ');
  }

  Future<void> _confirmLogout() async {
    final cs = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.logout_rounded, color: Colors.red, size: 22),
          const SizedBox(width: 10),
          Text(context.s.signOut,
              style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold, fontSize: 17)),
        ]),
        content: Text(context.s.signOutConfirm,
            style: GoogleFonts.ibmPlexSansArabic(fontSize: 14, color: cs.onSurfaceVariant)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.s.cancel,
                style: GoogleFonts.ibmPlexSansArabic(color: cs.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text(context.s.signOut, style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w600)),
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
    // ── watch theme so the entire screen rebuilds on toggle ──
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final cs     = Theme.of(context).colorScheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        drawer: const AppDrawer(),
        body: _loading ? _buildLoader(cs) : _buildBody(cs, isDark),
      ),
    );
  }

  Widget _buildLoader(ColorScheme cs) => Center(
    child: CircularProgressIndicator(color: cs.primary),
  );

  Widget _buildBody(ColorScheme cs, bool isDark) {
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
                _buildUserCard(cs),
                const SizedBox(height: 16),
                _buildStatsRow(cs),
                const SizedBox(height: 16),
                _buildCard(cs, children: [
                  _buildNavTile(cs,
                    icon: Icons.manage_accounts_outlined,
                    color: AppColors.primary,
                    title: context.s.editProfile,
                    onTap: () async {
                      await context.push('/edit-profile');
                      _loadProfile();
                    },
                  ),
                  _divider(cs),
                  _buildNavTile(cs,
                    icon: Icons.menu_book_outlined,
                    color: const Color(0xFF5C6BC0),
                    title: context.s.interactiveRef,
                    onTap: () => context.push('/interactive-reference'),
                  ),
                ]),
                const SizedBox(height: 12),
                _buildCard(cs, children: [
                  Consumer(builder: (ctx, ref, _) {
                    final locale   = ref.watch(localeProvider);
                    final isArabic = locale.languageCode == 'ar';
                    return _buildNavTile(cs,
                      icon: Icons.language_rounded,
                      color: const Color(0xFF00897B),
                      title: ctx.s.appLanguage,
                      trailing: _LangBadge(isArabic: isArabic),
                      onTap: () => _showLangDialog(ctx, ref, isArabic),
                    );
                  }),
                  _divider(cs),
                  // ── Dark mode toggle ─────────────────────────────────
                  _buildThemeToggleRow(cs, isDark),
                  _divider(cs),
                  // ── Push notifications toggle ────────────────────────
                  _buildPushToggleRow(cs),
                  _divider(cs),
                ]),
                const SizedBox(height: 12),
                _buildCard(cs, children: [
                  _buildNavTile(cs,
                    icon: Icons.help_outline_rounded,
                    color: const Color(0xFF00897B),
                    title: context.s.support,
                    onTap: () => context.push('/support'),
                  ),
                  _divider(cs),
                  _buildNavTile(cs,
                    icon: Icons.lightbulb_outline_rounded,
                    color: const Color(0xFFF57C00),
                    title: context.s.sendSuggestion,
                    onTap: () => context.push('/suggestion'),
                  ),
                ]),
                const SizedBox(height: 12),
                _buildCard(cs, children: [
                  _buildNavTile(cs,
                    icon: Icons.shield_outlined,
                    color: const Color(0xFF1565C0),
                    title: context.s.privacyPolicy,
                    onTap: () => context.push('/legal/privacy'),
                  ),
                  _divider(cs),
                  _buildNavTile(cs,
                    icon: Icons.gavel_rounded,
                    color: const Color(0xFF6A1B9A),
                    title: context.s.termsOfUse,
                    onTap: () => context.push('/legal/terms'),
                  ),
                  _divider(cs),
                  _buildNavTile(cs,
                    icon: Icons.warning_amber_rounded,
                    color: const Color(0xFFE65100),
                    title: context.s.disclaimer,
                    onTap: () => context.push('/legal/disclaimer'),
                  ),
                ]),
                if (_isSuperAdmin) ...[
                  const SizedBox(height: 12),
                  _buildCard(cs, children: [
                    _buildNavTile(cs,
                      icon: Icons.bar_chart_rounded,
                      color: const Color(0xFF6366F1),
                      title: 'إحصائيات التطبيق',
                      onTap: () => context.push('/admin/statistics'),
                    ),
                    _divider(cs),
                    _buildNavTile(cs,
                      icon: Icons.admin_panel_settings_outlined,
                      color: const Color(0xFF455A64),
                      title: 'إدارة قاعدة البيانات',
                      onTap: () => context.push('/admin-pin'),
                    ),
                  ]),
                ],
                const SizedBox(height: 16),
                _buildLogoutCard(cs),
                _buildDeleteAccountLink(cs),
                const SizedBox(height: 20),
                _buildFooter(cs),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── App Header ────────────────────────────────────────────────────────────
  Widget _buildAppHeader() => SliverToBoxAdapter(
    child: Builder(builder: (ctx) => CompactAppHeader(title: ctx.s.myAccount)),
  );

  // ── User card ─────────────────────────────────────────────────────────────
  Widget _buildUserCard(ColorScheme cs) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: cs.primary.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
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
                  child: GestureDetector(
                    onTap: _uploadingAvatar ? null : _pickAvatar,
                    child: Stack(
                      children: [
                        _Avatar(initials: _initials(_fullName), avatarUrl: _avatarUrl, cs: cs),
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            width: 30, height: 30,
                            decoration: BoxDecoration(
                              color: _uploadingAvatar ? Colors.grey : AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: cs.surface, width: 2),
                            ),
                            child: _uploadingAvatar
                                ? const Padding(
                                    padding: EdgeInsets.all(6),
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 15),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _spacedName(_fullName),
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 22, fontWeight: FontWeight.bold,
                    color: cs.onSurface, letterSpacing: 0.5, wordSpacing: 6,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.alternate_email_rounded, size: 13, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(_username,
                        style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500)),
                  ]),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
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

  // ── Stats row ─────────────────────────────────────────────────────────────
  Widget _buildStatsRow(ColorScheme cs) {
    return Row(
      children: [
        Expanded(child: _StatCard(
          icon: Icons.search_rounded, color: AppColors.primary,
          value: _formatStat(_drugSearches), label: context.s.drugSearchStat, cs: cs)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(
          icon: Icons.build_outlined, color: const Color(0xFF5C6BC0),
          value: _formatStat(_toolUsage), label: context.s.toolUsageStat, cs: cs)),
      ],
    );
  }

  // ── Generic card container ────────────────────────────────────────────────
  Widget _buildCard(ColorScheme cs, {required List<Widget> children}) => Container(
    decoration: BoxDecoration(
      color: cs.surface,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
      ],
    ),
    child: Column(children: children),
  );

  Widget _divider(ColorScheme cs) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Divider(height: 1, color: cs.outline.withOpacity(0.5)),
  );

  // ── Navigation tile ───────────────────────────────────────────────────────
  Widget _buildNavTile(ColorScheme cs, {
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
            Icon(Icons.chevron_left_rounded, size: 20, color: cs.outline),
            if (trailing != null) ...[const SizedBox(width: 8), trailing],
            const Spacer(),
            Text(title,
                style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 15, fontWeight: FontWeight.w500, color: cs.onSurface)),
            const SizedBox(width: 14),
            _IconBadge(icon: icon, color: color),
          ]),
        ),
      ),
    );
  }

  // ── Sun / Moon animated theme toggle ─────────────────────────────────────
  Widget _buildThemeToggleRow(ColorScheme cs, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        // Animated toggle pill
        GestureDetector(
          onTap: () => ref.read(themeProvider.notifier).toggle(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            width: 60,
            height: 32,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.accent : Colors.amber.shade400,
                width: 1.5,
              ),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              alignment: isDark ? Alignment.centerLeft : Alignment.centerRight,
              child: Container(
                margin: const EdgeInsets.all(3),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.accent : Colors.amber.shade400,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? AppColors.accent : Colors.amber).withOpacity(0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Icon(
                  isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                  color: Colors.white,
                  size: 15,
                ),
              ),
            ),
          ),
        ),
        const Spacer(),
        Text(
          context.s.darkMode,
          style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 15, fontWeight: FontWeight.w500, color: cs.onSurface),
        ),
        const SizedBox(width: 14),
        _IconBadge(
          icon: isDark ? Icons.nightlight_round : Icons.wb_sunny_outlined,
          color: isDark ? AppColors.accent : const Color(0xFF5E35B1),
        ),
      ]),
    );
  }

  // ── Push notifications on/off toggle ─────────────────────────────────────
  Widget _buildPushToggleRow(ColorScheme cs) {
    final isOn = _pushEnabled;
    // Green when on, neutral grey when off.
    final onColor = const Color(0xFF10B981);
    final offColor = cs.outline;
    final knobColor = isOn ? onColor : offColor;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        GestureDetector(
          onTap: _pushBusy ? null : _togglePush,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            width: 60,
            height: 32,
            decoration: BoxDecoration(
              color: knobColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: knobColor, width: 1.5),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              // Knob sits on the right when ON, matching the toggle above it.
              alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.all(3),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: knobColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: knobColor.withOpacity(0.4), blurRadius: 6),
                  ],
                ),
                child: _pushBusy
                    ? const Padding(
                        padding: EdgeInsets.all(6),
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(
                        isOn ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
              ),
            ),
          ),
        ),
        const Spacer(),
        Text(
          context.s.notifications,
          style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 15, fontWeight: FontWeight.w500, color: cs.onSurface),
        ),
        const SizedBox(width: 14),
        _IconBadge(
          icon: isOn ? Icons.notifications_active_outlined : Icons.notifications_off_outlined,
          color: knobColor,
        ),
      ]),
    );
  }

  // ── Logout card ───────────────────────────────────────────────────────────
  Widget _buildLogoutCard(ColorScheme cs) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: _confirmLogout,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.red.shade200.withOpacity(0.6)),
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
            Text(context.s.signOut,
                style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 15, fontWeight: FontWeight.w600, color: Colors.red.shade400)),
          ],
        ),
      ),
    ),
  );

  // ── Footer ────────────────────────────────────────────────────────────────
  Widget _buildDeleteAccountLink(ColorScheme cs) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 2),
    child: Center(
      child: _deleting
          ? const SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2))
          : GestureDetector(
              onTap: _confirmDeleteAccount,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 6),
                child: Text(
                  context.s.deleteAccount,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: cs.onSurfaceVariant.withOpacity(0.5),
                    decoration: TextDecoration.underline,
                    decorationColor: cs.onSurfaceVariant.withOpacity(0.3),
                  ),
                ),
              ),
            ),
    ),
  );

  Widget _buildFooter(ColorScheme cs) => Column(children: [
    Text('Iraq Pharma Guide ® 2026',
        style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: cs.onSurfaceVariant.withOpacity(0.7))),
    const SizedBox(height: 3),
    // Read from the binary so it can never drift from pubspec again.
    Text('${context.s.version} v${_appVersion.isEmpty ? '' : _appVersion}',
        style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 11, color: cs.onSurfaceVariant.withOpacity(0.45))),
  ]);
}

// ── Avatar ────────────────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String initials;
  final String? avatarUrl;
  final ColorScheme cs;
  const _Avatar({required this.initials, this.avatarUrl, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96, height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.darkNavy, AppColors.primary],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        border: Border.all(color: cs.surface, width: 4),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: ClipOval(
        child: avatarUrl != null && avatarUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: avatarUrl!,
                fit: BoxFit.cover, width: 96, height: 96,
                placeholder: (_, __) => const Center(
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                errorWidget: (_, __, ___) => Center(child: Text(initials,
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold))),
              )
            : Center(child: Text(initials,
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold))),
      ),
    );
  }
}

// ── Stat card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon; final Color color;
  final String value; final String label;
  final ColorScheme cs;
  const _StatCard({required this.icon, required this.color,
      required this.value, required this.label, required this.cs});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
    decoration: BoxDecoration(
      color: cs.surface, borderRadius: BorderRadius.circular(18),
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
            fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface)),
        Text(label, style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 12, color: cs.onSurfaceVariant)),
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
  final bool isArabic;
  const _LangBadge({required this.isArabic});

  @override
  Widget build(BuildContext context) {
    final label = isArabic ? '🇮🇶  العربية' : '🇬🇧  English';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF00897B).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00897B).withOpacity(0.3)),
      ),
      child: Text(label,
          style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 12, color: const Color(0xFF00695C), fontWeight: FontWeight.w600)),
    );
  }
}

// ── Language option in bottom sheet ──────────────────────────────────────────
class _LangOption extends StatelessWidget {
  final String label, sublabel, flag;
  final bool selected;
  final VoidCallback onTap;
  const _LangOption({required this.label, required this.sublabel,
      required this.flag, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF00897B).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? const Color(0xFF00897B) : cs.outline,
              width: selected ? 1.5 : 1),
        ),
        child: Row(children: [
          Text(flag, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    color: selected ? const Color(0xFF00695C) : cs.onSurface)),
            Text(sublabel,
                style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 12, color: cs.onSurfaceVariant)),
          ])),
          if (selected)
            Container(
              width: 22, height: 22,
              decoration: const BoxDecoration(color: Color(0xFF00897B), shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
            ),
        ]),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';

class AdminStatisticsScreen extends StatefulWidget {
  const AdminStatisticsScreen({super.key});
  @override
  State<AdminStatisticsScreen> createState() => _AdminStatisticsScreenState();
}

class _AdminStatisticsScreenState extends State<AdminStatisticsScreen> {
  Map<String, dynamic>? _stats;
  bool  _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await Supabase.instance.client.rpc('get_app_statistics');
      if (mounted) setState(() { _stats = Map<String, dynamic>.from(res); _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('إحصائيات التطبيق',
            style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _ErrorState(error: _error!, onRetry: _load)
              : _buildContent(cs),
    );
  }

  Widget _buildContent(ColorScheme cs) {
    final s = _stats!;
    final topDrugs = (s['top_drugs'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [

          // ── المستخدمون ─────────────────────────────────────────────
          _SectionHeader(title: 'المستخدمون', icon: Icons.people_alt_rounded),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _StatCard(
              label: 'إجمالي المسجلين',
              value: '${s['total_users'] ?? 0}',
              icon: Icons.group_rounded,
              color: AppColors.primary,
            )),
            const SizedBox(width: 10),
            Expanded(child: _StatCard(
              label: 'حسابات مفعّلة',
              value: '${s['confirmed_users'] ?? 0}',
              icon: Icons.verified_user_rounded,
              color: const Color(0xFF10B981),
            )),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _StatCard(
              label: 'جدد هذا الشهر',
              value: '${s['users_this_month'] ?? 0}',
              icon: Icons.calendar_month_rounded,
              color: const Color(0xFF6366F1),
            )),
            const SizedBox(width: 10),
            Expanded(child: _StatCard(
              label: 'جدد هذا الأسبوع',
              value: '${s['users_this_week'] ?? 0}',
              icon: Icons.date_range_rounded,
              color: const Color(0xFFF59E0B),
            )),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _StatCard(
              label: 'تسجيلات اليوم',
              value: '${s['users_today'] ?? 0}',
              icon: Icons.today_rounded,
              color: const Color(0xFFEF4444),
            )),
            const SizedBox(width: 10),
            Expanded(child: _StatCard(
              label: 'المدراء',
              value: '${s['total_admins'] ?? 0}',
              icon: Icons.admin_panel_settings_rounded,
              color: const Color(0xFF455A64),
            )),
          ]),

          const SizedBox(height: 24),

          // ── دليل الأسعار ───────────────────────────────────────────
          _SectionHeader(title: 'دليل الأسعار التجاري', icon: Icons.price_check_rounded),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _StatCard(
              label: 'إجمالي المنتجات',
              value: '${s['total_pricing_entries'] ?? 0}',
              icon: Icons.inventory_2_rounded,
              color: const Color(0xFF0EA5E9),
            )),
            const SizedBox(width: 10),
            Expanded(child: _StatCard(
              label: 'إجمالي المشاهدات',
              value: _formatNumber(s['total_price_views'] ?? 0),
              icon: Icons.visibility_rounded,
              color: const Color(0xFF8B5CF6),
            )),
          ]),

          if (topDrugs.isNotEmpty) ...[
            const SizedBox(height: 24),
            _SectionHeader(title: 'أكثر الأدوية بحثاً', icon: Icons.trending_up_rounded),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                children: topDrugs.asMap().entries.map((e) {
                  final idx   = e.key;
                  final drug  = e.value;
                  final name  = drug['trade_name'] as String? ?? '';
                  final views = drug['view_count'] as int? ?? 0;
                  final maxViews = (topDrugs.first['view_count'] as int? ?? 1).clamp(1, 999999);
                  return _DrugRankTile(
                    rank: idx + 1,
                    name: name,
                    views: views,
                    maxViews: maxViews,
                    isLast: idx == topDrugs.length - 1,
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatNumber(dynamic n) {
    final num = int.tryParse(n.toString()) ?? 0;
    if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M';
    if (num >= 1000)    return '${(num / 1000).toStringAsFixed(1)}K';
    return '$num';
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 18, color: AppColors.primary),
    const SizedBox(width: 8),
    Text(title, style: GoogleFonts.ibmPlexSansArabic(
        fontSize: 15, fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface)),
  ]);
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value,
      required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 12),
        Text(value, style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 26, fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ]),
    );
  }
}

class _DrugRankTile extends StatelessWidget {
  final int rank;
  final String name;
  final int views;
  final int maxViews;
  final bool isLast;
  const _DrugRankTile({required this.rank, required this.name,
      required this.views, required this.maxViews, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final pct = maxViews > 0 ? views / maxViews : 0.0;
    final rankColor = rank == 1
        ? const Color(0xFFF59E0B)
        : rank == 2
            ? const Color(0xFF9CA3AF)
            : rank == 3
                ? const Color(0xFFCD7C32)
                : AppColors.primary.withOpacity(0.5);

    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: rankColor.withOpacity(0.15), shape: BoxShape.circle),
            child: Center(child: Text('$rank',
                style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 12, fontWeight: FontWeight.bold, color: rankColor))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct.toDouble(),
                minHeight: 4,
                backgroundColor: Theme.of(context).dividerColor,
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ])),
          const SizedBox(width: 10),
          Text('$views', style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 13, fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(width: 4),
          Icon(Icons.visibility_outlined, size: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ]),
      ),
      if (!isLast) const Divider(height: 1),
    ]);
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.cloud_off_outlined, size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4)),
        const SizedBox(height: 16),
        Text('تعذّر تحميل الإحصائيات',
            style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 17, fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        Text(error, textAlign: TextAlign.center,
            style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: Text('إعادة المحاولة',
              style: GoogleFonts.ibmPlexSansArabic()),
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, foregroundColor: Colors.white),
        ),
      ]),
    ),
  );
}

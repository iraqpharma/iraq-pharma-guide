import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../services/app_admin_service.dart';
import '../../services/availability_service.dart';
import '../../services/jobs_service.dart';

/// «إعدادات التطبيق» — مركز إداري واحد لكل ما يحتاج موافقة أو متابعة،
/// بدل تفرّق الأقسام في شاشات لا يعرف صاحب التطبيق مكانها.
class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  int _availPending = 0;
  int _jobsPending  = 0;
  int _reqNew       = 0;
  bool _loading     = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final a = await AvailabilityService.instance.pendingCount();
    final j = await JobsService.instance.pendingCount();
    final r = await AppAdminService.instance.newRequestsCount();
    if (!mounted) return;
    setState(() {
      _availPending = a;
      _jobsPending  = j;
      _reqNew       = r;
      _loading      = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final pending = _availPending + _jobsPending + _reqNew;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('إعدادات التطبيق',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: () {
              setState(() => _loading = true);
              _load();
            },
            icon: const Icon(Icons.refresh_rounded, size: 21),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
          children: [
            // ── ملخّص ما ينتظر الموافقة ────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: pending > 0
                      ? [
                          AppColors.warningAmber.withOpacity(0.18),
                          AppColors.warningAmber.withOpacity(0.05),
                        ]
                      : [
                          AppColors.successGreen.withOpacity(0.16),
                          AppColors.successGreen.withOpacity(0.04),
                        ],
                ),
                border: Border.all(
                  color: (pending > 0
                          ? AppColors.warningAmber
                          : AppColors.successGreen)
                      .withOpacity(0.25),
                ),
              ),
              child: Row(children: [
                Icon(
                    pending > 0
                        ? Icons.pending_actions_rounded
                        : Icons.verified_rounded,
                    size: 30,
                    color: pending > 0
                        ? AppColors.warningAmber
                        : AppColors.successGreen),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _loading
                            ? 'جاري الفحص…'
                            : (pending > 0
                                ? '$pending عنصراً ينتظر قرارك'
                                : 'لا شيء ينتظر الموافقة'),
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        pending > 0
                            ? 'لا يظهر أي إعلان للمستخدمين قبل موافقتك'
                            : 'كل الإعلانات والطلبات مُراجَعة',
                        style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ]),
            ),

            const _GroupTitle('الموافقات'),
            _AdminTile(
              icon: Icons.inventory_2_rounded,
              color: const Color(0xFF2E8B82),
              title: 'إعلانات توفّر الأدوية',
              subtitle: 'إعلانات الصيدليات عن توفّر دواء عندها',
              badge: _availPending,
              onTap: () async {
                await context.push('/admin/availability');
                _load();
              },
            ),
            _AdminTile(
              icon: Icons.work_rounded,
              color: const Color(0xFF3A72B8),
              title: 'إعلانات فرص العمل',
              subtitle: 'مراجعة إعلانات الوظائف قبل نشرها',
              badge: _jobsPending,
              onTap: () async {
                await context.push('/jobs/review');
                _load();
              },
            ),
            _AdminTile(
              icon: Icons.playlist_add_check_rounded,
              color: const Color(0xFF7A4EA8),
              title: 'طلبات إضافة الأدوية',
              subtitle: 'ما يقترحه المستخدمون من أدوية ناقصة',
              badge: _reqNew,
              onTap: () async {
                await context.push('/admin/drug-requests');
                _load();
              },
            ),

            const _GroupTitle('المحتوى'),
            _AdminTile(
              icon: Icons.ondemand_video_rounded,
              color: const Color(0xFFC2454B),
              title: 'الفيديوهات التعليمية',
              subtitle: 'إضافة ونشر وإخفاء الفيديوهات',
              onTap: () => context.push('/videos'),
            ),
            _AdminTile(
              icon: Icons.campaign_rounded,
              color: const Color(0xFFD08A3E),
              title: 'الإعلانات التجارية',
              subtitle: 'تشغيل وإيقاف إعلانات الشاشة الرئيسية',
              onTap: () => context.push('/admin/ads'),
            ),

            const _GroupTitle('قاعدة البيانات'),
            _AdminTile(
              icon: Icons.medication_rounded,
              color: const Color(0xFF00897B),
              title: 'إدارة الأدوية',
              subtitle: 'إضافة وتعديل وحذف الأدوية',
              onTap: () => context.push('/admin/drugs'),
            ),
            _AdminTile(
              icon: Icons.insert_chart_rounded,
              color: const Color(0xFF6B6BC4),
              title: 'الإحصائيات',
              subtitle: 'المستخدمون والاستعمال',
              onTap: () => context.push('/admin/statistics'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupTitle extends StatelessWidget {
  final String text;
  const _GroupTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 9),
        child: Row(children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(text,
              style: const TextStyle(
                  fontSize: 13.5, fontWeight: FontWeight.bold)),
        ]),
      );
}

class _AdminTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final int badge;
  final VoidCallback onTap;

  const _AdminTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? cs.surface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.07)
                : const Color(0xFFECEFF2),
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: color.withOpacity(0.13),
                    blurRadius: 11,
                    spreadRadius: -3,
                    offset: const Offset(0, 5),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            splashColor: color.withOpacity(0.08),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
              child: Row(children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withOpacity(isDark ? 0.30 : 0.17),
                        color.withOpacity(isDark ? 0.14 : 0.07),
                      ],
                    ),
                  ),
                  child: Icon(icon, color: color, size: 21),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              height: 1.25)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: TextStyle(
                              fontSize: 11.5,
                              height: 1.35,
                              color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                if (badge > 0)
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.errorRed,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('$badge',
                        style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                Icon(Icons.chevron_left_rounded,
                    color: cs.onSurfaceVariant.withOpacity(0.5), size: 22),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

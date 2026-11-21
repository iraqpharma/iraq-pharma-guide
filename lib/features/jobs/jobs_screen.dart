import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/governorate_style.dart';
import '../../data/models/job_post.dart';
import '../../services/admin_access_service.dart';
import '../../services/jobs_service.dart';

/// ألوان أنواع الدوام — خط رفيع متدرّج على حافة البطاقة يميّز النوع
/// قبل قراءة النص.
const _workTypeColors = <String, Color>{
  'full_time': Color(0xFF00897B),
  'part_time': Color(0xFF3A72B8),
  'shift':     Color(0xFF7A4EA8),
  'temporary': Color(0xFFC98A2E),
};

const _workTypeIcons = <String, IconData>{
  'full_time': Icons.schedule_rounded,
  'part_time': Icons.hourglass_bottom_rounded,
  'shift':     Icons.bedtime_rounded,
  'temporary': Icons.event_available_rounded,
};

Color _wtColor(String k) => _workTypeColors[k] ?? AppColors.primary;

/// قسم فرص العمل للصيادلة — عرض الإعلانات المعتمدة.
class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  String _city = '';
  String _workType = '';
  bool _isAdmin = false;
  int _pending = 0;
  bool _govExpanded = false;

  late Future<List<JobPost>> _future;
  late Future<Map<String, int>> _counts;

  @override
  void initState() {
    super.initState();
    _future = JobsService.instance.listLive();
    _counts = JobsService.instance.cityCounts();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    final ok = await AdminAccessService.instance.hasAccess();
    if (!ok || !mounted) return;
    final n = await JobsService.instance.pendingCount();
    if (!mounted) return;
    setState(() {
      _isAdmin = true;
      _pending = n;
    });
  }

  void _reload({bool withCounts = false}) {
    setState(() {
      _future = JobsService.instance.listLive(
        city: _city.isEmpty ? null : _city,
        workType: _workType.isEmpty ? null : _workType,
      );
      if (withCounts) _counts = JobsService.instance.cityCounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: theme.scaffoldBackgroundColor,
        title: const Text('فرص عمل للصيادلة',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [
          if (_isAdmin)
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    tooltip: 'مراجعة الإعلانات',
                    icon: const Icon(Icons.fact_check_outlined, size: 22),
                    onPressed: () async {
                      await context.push('/jobs/review');
                      _checkAdmin();
                      _reload(withCounts: true);
                    },
                  ),
                  if (_pending > 0)
                    Positioned(
                      top: 8,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.errorRed,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('$_pending',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
          IconButton(
            tooltip: 'إعلاناتي',
            icon: const Icon(Icons.badge_outlined, size: 22),
            onPressed: () => context.push('/jobs/mine'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final added = await context.push('/jobs/new');
          if (added == true) _reload(withCounts: true);
        },
        elevation: 2,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded, size: 21),
        label: const Text('أضف إعلاناً',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _reload(withCounts: true),
        child: CustomScrollView(
          slivers: [
            // ── لوحة المحافظات ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: FutureBuilder<Map<String, int>>(
                future: _counts,
                builder: (_, snap) => _GovBoard(
                  counts: snap.data ?? const {},
                  selected: _city,
                  expanded: _govExpanded,
                  onToggleExpand: () =>
                      setState(() => _govExpanded = !_govExpanded),
                  onSelect: (c) {
                    setState(() {
                      _city = c;
                      if (c.isNotEmpty) _govExpanded = false;
                    });
                    _reload();
                  },
                ),
              ),
            ),

            // ── فلتر نوع الدوام ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: _WorkTypeFilter(
                value: _workType,
                onChanged: (v) {
                  setState(() => _workType = v);
                  _reload();
                },
              ),
            ),

            // ── الإعلانات ────────────────────────────────────────────────
            FutureBuilder<List<JobPost>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }
                if (snap.hasError) {
                  return SliverToBoxAdapter(
                    child: _Empty(
                      icon: Icons.wifi_off_rounded,
                      title: 'تعذّر تحميل الإعلانات',
                      body: 'تأكّد من الاتصال بالإنترنت ثم أعد المحاولة.',
                      onRetry: () => _reload(withCounts: true),
                    ),
                  );
                }
                final jobs = snap.data ?? const <JobPost>[];
                if (jobs.isEmpty) {
                  final filtered = _city.isNotEmpty || _workType.isNotEmpty;
                  return SliverToBoxAdapter(
                    child: _Empty(
                      icon: filtered
                          ? Icons.filter_alt_off_rounded
                          : Icons.work_outline_rounded,
                      title: filtered
                          ? 'لا إعلانات بهذا الفلتر'
                          : 'لا توجد إعلانات حالياً',
                      body: filtered
                          ? 'جرّب محافظة أخرى أو ألغِ الفلتر لترى كل الإعلانات.'
                          : 'كن أول من ينشر فرصة عمل — اضغط «أضف إعلاناً».',
                      onRetry: filtered
                          ? () {
                              setState(() {
                                _city = '';
                                _workType = '';
                              });
                              _reload();
                            }
                          : null,
                      retryLabel: filtered ? 'إلغاء الفلاتر' : null,
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 96),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => JobCard(job: jobs[i]),
                      childCount: jobs.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// لوحة المحافظات — أيقونة بلون المحافظة وتحتها عدد الوظائف
// ═══════════════════════════════════════════════════════════════════════════════

class _GovBoard extends StatelessWidget {
  final Map<String, int> counts;
  final String selected;
  final bool expanded;
  final VoidCallback onToggleExpand;
  final ValueChanged<String> onSelect;

  const _GovBoard({
    required this.counts,
    required this.selected,
    required this.expanded,
    required this.onToggleExpand,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final cs    = Theme.of(context).colorScheme;
    final total = counts.values.fold<int>(0, (p, v) => p + v);

    // الترتيب: الأكثر وظائف أولاً، والمحافظات بلا وظائف في الذيل.
    final all = [...JobsService.iraqCities]..sort((a, b) {
      final d = (counts[b] ?? 0).compareTo(counts[a] ?? 0);
      return d != 0 ? d : a.compareTo(b);
    });
    final withJobs = all.where((c) => (counts[c] ?? 0) > 0).toList();
    final strip    = withJobs.isEmpty ? all.take(8).toList() : withJobs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 10, 8),
          child: Row(children: [
            Container(
              width: 3,
              height: 15,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            const Text('المحافظات',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Text('$total وظيفة',
                style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant)),
            const Spacer(),
            TextButton(
              onPressed: onToggleExpand,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Row(children: [
                Text(expanded ? 'إخفاء' : 'كل المحافظات',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600)),
                Icon(expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded, size: 18),
              ]),
            ),
          ]),
        ),

        if (expanded)
          // شبكة كل المحافظات
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _GovTile(
                  label: 'الكل',
                  icon: Icons.public_rounded,
                  color: AppColors.primary,
                  count: total,
                  active: selected.isEmpty,
                  onTap: () => onSelect(''),
                  width: 78,
                ),
                ...all.map((c) => _GovTile(
                      label: c,
                      icon: GovStyle.of(c).icon,
                      color: GovStyle.of(c).color,
                      count: counts[c] ?? 0,
                      active: selected == c,
                      onTap: () => onSelect(selected == c ? '' : c),
                      width: 78,
                    )),
              ],
            ),
          )
        else
          // شريط أفقي بالمحافظات التي فيها وظائف
          SizedBox(
            height: 92,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
              children: [
                _GovTile(
                  label: 'الكل',
                  icon: Icons.public_rounded,
                  color: AppColors.primary,
                  count: total,
                  active: selected.isEmpty,
                  onTap: () => onSelect(''),
                  width: 74,
                ),
                const SizedBox(width: 8),
                for (final c in strip) ...[
                  _GovTile(
                    label: c,
                    icon: GovStyle.of(c).icon,
                    color: GovStyle.of(c).color,
                    count: counts[c] ?? 0,
                    active: selected == c,
                    onTap: () => onSelect(selected == c ? '' : c),
                    width: 74,
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _GovTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final int count;
  final bool active;
  final VoidCallback onTap;
  final double width;

  const _GovTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.count,
    required this.active,
    required this.onTap,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dim    = count == 0 && !active;

    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: color.withOpacity(0.10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: active
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        color.withOpacity(isDark ? 0.34 : 0.18),
                        color.withOpacity(isDark ? 0.16 : 0.06),
                      ],
                    )
                  : null,
              border: Border.all(
                color: active
                    ? color.withOpacity(0.55)
                    : (isDark
                        ? Colors.white.withOpacity(0.07)
                        : const Color(0xFFEDF0F3)),
                width: active ? 1.4 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withOpacity(dim ? 0.08 : 0.20),
                            color.withOpacity(dim ? 0.04 : 0.09),
                          ],
                        ),
                      ),
                      child: Icon(icon,
                          size: 19,
                          color: dim ? color.withOpacity(0.45) : color),
                    ),
                    if (count > 0)
                      Positioned(
                        top: -3,
                        left: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          constraints: const BoxConstraints(minWidth: 17),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                                color: isDark ? cs.surface : Colors.white,
                                width: 1.5),
                          ),
                          child: Text('$count',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 9.5,
                                  height: 1.25,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      height: 1.15,
                      fontWeight: active ? FontWeight.bold : FontWeight.w600,
                      color: dim
                          ? cs.onSurfaceVariant.withOpacity(0.6)
                          : cs.onSurface,
                    )),
                const SizedBox(height: 1),
                Text(count == 0 ? '—' : 'وظيفة',
                    style: TextStyle(
                        fontSize: 8.5,
                        color: cs.onSurfaceVariant.withOpacity(0.75))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// فلتر نوع الدوام
// ═══════════════════════════════════════════════════════════════════════════════

class _WorkTypeFilter extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _WorkTypeFilter({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
        children: [
          _FilterPill(
            label: 'كل الأنواع',
            icon: Icons.tune_rounded,
            color: AppColors.primary,
            active: value.isEmpty,
            onTap: () => onChanged(''),
          ),
          const SizedBox(width: 7),
          for (final e in JobPost.workTypeLabels.entries) ...[
            _FilterPill(
              label: e.value,
              icon: _workTypeIcons[e.key] ?? Icons.schedule_rounded,
              color: _wtColor(e.key),
              active: value == e.key,
              onTap: () => onChanged(value == e.key ? '' : e.key),
            ),
            const SizedBox(width: 7),
          ],
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool active;
  final VoidCallback onTap;
  const _FilterPill({
    required this.label,
    required this.icon,
    required this.color,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: active
              ? LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [color, Color.lerp(color, Colors.black, 0.18)!],
                )
              : null,
          border: Border.all(
            color: active
                ? Colors.transparent
                : (isDark
                    ? Colors.white.withOpacity(0.09)
                    : const Color(0xFFE6EAEE)),
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.28),
                    blurRadius: 9,
                    spreadRadius: -2,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              size: 15,
              color: active ? Colors.white : color.withOpacity(0.9)),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: active ? FontWeight.bold : FontWeight.w600,
                color: active ? Colors.white : cs.onSurface,
              )),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// بطاقة الإعلان
// ═══════════════════════════════════════════════════════════════════════════════

class JobCard extends StatelessWidget {
  final JobPost job;
  final bool showStatus;
  const JobCard({super.key, required this.job, this.showStatus = false});

  Future<void> _dial(String raw) async {
    final uri = Uri.parse('tel:${raw.replaceAll(RegExp(r'[^0-9+]'), '')}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _whatsapp(String raw) async {
    var n = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (n.startsWith('0')) n = '964${n.substring(1)}';
    final uri = Uri.parse('https://wa.me/$n');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme      = Theme.of(context);
    final cs         = theme.colorScheme;
    final isDark     = theme.brightness == Brightness.dark;
    final negotiable = job.salaryNegotiable || job.salaryMin == null;
    final gov        = GovStyle.of(job.city);
    final wt         = _wtColor(job.workType);

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      decoration: BoxDecoration(
        color: isDark ? cs.surface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.07)
              : const Color(0xFFECEFF2),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: gov.color.withOpacity(0.13),
                  blurRadius: 12,
                  spreadRadius: -4,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── خط رفيع متدرّج يميّز نوع الدوام ───────────────────────
            Container(
              width: 3.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [wt, wt.withOpacity(0.25)],
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── الترويسة ─────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: Row(children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(13),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              gov.color.withOpacity(isDark ? 0.30 : 0.17),
                              gov.color.withOpacity(isDark ? 0.14 : 0.07),
                            ],
                          ),
                        ),
                        child: Icon(gov.icon, color: gov.color, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(job.pharmacyName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 15,
                                    height: 1.2,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 3),
                            Row(children: [
                              Icon(Icons.place_outlined,
                                  size: 12.5, color: gov.color),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(job.locationAr,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: gov.color)),
                              ),
                            ]),
                          ],
                        ),
                      ),
                      if (showStatus) _StatusPill(status: job.status),
                    ]),
                  ),

                  // ── الوسوم ───────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                    child: Wrap(spacing: 6, runSpacing: 6, children: [
                      _Tag(job.jobTitle, Icons.badge_outlined),
                      _Tag(job.workTypeAr,
                          _workTypeIcons[job.workType] ??
                              Icons.schedule_rounded,
                          color: wt),
                      if (job.shiftText.isNotEmpty)
                        _Tag(job.shiftText, Icons.bedtime_outlined),
                      if (job.genderPref != 'any')
                        _Tag(JobPost.genderLabels[job.genderPref] ?? '',
                            Icons.person_outline_rounded),
                      if (job.experienceText.isNotEmpty)
                        _Tag(job.experienceText, Icons.military_tech_outlined),
                    ]),
                  ),

                  // ── ساعات التواجد ────────────────────────────────────
                  if (job.hoursText.isNotEmpty || job.daysText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 9, 12, 0),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: wt.withOpacity(isDark ? 0.14 : 0.06),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: wt.withOpacity(0.18)),
                        ),
                        child: Row(children: [
                          Icon(Icons.access_time_rounded,
                              size: 15, color: wt),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              [job.hoursText, job.daysText]
                                  .where((e) => e.isNotEmpty)
                                  .join('  ·  '),
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? cs.onSurface : wt),
                            ),
                          ),
                        ]),
                      ),
                    ),

                  // ── الراتب ───────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Row(children: [
                      Icon(
                          negotiable
                              ? Icons.handshake_outlined
                              : Icons.payments_rounded,
                          size: 16,
                          color: negotiable
                              ? AppColors.warningAmber
                              : AppColors.successGreen),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(job.salaryAr,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: negotiable
                                  ? AppColors.warningAmber
                                  : AppColors.successGreen,
                            )),
                      ),
                    ]),
                  ),

                  if (job.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: Text(job.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12.5,
                              height: 1.5,
                              color: cs.onSurface.withOpacity(0.85))),
                    ),

                  const SizedBox(height: 10),
                  Divider(
                      height: 1,
                      thickness: 1,
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : const Color(0xFFF1F3F5)),

                  // ── التذييل ──────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 6, 4),
                    child: Row(children: [
                      Icon(Icons.schedule_rounded,
                          size: 12, color: cs.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(job.agoAr,
                          style: TextStyle(
                              fontSize: 11, color: cs.onSurfaceVariant)),
                      const Spacer(),
                      if (job.contactWhatsapp.isNotEmpty)
                        _FooterAction(
                          icon: Icons.chat_rounded,
                          label: 'واتساب',
                          color: const Color(0xFF25A366),
                          onTap: () => _whatsapp(job.contactWhatsapp),
                        ),
                      const SizedBox(width: 4),
                      _FooterAction(
                        icon: Icons.phone_rounded,
                        label: 'اتصال',
                        color: AppColors.primary,
                        onTap: () {
                          JobsService.instance.bumpView(job.id);
                          _dial(job.contactPhone);
                        },
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _FooterAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ]),
        ),
      );
}

class _Tag extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color? color;
  const _Tag(this.text, this.icon, {this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
            color: color == null
                ? (isDark
                    ? Colors.white.withOpacity(0.10)
                    : const Color(0xFFE7EBEF))
                : c.withOpacity(0.32)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12.5, color: c),
        const SizedBox(width: 4),
        Text(text,
            style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: color == null
                    ? Theme.of(context).colorScheme.onSurface
                    : c)),
      ]),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final map = <String, List<dynamic>>{
      'pending': ['بانتظار المراجعة', AppColors.warningAmber],
      'approved': ['منشور', AppColors.successGreen],
      'rejected': ['مرفوض', AppColors.errorRed],
      'closed': ['مغلق', Colors.grey],
      'expired': ['منتهٍ', Colors.grey],
    };
    final v = map[status] ?? ['—', Colors.grey];
    final color = v[1] as Color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(v[0] as String,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.bold)),
    );
  }
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback? onRetry;
  final String? retryLabel;
  const _Empty({
    required this.icon,
    required this.title,
    required this.body,
    this.onRetry,
    this.retryLabel,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.07),
              ),
              child: Icon(icon,
                  size: 36, color: AppColors.primary.withOpacity(0.55)),
            ),
            const SizedBox(height: 14),
            Text(title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(body,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12.5,
                    height: 1.6,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(retryLabel ?? 'إعادة المحاولة'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary.withOpacity(0.4)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ]),
        ),
      );
}

// ─── إعلاناتي ────────────────────────────────────────────────────────────────

class MyJobsScreen extends StatefulWidget {
  const MyJobsScreen({super.key});

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen> {
  late Future<List<JobPost>> _future = JobsService.instance.listMine();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعلاناتي')),
      body: FutureBuilder<List<JobPost>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final jobs = snap.data ?? const <JobPost>[];
          if (jobs.isEmpty) {
            return const _Empty(
              icon: Icons.inbox_outlined,
              title: 'لم تنشر إعلاناً بعد',
              body: 'إعلاناتك ستظهر هنا مع حالة كل واحد منها.',
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
            children: [
              for (final j in jobs) ...[
                JobCard(job: j, showStatus: true),
                if (j.status == 'rejected' && j.rejectReason.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12, right: 6),
                    child: Text('سبب الرفض: ${j.rejectReason}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.errorRed)),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

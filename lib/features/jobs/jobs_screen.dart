import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/job_post.dart';
import '../../services/admin_access_service.dart';
import '../../services/jobs_service.dart';

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
  late Future<List<JobPost>> _future;

  @override
  void initState() {
    super.initState();
    _future = JobsService.instance.listLive();
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

  void _reload() {
    setState(() {
      _future = JobsService.instance.listLive(
        city: _city.isEmpty ? null : _city,
        workType: _workType.isEmpty ? null : _workType,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('فرص عمل للصيادلة'),
        actions: [
          if (_isAdmin)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    tooltip: 'مراجعة الإعلانات',
                    icon: const Icon(Icons.fact_check_outlined),
                    onPressed: () async {
                      await context.push('/jobs/review');
                      _checkAdmin();
                      _reload();
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
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/jobs/mine'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final added = await context.push('/jobs/new');
          if (added == true) _reload();
        },
        icon: const Icon(Icons.add),
        label: const Text('أضف إعلاناً'),
      ),
      body: Column(
        children: [
          _FilterBar(
            city: _city,
            workType: _workType,
            onCity: (v) {
              setState(() => _city = v);
              _reload();
            },
            onWorkType: (v) {
              setState(() => _workType = v);
              _reload();
            },
          ),
          Expanded(
            child: FutureBuilder<List<JobPost>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return _Empty(
                    icon: Icons.wifi_off_rounded,
                    title: 'تعذّر تحميل الإعلانات',
                    body: 'تأكّد من الاتصال بالإنترنت ثم أعد المحاولة.',
                    onRetry: _reload,
                  );
                }
                final jobs = snap.data ?? const <JobPost>[];
                if (jobs.isEmpty) {
                  return const _Empty(
                    icon: Icons.work_outline_rounded,
                    title: 'لا توجد إعلانات حالياً',
                    body: 'كن أول من ينشر فرصة عمل — اضغط «أضف إعلاناً».',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 96),
                    itemCount: jobs.length,
                    itemBuilder: (_, i) => JobCard(job: jobs[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── شريط الفلاتر ────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final String city;
  final String workType;
  final ValueChanged<String> onCity;
  final ValueChanged<String> onWorkType;
  const _FilterBar({
    required this.city,
    required this.workType,
    required this.onCity,
    required this.onWorkType,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          _Chip(
            label: city.isEmpty ? 'كل المحافظات' : city,
            active: city.isNotEmpty,
            icon: Icons.location_on_outlined,
            onTap: () async {
              final picked = await showModalBottomSheet<String>(
                context: context,
                showDragHandle: true,
                builder: (_) => _CityPicker(selected: city),
              );
              if (picked != null) onCity(picked);
            },
          ),
          const SizedBox(width: 8),
          ...JobPost.workTypeLabels.entries.map((e) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _Chip(
                  label: e.value,
                  active: workType == e.key,
                  onTap: () => onWorkType(workType == e.key ? '' : e.key),
                ),
              )),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final IconData? icon;
  final VoidCallback onTap;
  const _Chip(
      {required this.label,
      required this.active,
      required this.onTap,
      this.icon});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: active
                ? AppColors.primary
                : Theme.of(context).dividerColor.withOpacity(0.5),
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon,
                size: 15,
                color: active
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 5),
          ],
          Text(label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                color: active
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
              )),
        ]),
      ),
    );
  }
}

class _CityPicker extends StatelessWidget {
  final String selected;
  const _CityPicker({required this.selected});

  @override
  Widget build(BuildContext context) {
    final cities = ['', ...JobsService.iraqCities];
    return ListView.builder(
      shrinkWrap: true,
      itemCount: cities.length,
      itemBuilder: (_, i) {
        final c = cities[i];
        return ListTile(
          title: Text(c.isEmpty ? 'كل المحافظات' : c),
          trailing: selected == c
              ? const Icon(Icons.check, color: AppColors.primary)
              : null,
          onTap: () => Navigator.pop(context, c),
        );
      },
    );
  }
}

// ─── بطاقة الإعلان ───────────────────────────────────────────────────────────

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
    final theme = Theme.of(context);
    final negotiable = job.salaryNegotiable || job.salaryMin == null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // الترويسة الملوّنة
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.10),
                AppColors.primary.withOpacity(0.02),
              ],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
            ),
          ),
          child: Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.local_pharmacy_outlined,
                  color: AppColors.primary, size: 22),
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
                          fontSize: 15.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Row(children: [
                    Icon(Icons.location_on_outlined,
                        size: 13, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(job.locationAr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12.5,
                              color: theme.colorScheme.onSurfaceVariant)),
                    ),
                  ]),
                ],
              ),
            ),
            if (showStatus) _StatusPill(status: job.status),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
          child: Wrap(spacing: 6, runSpacing: 6, children: [
            _Tag(job.jobTitle, Icons.badge_outlined),
            _Tag(job.workTypeAr, Icons.schedule_outlined),
            if (job.shiftText.isNotEmpty)
              _Tag(job.shiftText, Icons.sunny_snowing),
            if (job.genderPref != 'any')
              _Tag(JobPost.genderLabels[job.genderPref] ?? '',
                  Icons.person_outline),
          ]),
        ),

        // الراتب
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: negotiable
                  ? AppColors.warningAmber.withOpacity(0.10)
                  : AppColors.successGreen.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              Icon(
                  negotiable
                      ? Icons.handshake_outlined
                      : Icons.payments_outlined,
                  size: 18,
                  color: negotiable
                      ? AppColors.warningAmber
                      : AppColors.successGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(job.salaryAr,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: negotiable
                          ? AppColors.warningAmber
                          : AppColors.successGreen,
                    )),
              ),
            ]),
          ),
        ),

        if (job.hoursText.isNotEmpty || job.daysText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: Row(children: [
              Icon(Icons.access_time,
                  size: 14, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  [job.hoursText, job.daysText]
                      .where((e) => e.isNotEmpty)
                      .join(' · '),
                  style: TextStyle(
                      fontSize: 12.5,
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ]),
          ),

        if (job.description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: Text(job.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, height: 1.5)),
          ),

        const SizedBox(height: 12),
        Divider(height: 1, color: theme.dividerColor.withOpacity(0.3)),

        Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
          child: Row(children: [
            Text(job.agoAr,
                style: TextStyle(
                    fontSize: 11.5, color: theme.colorScheme.onSurfaceVariant)),
            const Spacer(),
            if (job.contactWhatsapp.isNotEmpty)
              TextButton.icon(
                onPressed: () => _whatsapp(job.contactWhatsapp),
                icon: const Icon(Icons.chat_outlined, size: 17),
                label: const Text('واتساب', style: TextStyle(fontSize: 13)),
              ),
            TextButton.icon(
              onPressed: () {
                JobsService.instance.bumpView(job.id);
                _dial(job.contactPhone);
              },
              icon: const Icon(Icons.phone_outlined, size: 17),
              label: const Text('اتصال', style: TextStyle(fontSize: 13)),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final IconData icon;
  const _Tag(this.text, this.icon);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).dividerColor.withOpacity(0.18),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 11.5)),
        ]),
      );
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
  const _Empty(
      {required this.icon,
      required this.title,
      required this.body,
      this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 56, color: Theme.of(context).dividerColor),
            const SizedBox(height: 14),
            Text(title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(body,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            if (onRetry != null) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
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

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/job_post.dart';
import '../../services/admin_access_service.dart';
import '../../services/jobs_service.dart';
import 'jobs_screen.dart' show JobCard;

/// إدارة إعلانات العمل من داخل التطبيق — للمدراء فقط.
///
/// ثلاثة أقسام معزولة:
///   • طلبات جديدة: بانتظار الموافقة → نشر / رفض / حذف
///   • منشورة: ظاهرة للمستخدمين → إخفاء / حذف
///   • أخرى: مرفوضة أو مخفيّة أو منتهية → إعادة نشر / حذف
///
/// الحماية مزدوجة: الشاشة تتحقّق من الصلاحية قبل العرض، وقاعدة البيانات
/// ترفض أي تعديل من غير المدراء عبر RLS.
class JobsAdminScreen extends StatefulWidget {
  const JobsAdminScreen({super.key});

  @override
  State<JobsAdminScreen> createState() => _JobsAdminScreenState();
}

class _JobsAdminScreenState extends State<JobsAdminScreen> {
  bool? _allowed;
  late Future<List<JobPost>> _future = JobsService.instance.listAllForAdmin();
  final _busy = <int>{};

  @override
  void initState() {
    super.initState();
    AdminAccessService.instance.hasAccess().then((v) {
      if (mounted) setState(() => _allowed = v);
    });
  }

  void _reload() {
    setState(() => _future = JobsService.instance.listAllForAdmin());
  }

  /// ينفّذ عملية على إعلان مع مؤشّر انشغال ورسالة نجاح أو خطأ.
  Future<void> _run(JobPost j, Future<void> Function() op, String done) async {
    setState(() => _busy.add(j.id));
    try {
      await op();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.successGreen,
        content: Text('$done: ${j.pharmacyName}'),
      ));
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.errorRed,
        content: Text('تعذّر التنفيذ: $e'),
      ));
    } finally {
      if (mounted) setState(() => _busy.remove(j.id));
    }
  }

  Future<void> _approve(JobPost j) =>
      _run(j, () => JobsService.instance.approve(j.id), 'نُشر الإعلان');

  Future<void> _hide(JobPost j) async {
    final ok = await _confirm(
      title: 'إخفاء الإعلان؟',
      body: 'يختفي إعلان «${j.pharmacyName}» من المستخدمين ويبقى محفوظاً '
          'في قسم «أخرى»، ويمكن إعادة نشره متى شئت.',
      action: 'إخفاء',
    );
    if (ok) await _run(j, () => JobsService.instance.hide(j.id), 'أُخفي الإعلان');
  }

  Future<void> _delete(JobPost j) async {
    final ok = await _confirm(
      title: 'حذف نهائي؟',
      body: 'يُحذف إعلان «${j.pharmacyName}» نهائياً ولا يمكن استرجاعه. '
          'إن أردت إزالته مؤقتاً فاستعمل «إخفاء».',
      action: 'حذف نهائي',
      danger: true,
    );
    if (ok) {
      await _run(j, () => JobsService.instance.deletePermanently(j.id),
          'حُذف الإعلان');
    }
  }

  Future<void> _reject(JobPost j) async {
    final ctrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('سبب الرفض'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'يظهر لصاحب الإعلان ليصحّحه',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('رفض'),
          ),
        ],
      ),
    );
    if (reason == null) return;
    await _run(
        j, () => JobsService.instance.reject(j.id, reason), 'رُفض الإعلان');
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    required String action,
    bool danger = false,
  }) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body, style: const TextStyle(height: 1.6)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor:
                    danger ? AppColors.errorRed : AppColors.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return r == true;
  }

  @override
  Widget build(BuildContext context) {
    if (_allowed == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_allowed == false) {
      return Scaffold(
        appBar: AppBar(title: const Text('إدارة إعلانات العمل')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.lock_outline, size: 54, color: Colors.grey),
              SizedBox(height: 12),
              Text('هذا القسم للإدارة فقط',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ]),
          ),
        ),
      );
    }

    return FutureBuilder<List<JobPost>>(
      future: _future,
      builder: (context, snap) {
        final all = snap.data ?? const <JobPost>[];
        final pending = all.where((j) => j.status == 'pending').toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        final live = all.where((j) => j.status == 'approved').toList();
        final other = all
            .where((j) => j.status != 'pending' && j.status != 'approved')
            .toList();

        Widget body(List<JobPost> jobs, _Section sec) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _Empty(
              icon: Icons.cloud_off_outlined,
              text: 'تعذّر التحميل. تحقّق من الاتصال ثم حدّث',
              onRetry: _reload,
            );
          }
          if (jobs.isEmpty) {
            return _Empty(
              icon: Icons.inbox_outlined,
              text: switch (sec) {
                _Section.pending => 'لا توجد طلبات نشر جديدة',
                _Section.live => 'لا توجد إعلانات منشورة',
                _Section.other => 'لا توجد إعلانات مرفوضة أو مخفيّة',
              },
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
              children: [
                for (final j in jobs) ...[
                  JobCard(job: j, showStatus: true),
                  if (sec == _Section.live &&
                      j.expiresAt != null &&
                      j.expiresAt!.isBefore(DateTime.now()))
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                          'انتهت مدّة هذا الإعلان فلا يراه المستخدمون. '
                          'اضغط «تجديد» ليظهر 30 يوماً أخرى.',
                          style: TextStyle(
                              fontSize: 11.5, color: AppColors.errorRed)),
                    ),
                  if (j.rejectReason.trim().isNotEmpty &&
                      j.status == 'rejected')
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('سبب الرفض: ${j.rejectReason}',
                          style: const TextStyle(fontSize: 11.5)),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18, top: 6),
                    child: _busy.contains(j.id)
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2)),
                            ),
                          )
                        : _Actions(
                            section: sec,
                            expired: j.expiresAt != null &&
                                j.expiresAt!.isBefore(DateTime.now()),
                            onApprove: () => _approve(j),
                            onReject: () => _reject(j),
                            onHide: () => _hide(j),
                            onDelete: () => _delete(j),
                          ),
                  ),
                ],
              ],
            ),
          );
        }

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('إدارة إعلانات العمل'),
              actions: [
                IconButton(
                    tooltip: 'تحديث',
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh)),
              ],
              bottom: TabBar(
                tabs: [
                  Tab(text: 'طلبات جديدة (${pending.length})'),
                  Tab(text: 'منشورة (${live.length})'),
                  Tab(text: 'أخرى (${other.length})'),
                ],
              ),
            ),
            body: TabBarView(children: [
              body(pending, _Section.pending),
              body(live, _Section.live),
              body(other, _Section.other),
            ]),
          ),
        );
      },
    );
  }
}

enum _Section { pending, live, other }

class _Actions extends StatelessWidget {
  final _Section section;
  final bool expired;
  final VoidCallback onApprove, onReject, onHide, onDelete;
  const _Actions({
    required this.section,
    this.expired = false,
    required this.onApprove,
    required this.onReject,
    required this.onHide,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    Widget outlined(String label, IconData icon, VoidCallback onTap,
            {Color? color}) =>
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            icon: Icon(icon, size: 17),
            label: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
          ),
        );
    Widget filled(String label, IconData icon, VoidCallback onTap) => Expanded(
          child: FilledButton.icon(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.successGreen,
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            icon: Icon(icon, size: 17),
            label: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
          ),
        );
    final delete = outlined('حذف', Icons.delete_outline, onDelete,
        color: AppColors.errorRed);
    const gap = SizedBox(width: 8);

    return Row(
      children: switch (section) {
        _Section.pending => [
            delete,
            gap,
            outlined('رفض', Icons.close, onReject, color: AppColors.errorRed),
            gap,
            filled('نشر', Icons.check, onApprove),
          ],
        _Section.live => [
            delete,
            gap,
            outlined('إخفاء', Icons.visibility_off_outlined, onHide),
            if (expired) ...[
              gap,
              filled('تجديد', Icons.replay, onApprove),
            ],
          ],
        _Section.other => [
            delete,
            gap,
            filled('إعادة نشر', Icons.replay, onApprove),
          ],
      },
    );
  }
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onRetry;
  const _Empty({required this.icon, required this.text, this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            Text(text,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('تحديث'),
              ),
            ],
          ]),
        ),
      );
}

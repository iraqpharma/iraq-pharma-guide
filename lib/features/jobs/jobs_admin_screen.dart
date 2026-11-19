import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/job_post.dart';
import '../../services/admin_access_service.dart';
import '../../services/jobs_service.dart';
import 'jobs_screen.dart' show JobCard;

/// مراجعة إعلانات العمل من داخل التطبيق — للمدراء فقط.
///
/// الحماية مزدوجة: الشاشة تتحقّق من الصلاحية قبل العرض،
/// وقاعدة البيانات ترفض أي تعديل من غير المدراء عبر RLS.
class JobsAdminScreen extends StatefulWidget {
  const JobsAdminScreen({super.key});

  @override
  State<JobsAdminScreen> createState() => _JobsAdminScreenState();
}

class _JobsAdminScreenState extends State<JobsAdminScreen> {
  bool? _allowed;
  late Future<List<JobPost>> _future = JobsService.instance.listPending();
  final _busy = <int>{};

  @override
  void initState() {
    super.initState();
    AdminAccessService.instance.hasAccess().then((v) {
      if (mounted) setState(() => _allowed = v);
    });
  }

  void _reload() {
    setState(() => _future = JobsService.instance.listPending());
  }

  Future<void> _approve(JobPost j) async {
    setState(() => _busy.add(j.id));
    try {
      await JobsService.instance.approve(j.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.successGreen,
          content: Text('نُشر إعلان ${j.pharmacyName}'),
        ),
      );
      _reload();
    } catch (e) {
      _error(e);
    } finally {
      if (mounted) setState(() => _busy.remove(j.id));
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
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('رفض'),
          ),
        ],
      ),
    );
    if (reason == null) return;
    setState(() => _busy.add(j.id));
    try {
      await JobsService.instance.reject(j.id, reason);
      _reload();
    } catch (e) {
      _error(e);
    } finally {
      if (mounted) setState(() => _busy.remove(j.id));
    }
  }

  void _error(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: AppColors.errorRed, content: Text('تعذّر التنفيذ: $e')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_allowed == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_allowed == false) {
      return Scaffold(
        appBar: AppBar(title: const Text('مراجعة الإعلانات')),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('مراجعة الإعلانات'),
        actions: [
          IconButton(
              onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<List<JobPost>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('خطأ: ${snap.error}'));
          }
          final jobs = snap.data ?? const <JobPost>[];
          if (jobs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.inbox_outlined, size: 56, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('لا توجد إعلانات بانتظار المراجعة',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ]),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
            children: [
              for (final j in jobs) ...[
                JobCard(job: j, showStatus: true),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16, top: 2),
                  child: _busy.contains(j.id)
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2)),
                          ),
                        )
                      : Row(children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _reject(j),
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.errorRed),
                              icon: const Icon(Icons.close, size: 18),
                              label: const Text('رفض'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _approve(j),
                              style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.successGreen),
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text('نشر'),
                            ),
                          ),
                        ]),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

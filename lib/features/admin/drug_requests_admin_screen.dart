import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../services/app_admin_service.dart';

/// طلبات إضافة الأدوية — ما يقترحه المستخدمون، مع ملاحظاتهم وقرار الإدارة.
class DrugRequestsAdminScreen extends StatefulWidget {
  const DrugRequestsAdminScreen({super.key});

  @override
  State<DrugRequestsAdminScreen> createState() =>
      _DrugRequestsAdminScreenState();
}

class _DrugRequestsAdminScreenState extends State<DrugRequestsAdminScreen> {
  String _filter = 'new';
  late Future<List<DrugRequest>> _future;

  static const _statusColors = <String, Color>{
    'new':       AppColors.warningAmber,
    'reviewing': Color(0xFF3A72B8),
    'added':     AppColors.successGreen,
    'duplicate': Color(0xFF6E7B88),
    'rejected':  AppColors.errorRed,
  };

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = AppAdminService.instance
          .drugRequests(status: _filter.isEmpty ? null : _filter);
    });
  }

  Future<void> _setStatus(DrugRequest r, String status) async {
    try {
      await AppAdminService.instance.setRequestStatus(r.id, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('«${r.drugName}» → ${DrugRequest.statusLabels[status]}'),
        behavior: SnackBarBehavior.floating,
      ));
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('تعذّر التحديث: $e'),
        backgroundColor: AppColors.errorRed,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('طلبات إضافة الأدوية',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5)),
      ),
      body: Column(children: [
        // ── فلتر الحالة ────────────────────────────────────────────────
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 7, 12, 8),
            children: [
              _pill('الكل', ''),
              for (final e in DrugRequest.statusLabels.entries)
                _pill(e.value, e.key),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<DrugRequest>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Text('تعذّر التحميل، تأكّد أن حسابك مدرج '
                        'في database_admins\n\n${snap.error}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12.5,
                            color: theme.colorScheme.onSurfaceVariant)),
                  ),
                );
              }
              final list = snap.data ?? const <DrugRequest>[];
              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_rounded,
                          size: 48, color: theme.dividerColor),
                      const SizedBox(height: 10),
                      Text('لا طلبات بهذه الحالة',
                          style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => _reload(),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _card(list[i]),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _pill(String label, String value) {
    final active = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(left: 7),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          setState(() => _filter = value);
          _reload();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
                color: active
                    ? AppColors.primary
                    : Theme.of(context).dividerColor.withOpacity(0.5)),
          ),
          child: Text(label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: active ? FontWeight.bold : FontWeight.w600,
                color: active
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
              )),
        ),
      ),
    );
  }

  Widget _card(DrugRequest r) {
    final cs     = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color  = _statusColors[r.status] ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 6),
      decoration: BoxDecoration(
        color: isDark ? cs.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.07)
                : const Color(0xFFECEFF2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(r.drugName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(r.statusAr,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Icon(Icons.category_outlined, size: 13, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(r.category,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          const Spacer(),
          Text(
              '${r.createdAt.year}/${r.createdAt.month}/${r.createdAt.day}',
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        ]),
        if (r.notes.isNotEmpty) ...[
          const SizedBox(height: 9),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(isDark ? 0.12 : 0.05),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(r.notes,
                style: const TextStyle(fontSize: 12.5, height: 1.5)),
          ),
        ],
        const SizedBox(height: 4),
        Row(children: [
          _act('أُضيف', Icons.check_rounded, AppColors.successGreen,
              () => _setStatus(r, 'added')),
          _act('موجود', Icons.copy_rounded, const Color(0xFF6E7B88),
              () => _setStatus(r, 'duplicate')),
          _act('مراجعة', Icons.schedule_rounded, const Color(0xFF3A72B8),
              () => _setStatus(r, 'reviewing')),
          const Spacer(),
          _act('رفض', Icons.close_rounded, AppColors.errorRed,
              () => _setStatus(r, 'rejected')),
        ]),
      ]),
    );
  }

  Widget _act(String label, IconData icon, Color color, VoidCallback onTap) =>
      InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ]),
        ),
      );
}

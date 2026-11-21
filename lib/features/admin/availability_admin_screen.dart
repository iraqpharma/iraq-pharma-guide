import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/governorate_style.dart';
import '../../data/models/availability_post.dart';
import '../../services/availability_service.dart';

/// مراجعة إعلانات توفّر الأدوية قبل ظهورها للمستخدمين.
class AvailabilityAdminScreen extends StatefulWidget {
  const AvailabilityAdminScreen({super.key});

  @override
  State<AvailabilityAdminScreen> createState() =>
      _AvailabilityAdminScreenState();
}

class _AvailabilityAdminScreenState extends State<AvailabilityAdminScreen> {
  late Future<List<AvailabilityPost>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() => _future = AvailabilityService.instance.listPending());
  }

  Future<void> _approve(AvailabilityPost p) async {
    await AvailabilityService.instance.approve(p.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('نُشر إعلان «${p.drugName}»'),
      backgroundColor: AppColors.successGreen,
      behavior: SnackBarBehavior.floating,
    ));
    _reload();
  }

  Future<void> _reject(AvailabilityPost p) async {
    final ctrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('سبب الرفض'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: 'يظهر لصاحب الإعلان ليُصلحه',
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
    await AvailabilityService.instance.reject(p.id, reason);
    if (!mounted) return;
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('مراجعة إعلانات التوفّر',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5)),
      ),
      body: FutureBuilder<List<AvailabilityPost>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Text('تعذّر التحميل\n\n${snap.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12.5,
                        color: theme.colorScheme.onSurfaceVariant)),
              ),
            );
          }
          final list = snap.data ?? const <AvailabilityPost>[];
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified_rounded,
                      size: 52, color: AppColors.successGreen),
                  const SizedBox(height: 12),
                  const Text('لا إعلانات تنتظر المراجعة',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text('كل إعلانات التوفّر مُراجَعة',
                      style: TextStyle(
                          fontSize: 12.5,
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
              itemCount: list.length,
              itemBuilder: (_, i) => _card(list[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _card(AvailabilityPost p) {
    final cs     = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gov    = GovStyle.of(p.city);

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
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
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: gov.color.withOpacity(0.13),
            ),
            child: Icon(gov.icon, color: gov.color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.titleLine,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('${p.pharmacyName} · ${p.locationAr}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: gov.color)),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 9),
        Wrap(spacing: 6, runSpacing: 6, children: [
          if (p.formLine.isNotEmpty) _tag(p.formLine, Icons.medication_outlined),
          _tag(p.priceAr, Icons.payments_outlined),
          _tag(p.contactPhone, Icons.phone_outlined),
          if (p.contactWhatsapp.isNotEmpty)
            _tag(p.contactWhatsapp, Icons.chat_outlined),
        ]),
        if (p.notes.isNotEmpty) ...[
          const SizedBox(height: 9),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(isDark ? 0.12 : 0.05),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(p.notes,
                style: const TextStyle(fontSize: 12.5, height: 1.5)),
          ),
        ],
        const SizedBox(height: 2),
        Row(children: [
          Text(p.agoAr,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          const Spacer(),
          TextButton.icon(
            onPressed: () => _reject(p),
            icon: const Icon(Icons.close_rounded, size: 17),
            label: const Text('رفض', style: TextStyle(fontSize: 13)),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
          ),
          const SizedBox(width: 4),
          FilledButton.icon(
            onPressed: () => _approve(p),
            icon: const Icon(Icons.check_rounded, size: 17),
            label: const Text('نشر', style: TextStyle(fontSize: 13)),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.successGreen,
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _tag(String text, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.10)
                : const Color(0xFFE7EBEF)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon,
            size: 12.5, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(text,
            style: const TextStyle(
                fontSize: 11.5, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

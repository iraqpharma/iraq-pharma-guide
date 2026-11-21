import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../services/app_admin_service.dart';

/// مراجعة دليل الأسعار.
///
/// الدليل يُغذّى من مدخلات كثيرة، فتسرّبت إليه أسماء عبثية مثل
/// «tytytyty» ومستلزمات ليست أدوية مثل الكانولا والسرنجة. هذه الصفوف
/// أُخفيت ولم تُحذف، كي يراها صاحب التطبيق ويقرّر: حذف نهائي أو إعادة
/// إظهار إن كان الإخفاء خطأ.
class PricingReviewScreen extends StatefulWidget {
  const PricingReviewScreen({super.key});

  @override
  State<PricingReviewScreen> createState() => _PricingReviewScreenState();
}

class _PricingReviewScreenState extends State<PricingReviewScreen> {
  List<Map<String, dynamic>>? _rows;
  String? _error;
  final _busy = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _rows = null;
      _error = null;
    });
    try {
      final r = await AppAdminService.instance.hiddenPricing();
      if (mounted) setState(() => _rows = r);
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذّر التحميل. تحقّق من الاتصال');
    }
  }

  Future<void> _restore(Map<String, dynamic> row) async {
    final id = '${row['id']}';
    setState(() => _busy.add(id));
    try {
      await AppAdminService.instance.setPricingHidden(row['id'], false);
      if (mounted) {
        setState(() {
          _rows?.removeWhere((e) => '${e['id']}' == id);
          _busy.remove(id);
        });
      }
    } catch (_) {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  Future<void> _delete(Map<String, dynamic> row) async {
    final name = '${row['trade_name'] ?? ''}';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('حذف نهائي', style: TextStyle(fontSize: 16)),
        content: Text(
            'سيُحذف «$name» من دليل الأسعار نهائياً، ولا يمكن التراجع',
            style: const TextStyle(fontSize: 13.5, height: 1.7)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorRed,
                foregroundColor: Colors.white),
            child: const Text('احذف'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final id = '${row['id']}';
    setState(() => _busy.add(id));
    try {
      await AppAdminService.instance.deletePricing(row['id']);
      if (mounted) {
        setState(() {
          _rows?.removeWhere((e) => '${e['id']}' == id);
          _busy.remove(id);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busy.remove(id));
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تعذّر الحذف')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final rows   = _rows;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('مراجعة دليل الأسعار',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [
          IconButton(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 21)),
        ],
      ),
      body: _error != null
          ? Center(
              child: Text(_error!,
                  style: TextStyle(
                      fontSize: 13.5,
                      color: theme.colorScheme.onSurfaceVariant)))
          : rows == null
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : rows.isEmpty
                  ? _clean(theme)
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                AppColors.warningAmber.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                                color: AppColors.warningAmber
                                    .withOpacity(0.22)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.visibility_off_outlined,
                                size: 17, color: AppColors.warningAmber),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                  '${rows.length} صفاً مخفيّاً عن المستخدمين '
                                  'بانتظار قرارك. الإخفاء لا يحذف شيئاً',
                                  style: TextStyle(
                                      fontSize: 12,
                                      height: 1.6,
                                      color: theme.colorScheme.onSurface)),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 12),
                        for (final r in rows) _card(r, isDark, theme),
                      ],
                    ),
    );
  }

  Widget _clean(ThemeData theme) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.successGreen.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_outlined,
                  size: 40, color: AppColors.successGreen),
            ),
            const SizedBox(height: 16),
            const Text('الدليل نظيف',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('لا صفوف مخفيّة بانتظار المراجعة',
                style: TextStyle(
                    fontSize: 12.5,
                    color: theme.colorScheme.onSurfaceVariant)),
          ]),
        ),
      );

  Widget _card(Map<String, dynamic> r, bool isDark, ThemeData theme) {
    final id     = '${r['id']}';
    final busy   = _busy.contains(id);
    final name   = '${r['trade_name'] ?? ''}';
    final reason = '${r['hidden_reason'] ?? ''}';
    final price  = r['price'] ?? r['public_price'] ?? r['selling_price'];
    final auto   = AppAdminService.validateProductName(name);

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.07)
                : const Color(0xFFECEFF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(name.isEmpty ? 'بلا اسم' : name,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold)),
            ),
            if (price != null)
              Text('$price',
                  style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant)),
          ]),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: [
            if (reason.isNotEmpty) _tag(reason, AppColors.warningAmber),
            if (auto != null) _tag(auto, AppColors.errorRed),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: busy ? null : () => _restore(r),
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: const Text('أعِد إظهاره',
                    style: TextStyle(fontSize: 12.5)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.successGreen,
                  side: BorderSide(
                      color: AppColors.successGreen.withOpacity(0.4)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11)),
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: busy ? null : () => _delete(r),
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: const Text('احذف نهائياً',
                    style: TextStyle(fontSize: 12.5)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.errorRed,
                  side:
                      BorderSide(color: AppColors.errorRed.withOpacity(0.4)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11)),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _tag(String t, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: c.withOpacity(0.11),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(t,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: c)),
      );
}

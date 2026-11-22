import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_strings.dart';

/// إبلاغ عن إعلان نشره مستخدم (وظيفة أو توفّر دواء).
///
/// المحتوى الذي ينشره المستخدمون يحتاج طريقاً للتبليغ عنه حتى مع
/// المراجعة المسبقة: الإعلان قد يصير مخالفاً بعد نشره (وظيفة أُغلقت،
/// رقم خاطئ، احتيال). البلاغ يصل للإدارة في جدول `listing_reports`.
class ReportListing {
  ReportListing._();

  static const _reasons = <(String, String, String)>[
    ('fraud', 'إعلان وهمي أو احتيال', 'Fake or fraudulent listing'),
    ('wrong_info', 'معلومات خاطئة أو رقم لا يعمل', 'Wrong information or dead number'),
    ('inappropriate', 'محتوى غير لائق أو مخالف', 'Inappropriate or objectionable content'),
    ('expired', 'الإعلان انتهى ولم يُغلق', 'No longer available'),
    ('other', 'سبب آخر', 'Other'),
  ];

  /// [kind]: `job` أو `availability`.
  static Future<void> show(BuildContext context,
      {required String kind, required int id}) async {
    final ar = context.s.isAr;
    final messenger = ScaffoldMessenger.of(context);
    final db = Supabase.instance.client;
    if (db.auth.currentUser == null) {
      messenger.showSnackBar(SnackBar(
          content: Text(ar
              ? 'سجّل الدخول لتتمكّن من الإبلاغ'
              : 'Sign in to report a listing')));
      return;
    }
    final reason = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(ar ? 'لماذا تبلّغ عن هذا الإعلان؟' : 'Why are you reporting this listing?',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
          for (final r in _reasons)
            ListTile(
              dense: true,
              leading: const Icon(Icons.flag_outlined,
                  size: 20, color: AppColors.errorRed),
              title: Text(ar ? r.$2 : r.$3),
              onTap: () => Navigator.pop(ctx, r.$1),
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (reason == null) return;
    try {
      await db.from('listing_reports').insert({
        'kind': kind,
        'listing_id': id,
        'reason': reason,
      });
      messenger.showSnackBar(SnackBar(
          backgroundColor: AppColors.successGreen,
          content: Text(ar
              ? 'وصل بلاغك. ستراجعه الإدارة'
              : 'Report received. The admins will review it')));
    } catch (_) {
      messenger.showSnackBar(SnackBar(
          backgroundColor: AppColors.errorRed,
          content: Text(ar
              ? 'تعذّر إرسال البلاغ. تحقّق من الاتصال'
              : 'Could not send the report. Check your connection')));
    }
  }
}

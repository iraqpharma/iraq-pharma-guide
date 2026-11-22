import '../../shared/widgets/t_text.dart';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_strings.dart';
import '../../data/database/database_helper.dart';
import '../../services/barcode_service.dart';
import 'barcode_scanner_screen.dart';
import '../../services/haptics_service.dart';

/// فتح القارئ وتحويل الرقم إلى اسم دواء.
///
/// الرقم المطبوع على العلبة لا يحمل الاسم، فإدخاله في البحث لا يعطي
/// نتيجة. هذا الملف يضع الخطوة الناقصة: يقرأ الرقم، يسأل قاعدة الربط عن
/// اسمه، وإن كان مجهولاً يطلب من الصيدلاني إسناده مرّة واحدة فيُعرَّف
/// للجميع بعدها.
class BarcodeResolver {
  BarcodeResolver._();

  /// يشرح سبب الكاميرا مرّة واحدة ثم يفتح القارئ ويرجع الرقم.
  ///
  /// إذن الكاميرا يطلبه القارئ نفسه (mobile_scanner) عند تشغيله لا
  /// permission_handler: على iOS يرجع الأخير «مرفوض نهائياً» دون أن يسأل
  /// النظام أصلاً ما لم يُفعَّل ماكرو PERMISSION_CAMERA في Podfile، فكانت
  /// الكاميرا لا تفتح ولا يظهر مفتاحها في إعدادات الجهاز. وإن رُفض الإذن
  /// فعلاً تعرض شاشة القارئ السبب وزر فتح الإعدادات.
  static Future<String?> scan(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    var explained = prefs.getBool(_kCameraExplained) ?? false;
    if (!explained && Platform.isAndroid) {
      // على أندرويد الحالة موثوقة: من منح الإذن سابقاً لا يحتاج الشرح.
      try {
        explained = await Permission.camera.isGranted;
      } catch (_) {/* نكمل بالشرح */}
    }
    if (!explained) {
      if (!context.mounted) return null;
      final allow = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const CameraPermissionDialog(),
      );
      if (allow != true) return null;
      await prefs.setBool(_kCameraExplained, true);
    }
    if (!context.mounted) return null;
    return Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
  }

  static const _kCameraExplained = 'camera_rationale_seen';

  /// يقرأ ثم يحوّل إلى اسم. يرجع null إن أُلغي أو لم يُسنَد.
  static Future<String?> scanAndResolve(BuildContext context) async {
    final code = await scan(context);
    if (code == null || code.trim().isEmpty) return null;
    if (!context.mounted) return null;
    return resolve(context, code);
  }

  /// يحوّل رقماً جاهزاً إلى اسم دواء.
  static Future<String?> resolve(BuildContext context, String code) async {
    final norm = BarcodeService.normalize(code);
    final hit = await BarcodeService.instance.lookup(norm);
    if (hit != null) {
      // رقم معروف: نزيد وزنه ونرجع اسمه
      Haptics.success();
      BarcodeService.instance.confirm(norm);
      return hit.name;
    }
    Haptics.warn();
    // المدير يربط مباشرة، والمستخدم العادي يقترح فقط
    final admin = await BarcodeService.instance.isAdmin();
    if (!context.mounted) return null;
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LinkBarcodeSheet(barcode: norm, isAdmin: admin),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// إسناد رقم مجهول إلى دواء
// ════════════════════════════════════════════════════════════════════════

class _LinkBarcodeSheet extends StatefulWidget {
  final String barcode;
  final bool isAdmin;
  const _LinkBarcodeSheet(
      {required this.barcode, required this.isAdmin});

  @override
  State<_LinkBarcodeSheet> createState() => _LinkBarcodeSheetState();
}

class _LinkBarcodeSheetState extends State<_LinkBarcodeSheet> {
  final _name     = TextEditingController();
  final _strength = TextEditingController();
  final _form     = TextEditingController();

  List<String> _hints = [];
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _strength.dispose();
    _form.dispose();
    super.dispose();
  }

  Future<void> _suggest(String q) async {
    if (q.trim().length < 2) {
      if (_hints.isNotEmpty) setState(() => _hints = []);
      return;
    }
    final r = await DatabaseHelper.instance.searchNames(q, limit: 7);
    if (mounted) setState(() => _hints = r);
  }

  Future<void> _save() async {
    final n = _name.text.trim();
    if (n.length < 2) return;
    setState(() => _busy = true);

    final svc = BarcodeService.instance;
    final ok = widget.isAdmin
        ? await svc.submit(
            barcode: widget.barcode,
            name: n,
            form: _form.text.trim(),
            strength: _strength.text.trim(),
          )
        : await svc.suggest(
            barcode: widget.barcode,
            name: n,
            form: _form.text.trim(),
            strength: _strength.text.trim(),
          );

    if (!mounted) return;
    setState(() => _busy = false);

    if (!ok) {
      Haptics.error();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: TText((context.s.isAr ? 'تعذّر الإرسال. تحقّق من الاتصال وحاول مرّة أخرى' : 'Could not send. Check your connection and try again')),
      ));
      return;
    }

    Haptics.success();
    if (widget.isAdmin) {
      // المدير ربطه فوراً، فنُكمل البحث بالاسم
      Navigator.of(context).pop(n);
    } else {
      // الاقتراح لا يُعتمد قبل المراجعة، فلا نُظهر الاسم كأنه مؤكّد
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: TText((context.s.isAr ? 'وصل اقتراحك. سيُراجَع قبل اعتماده للجميع' : 'Suggestion received. It will be reviewed before it goes live')),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surface : Colors.white,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant
                        .withOpacity(0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.qr_code_2_rounded,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TText((context.s.isAr ? 'رقم غير معروف' : 'Unknown barcode'),
                          style: TextStyle(
                              fontSize: 14.5, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      TText(widget.barcode,
                          style: TextStyle(
                              fontSize: 12,
                              letterSpacing: 0.5,
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(isDark ? 0.14 : 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TText(
                    widget.isAdmin
                        ? 'الباركود رقم تسلسلي لا يحمل اسم الدواء. اربطه '
                            'بالدواء الصحيح فيصبح معروفاً لكل مستخدمي '
                            'التطبيق فوراً'
                        : 'الباركود رقم تسلسلي لا يحمل اسم الدواء. اكتب '
                            'اسم الدواء الذي على العلبة ليصل اقتراحك '
                            'للمراجعة، ولا يُعتمد قبل التأكّد منه',
                    style: TextStyle(
                        fontSize: 11.5,
                        height: 1.8,
                        color: theme.colorScheme.onSurface)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _name,
                autofocus: true,
                onChanged: _suggest,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  labelText: (context.s.isAr ? 'اسم الدواء بالإنكليزية' : 'Drug name in English'),
                  labelStyle: const TextStyle(fontSize: 12.5),
                  hintText: (context.s.isAr ? 'اكتب حرفين ليظهر الاقتراح' : 'Type two letters for suggestions'),
                  hintStyle: const TextStyle(fontSize: 12),
                  isDense: true,
                  prefixIcon: const Icon(Icons.medication_outlined, size: 19),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              if (_hints.isNotEmpty) ...[
                const SizedBox(height: 9),
                Wrap(spacing: 7, runSpacing: 7, children: [
                  for (final h in _hints)
                    InkWell(
                      onTap: () {
                        _name.text = h;
                        _name.selection =
                            TextSelection.collapsed(offset: h.length);
                        setState(() => _hints = []);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 11, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.primary.withOpacity(0.22)),
                        ),
                        child: TText(h,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary)),
                      ),
                    ),
                ]),
              ],
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _strength,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: (context.s.isAr ? 'التركيز' : 'Strength'),
                      labelStyle: const TextStyle(fontSize: 12.5),
                      hintText: '500 mg',
                      hintStyle: const TextStyle(fontSize: 12),
                      isDense: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _form,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: (context.s.isAr ? 'الشكل' : 'Form'),
                      labelStyle: const TextStyle(fontSize: 12.5),
                      hintText: 'Tablet',
                      hintStyle: const TextStyle(fontSize: 12),
                      isDense: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: TText(context.s.cancel,
                        style: const TextStyle(fontSize: 13.5)),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _busy ? null : _save,
                    icon: _busy
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Icon(
                            widget.isAdmin
                                ? Icons.link_rounded
                                : Icons.send_rounded,
                            size: 18),
                    label: TText(
                        widget.isAdmin
                            ? (context.s.isAr ? 'اربط الرقم بهذا الدواء' : 'Link barcode to this drug')
                            : (context.s.isAr ? 'أرسل الاقتراح للمراجعة' : 'Send suggestion for review'),
                        style: const TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// شرح سبب طلب الكاميرا قبل ظهور نافذة النظام
// ════════════════════════════════════════════════════════════════════════

class CameraPermissionDialog extends StatelessWidget {
  const CameraPermissionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 30, 24, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.qr_code_scanner_rounded,
                  color: AppColors.primary, size: 42),
            ),
            const SizedBox(height: 18),
            TText(context.s.cameraPermission,
                style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface)),
            const SizedBox(height: 9),
            TText(context.s.cameraPermissionReason,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                    fontSize: 13,
                    height: 1.7,
                    color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: TText(context.s.cancel,
                      style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w600, fontSize: 13.5)),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: TText(context.s.allow_,
                      style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold, fontSize: 13.5)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

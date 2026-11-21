import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ردّ فعل لمسي وصوتي موحّد لكل التطبيق.
///
/// الاهتزاز اللمسي مبني في النظام نفسه (HapticFeedback) ولا يحتاج أي
/// حزمة خارجية ولا ملفات صوت، فلا يزيد حجم التطبيق ولا يُعقّد بناء
/// iOS. والنقرة الصوتية تستعمل صوت النظام القياسي، فهي مألوفة للمستخدم
/// ولا تُزعج من يعمل في صيدلية مزدحمة.
///
/// كل شيء يمرّ من هنا كي يكون الإيقاف من الإعدادات بمفتاح واحد.
class Haptics {
  Haptics._();

  static const _kHaptics = 'fb_haptics_on';
  static const _kSounds  = 'fb_sounds_on';

  static bool _haptics = true;
  static bool _sounds  = true;
  static bool _loaded  = false;

  static bool get hapticsOn => _haptics;
  static bool get soundsOn  => _sounds;

  /// تُنادى مرّة في بدء التطبيق.
  static Future<void> load() async {
    if (_loaded) return;
    try {
      final p = await SharedPreferences.getInstance();
      _haptics = p.getBool(_kHaptics) ?? true;
      _sounds  = p.getBool(_kSounds)  ?? true;
    } catch (_) {
      // قيم افتراضية تكفي
    }
    _loaded = true;
  }

  static Future<void> setHaptics(bool on) async {
    _haptics = on;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_kHaptics, on);
    } catch (_) {}
  }

  static Future<void> setSounds(bool on) async {
    _sounds = on;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_kSounds, on);
    } catch (_) {}
  }

  // ── اللبنات ───────────────────────────────────────────────────────

  static void _buzz(void Function() f) {
    if (!_haptics) return;
    try {
      f();
    } catch (_) {
      // بعض الأجهزة بلا محرّك اهتزاز
    }
  }

  static void _click([SystemSoundType t = SystemSoundType.click]) {
    if (!_sounds) return;
    try {
      SystemSound.play(t);
    } catch (_) {}
  }

  // ── الاستعمالات ───────────────────────────────────────────────────

  /// ضغطة زرّ عادية، فتح بطاقة، تبديل تبويب.
  static void tap() => _buzz(HapticFeedback.lightImpact);

  /// تغيير اختيار: شريحة فلتر، حالة النقص، عدد المرّات في اليوم.
  static void select() {
    _buzz(HapticFeedback.selectionClick);
    _click();
  }

  /// إجابة صحيحة، نتيجة حاسبة ظهرت، باركود قُرئ بنجاح، إرسال تمّ.
  static void success() {
    _buzz(HapticFeedback.mediumImpact);
    _click();
  }

  /// إجابة خاطئة، باركود مجهول، حقل ناقص.
  static void error() {
    _buzz(HapticFeedback.heavyImpact);
    _click(SystemSoundType.alert);
  }

  /// تنبيه لا خطأ: تداخل شديد، دواء منتهي الصلاحية، زيارة تلقيح فائتة.
  static void warn() {
    _buzz(HapticFeedback.mediumImpact);
    _click(SystemSoundType.alert);
  }

  /// إنجاز: ختام المسابقة، دخول لوحة الصدارة، سلسلة أيام جديدة.
  ///
  /// نبضتان متتاليتان تُميّزه عن النجاح العادي.
  static Future<void> celebrate() async {
    if (!_haptics && !_sounds) return;
    _buzz(HapticFeedback.mediumImpact);
    _click();
    await Future<void>.delayed(const Duration(milliseconds: 110));
    _buzz(HapticFeedback.heavyImpact);
  }

  /// حذف أو إجراء لا رجعة فيه.
  static void heavy() => _buzz(HapticFeedback.heavyImpact);
}

import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  SessionService._();
  static final instance = SessionService._();

  static const _keyRememberMe     = 'session_remember_me';
  static const _keyLoginTimestamp = 'session_login_ts';
  static const _keySavedEmail     = 'session_saved_email';

  // «تذكرني» مُفعّل: نصف سنة، والمهلة متجدّدة (sliding) فكل فتح للتطبيق
  // داخل المهلة يُعيد العدّ من جديد — المستخدم النشِط لا يُخرَج أبداً.
  static const _rememberDays = 180;
  // غير مُفعّل: أسبوعان بدل 48 ساعة. الإخراج كل يومين كان يزعج
  // المستخدمين ويجعلهم يعيدون كتابة كلمة المرور بلا سبب أمني حقيقي،
  // ورمز التحديث في سوبابيس يتجدّد تلقائياً.
  static const _sessionDays = 14;

  /// Called right after successful login/OTP verification.
  Future<void> onLoginSuccess({
    required bool rememberMe,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRememberMe, rememberMe);
    await prefs.setInt(_keyLoginTimestamp, DateTime.now().millisecondsSinceEpoch);
    if (rememberMe) {
      await prefs.setString(_keySavedEmail, email.trim().toLowerCase());
    } else {
      await prefs.remove(_keySavedEmail);
    }
  }

  /// Returns the auto-filled email if "تذكرني" was checked, otherwise null.
  Future<String?> getSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_keyRememberMe) == true) {
      return prefs.getString(_keySavedEmail);
    }
    return null;
  }

  Future<bool> isRemembered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyRememberMe) ?? false;
  }

  /// True if the stored session is still within its validity window.
  ///
  /// المهلة متجدّدة: إن كانت الجلسة سارية يُحدَّث وقتها، فتُحسب المهلة
  /// من آخر استعمال لا من أوّل دخول.
  Future<bool> isSessionStillValid() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt(_keyLoginTimestamp);
    if (ts == null) return false;
    final elapsed = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(ts));
    final rememberMe = prefs.getBool(_keyRememberMe) ?? false;
    final valid = elapsed.inDays <
        (rememberMe ? _rememberDays : _sessionDays);
    if (valid) {
      await prefs.setInt(
          _keyLoginTimestamp, DateTime.now().millisecondsSinceEpoch);
    }
    return valid;
  }

  /// يُحدِّث وقت آخر استعمال يدوياً (يُستدعى عند فتح التطبيق).
  Future<void> touch() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getInt(_keyLoginTimestamp) == null) return;
    await prefs.setInt(
        _keyLoginTimestamp, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyRememberMe);
    await prefs.remove(_keyLoginTimestamp);
    await prefs.remove(_keySavedEmail);
  }
}

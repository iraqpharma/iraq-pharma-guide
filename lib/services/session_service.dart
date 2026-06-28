import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  SessionService._();
  static final instance = SessionService._();

  static const _keyRememberMe     = 'session_remember_me';
  static const _keyLoginTimestamp = 'session_login_ts';
  static const _keySavedEmail     = 'session_saved_email';

  // Duration when "تذكرني" is checked
  static const _rememberDays = 30;
  // Duration when NOT checked (next cold launch → signed out)
  static const _sessionHours = 48; // 2 days

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
  Future<bool> isSessionStillValid() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt(_keyLoginTimestamp);
    if (ts == null) return false;
    final elapsed = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(ts));
    final rememberMe = prefs.getBool(_keyRememberMe) ?? false;
    return rememberMe
        ? elapsed.inDays < _rememberDays
        : elapsed.inHours < _sessionHours;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyRememberMe);
    await prefs.remove(_keyLoginTimestamp);
    await prefs.remove(_keySavedEmail);
  }
}

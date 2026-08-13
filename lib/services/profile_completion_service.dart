import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Controls the one-time "complete your profile" prompt (governorate,
/// birth date, avatar) shown right after login/signup — mirrors
/// [NotificationPermissionService]'s "ask once" pattern.
class ProfileCompletionService {
  ProfileCompletionService._();
  static final instance = ProfileCompletionService._();

  static const _askedKey = 'profile_completion_asked_v1';

  /// Returns true if the screen should be shown: not asked before on this
  /// device AND the account is still missing governorate/birth date.
  Future<bool> shouldShowScreen() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_askedKey) == true) return false;

    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return false;

    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('address, birth_date')
          .eq('id', uid)
          .maybeSingle();
      if (data == null) return true;
      final address   = (data['address']    as String?)?.trim() ?? '';
      final birthDate = (data['birth_date'] as String?)?.trim() ?? '';
      return address.isEmpty || birthDate.isEmpty;
    } catch (_) {
      // Never block navigation on a network hiccup.
      return false;
    }
  }

  /// Call when the user saves or skips — never show again on this device.
  Future<void> markAsked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_askedKey, true);
  }
}

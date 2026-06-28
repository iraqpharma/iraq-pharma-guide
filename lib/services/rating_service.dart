import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _kLastShownKey = 'rating_last_shown_ms';
const _kRatedKey     = 'rating_completed';
// Show again after 7 days if user dismissed without rating
const _kCooldownDays = 7;
// Minimum rating to redirect to store
const _kStoreThreshold = 4.0;

class RatingConfig {
  final String messageText;
  final String ratingLink;

  const RatingConfig({required this.messageText, required this.ratingLink});
}

class RatingService {
  RatingService._();
  static final RatingService instance = RatingService._();

  final _client = Supabase.instance.client;

  /// Returns [RatingConfig] if the modal should be shown, null otherwise.
  Future<RatingConfig?> shouldShow() async {
    try {
      // 1. Detect platform
      final platform = Platform.isIOS ? 'ios' : 'android';

      // 2. Check remote config for this platform
      final row = await _client
          .from('app_notifications')
          .select('message_text, rating_link, is_active')
          .eq('is_active', true)
          .eq('platform', platform)
          .limit(1)
          .maybeSingle();

      if (row == null) return null;

      // 2. Check local cooldown
      final prefs = await SharedPreferences.getInstance();
      final alreadyRated = prefs.getBool(_kRatedKey) ?? false;
      if (alreadyRated) return null;

      final lastShownMs = prefs.getInt(_kLastShownKey) ?? 0;
      final daysSinceLast = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(lastShownMs))
          .inDays;

      if (lastShownMs != 0 && daysSinceLast < _kCooldownDays) return null;

      return RatingConfig(
        messageText: row['message_text'] as String? ?? '',
        ratingLink:  row['rating_link']  as String? ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  /// Call when modal is shown (starts cooldown timer).
  Future<void> markShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLastShownKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Call when user submits a rating.
  Future<void> submitRating({
    required double rating,
    required bool redirectedToStore,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // If rated >= threshold, mark as permanently done
    if (rating >= _kStoreThreshold) {
      await prefs.setBool(_kRatedKey, true);
    }

    // Save to Supabase for analytics (fire-and-forget)
    try {
      final uid = _client.auth.currentUser?.id;
      await _client.from('user_ratings').insert({
        'user_id':             uid,
        'rating':              rating,
        'redirected_to_store': redirectedToStore,
        'created_at':          DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Analytics failure should never affect UX
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/app_notification.dart';
import '../services/notification_service.dart';

SupabaseClient get _db => Supabase.instance.client;

// ── Current user id, re-emitted on every auth change ─────────────────────────
final authUidProvider = StreamProvider<String?>((ref) async* {
  yield _db.auth.currentUser?.id;
  yield* _db.auth.onAuthStateChange.map((_) => _db.auth.currentUser?.id);
});

// ── Raw notification rows (realtime) ─────────────────────────────────────────
// Public so the notifications screen can invalidate it on pull-to-refresh.
final rawNotificationsProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  return _db
      .from('notifications')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false);
});

// ── Ids this user has already read ───────────────────────────────────────────
final readIdsProvider = StreamProvider<Set<String>>((ref) {
  final uid = ref.watch(authUidProvider).value;
  if (uid == null) return Stream.value(<String>{});
  return _db
      .from('notification_reads')
      .stream(primaryKey: ['notification_id', 'user_id'])
      .eq('user_id', uid)
      .map((rows) =>
          rows.map((r) => r['notification_id'].toString()).toSet());
});

// ── Notifications visible to this user, with per-user read state ─────────────
//
// is_read on the notifications table is a single shared column: whoever opened
// a notification first marked it read for everyone, which is why the unread
// badge was permanently zero. Read state now comes from notification_reads and
// is merged in here, so no screen had to change.
final notificationsProvider =
    Provider<AsyncValue<List<AppNotification>>>((ref) {
  final raw   = ref.watch(rawNotificationsProvider);
  final reads = ref.watch(readIdsProvider).value ?? <String>{};
  final uid   = ref.watch(authUidProvider).value;

  return raw.whenData((rows) => rows
      .where((r) => r['user_id'] == null || r['user_id'] == uid)
      .map((r) => AppNotification.fromJson({
            ...r,
            'is_read': reads.contains(r['id'].toString()),
          }))
      .toList());
});

// ── Unread count (derived) ───────────────────────────────────────────────────
final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).maybeWhen(
        data: (list) =>
            list.where((n) => !n.isRead && !n.isExpired).length,
        orElse: () => 0,
      );
});

// ── Actions ──────────────────────────────────────────────────────────────────
final notificationActionsProvider =
    Provider((ref) => NotificationService.instance);

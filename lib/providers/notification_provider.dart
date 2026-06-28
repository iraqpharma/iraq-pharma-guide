import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/app_notification.dart';
import '../services/notification_service.dart';

// ── Stream of all notifications (realtime) ────────────────────────────────────
final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  return Supabase.instance.client
      .from('notifications')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .map((rows) => rows.map(AppNotification.fromJson).toList());
});

// ── Unread count (derived) ─────────────────────────────────────────────────────
final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).maybeWhen(
        data: (list) => list.where((n) => !n.isRead).length,
        orElse: () => 0,
      );
});

// ── Actions ───────────────────────────────────────────────────────────────────
final notificationActionsProvider = Provider((ref) => NotificationService.instance);

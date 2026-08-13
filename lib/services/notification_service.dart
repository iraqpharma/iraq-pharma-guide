import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles FCM background messages — must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized by the time this is called.
  debugPrint('FCM background: ${message.messageId}');
}

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _fcm = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _channelId   = 'iraq_pharma_high';
  static const _channelName = 'Iraq Pharma Notifications';

  // ── Init ───────────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    try {
      await _setupLocalNotifications();
      await _setupFCM().timeout(const Duration(seconds: 8));
    } catch (e) {
      // Never let notification setup failures block app startup.
      debugPrint('NotificationService init failed (non-fatal): $e');
    }
  }

  // ── Local notifications (foreground display) ───────────────────────────────
  Future<void> _setupLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios     = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _localNotifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // Create high-importance Android channel
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      importance: Importance.high,
      playSound: true,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // ── FCM ────────────────────────────────────────────────────────────────────
  Future<void> _setupFCM() async {
    // 1. Request permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // 2. Background handler (top-level)
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 3. Foreground handler — show local notification
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // 4. Notification tap when app is in background (not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTap);

    // 5. App opened from terminated state via notification
    final initial = await _fcm.getInitialMessage();
    if (initial != null) _onNotificationTap(initial);

    // 6. Persist the token so the server can actually target this device.
    //    Without this, push notifications are silently never sent — the
    //    server-side edge function looks up profiles.fcm_token and has
    //    nothing to send to.
    final token = await _fcm.getToken();
    debugPrint('FCM Token: $token');
    await _saveTokenForCurrentUser(token);

    // 7. Keep the token fresh — FCM tokens rotate periodically.
    _fcm.onTokenRefresh.listen(_saveTokenForCurrentUser);

    // 8. iOS foreground presentation
    if (Platform.isIOS) {
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true, badge: true, sound: true,
      );
    }
  }

  /// Saves the FCM token to the current user's profile row so the
  /// send-push-notification edge function can find it.
  Future<void> _saveTokenForCurrentUser(String? token) async {
    if (token == null) return;
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return; // not logged in yet — will be saved on next call
    try {
      await _db.from('profiles').update({'fcm_token': token}).eq('id', uid);
    } catch (e) {
      debugPrint('Failed to save FCM token: $e');
    }
  }

  /// Public entry point — call this right after notification permission is
  /// granted (user is guaranteed logged-in at that point) and again on every
  /// app start so returning users on an existing install stay registered.
  Future<void> saveTokenForCurrentUser() async {
    final token = await _fcm.getToken();
    await _saveTokenForCurrentUser(token);
  }

  /// Forces a brand-new FCM token instead of reusing whatever is cached
  /// on-device. On iOS the FCM token can survive in the Keychain across
  /// app deletions/reinstalls and go stale (APNs rejects it with
  /// UNREGISTERED) while getToken() keeps happily returning the same dead
  /// value. Call this once when the user explicitly grants notification
  /// permission, so we're guaranteed a token Apple actually recognizes.
  Future<void> refreshAndSaveToken() async {
    try {
      await _fcm.deleteToken();
    } catch (e) {
      debugPrint('deleteToken failed (non-fatal): $e');
    }
    final token = await _fcm.getToken();
    debugPrint('FCM Token (refreshed): $token');
    await _saveTokenForCurrentUser(token);
  }

  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  void _onNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.data}');
    // Add navigation logic here if needed
  }

  // ── Supabase helpers ───────────────────────────────────────────────────────
  static final _db = Supabase.instance.client;

  Future<void> markAsRead(String id) async {
    await _db
        .from('notifications')
        .update({'is_read': true})
        .eq('id', id);
  }

  Future<void> markAllAsRead() async {
    await _db
        .from('notifications')
        .update({'is_read': true})
        .eq('is_read', false);
  }

  /// FCM token — send this to your backend to target this device.
  Future<String?> getToken() => _fcm.getToken();
}

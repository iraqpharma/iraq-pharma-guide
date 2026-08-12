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
    await _setupLocalNotifications();
    await _setupFCM();
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

    // 6. Log token for testing
    final token = await _fcm.getToken();
    debugPrint('FCM Token: $token');

    // 7. iOS foreground presentation
    if (Platform.isIOS) {
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true, badge: true, sound: true,
      );
    }
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

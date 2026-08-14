import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/router/app_router.dart';

/// Handles FCM background messages — must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background: ${message.messageId}');
}

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _fcm = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _channelId   = 'iraq_pharma_high';
  static const _channelName = 'Iraq Pharma Notifications';

  /// Same key used by NotificationPermissionService's in-app toggle.
  static const _pushEnabledKey = 'push_notifications_enabled';

  bool _authListenerAttached = false;
  AppLifecycleListener? _lifecycle;

  // ── Init ───────────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    try {
      await _setupLocalNotifications();
      await _setupFCM();
    } catch (e) {
      // Never let notification setup failures block app startup.
      debugPrint('NotificationService init failed (non-fatal): $e');
    }
  }

  // ── Local notifications (foreground display) ───────────────────────────────
  Future<void> _setupLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    // IMPORTANT: all three must stay false. When they were true, this call
    // fired the real iOS permission dialog during cold start, which meant the
    // dedicated NotificationPermissionScreen was always skipped
    // (shouldShowScreen() saw the permission as already decided) and therefore
    // refreshAndSaveToken() never ran on iOS — that is why iPhones never had
    // an fcm_token row. Permission is now requested only from that screen.
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

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
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTap);

    final initial = await _fcm.getInitialMessage();
    if (initial != null) _onNotificationTap(initial);

    if (Platform.isIOS) {
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true, badge: true, sound: true,
      );
    }

    // Tokens rotate periodically — persist every rotation.
    _fcm.onTokenRefresh.listen((t) async {
      if (await _isPushEnabled()) await _persist(t);
    });

    // The single most important fix: initialize() runs from main() BEFORE the
    // Supabase session is restored and long before login, so currentUser was
    // null and every token save silently bailed out. Re-sync on every auth
    // event instead of only once at startup.
    _attachAuthListener();

    // Coming back to the app is the moment the icon badge is most likely to
    // be stale (a push arrived while it was closed).
    _lifecycle ??= AppLifecycleListener(
      onResume: () => unawaited(syncAppBadge()),
    );

    unawaited(syncToken());
    unawaited(syncAppBadge());
  }

  void _attachAuthListener() {
    if (_authListenerAttached) return;
    _authListenerAttached = true;
    _db.auth.onAuthStateChange.listen((state) {
      switch (state.event) {
        case AuthChangeEvent.initialSession:
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.tokenRefreshed:
        case AuthChangeEvent.userUpdated:
          unawaited(syncToken());
          unawaited(syncAppBadge());
          break;
        default:
          break;
      }
    });
  }

  /// On iOS, getToken() needs the native APNs device token to exist first
  /// (Apple assigns it asynchronously after permission is granted). Calling
  /// getToken() earlier throws [firebase_messaging/apns-token-not-set].
  Future<String?> _getTokenSafely() async {
    if (Platform.isIOS) {
      // Re-issuing the request when permission is already granted shows no
      // dialog, but it is what makes the plugin register the app with APNs.
      final s = await _fcm.getNotificationSettings();
      if (s.authorizationStatus == AuthorizationStatus.authorized ||
          s.authorizationStatus == AuthorizationStatus.provisional) {
        try {
          await _fcm.requestPermission(alert: true, badge: true, sound: true);
        } catch (e) {
          debugPrint('re-request permission failed: $e');
        }
      }

      String? apnsToken = await _fcm.getAPNSToken();
      var attempts = 0;
      while (apnsToken == null && attempts < 20) {
        await Future.delayed(const Duration(milliseconds: 500));
        apnsToken = await _fcm.getAPNSToken();
        attempts++;
      }
      if (apnsToken == null) {
        debugPrint('APNs token never became available after ~10s of waiting');
        return null;
      }
    }
    try {
      return await _fcm.getToken();
    } catch (e) {
      debugPrint('getToken failed: $e');
      return null;
    }
  }

  /// Fetches the current token and stores it, returning whether the row was
  /// actually written. Safe to call as often as you like.
  Future<bool> syncToken() async {
    if (!await _isPushEnabled()) return false;

    final uid = _db.auth.currentUser?.id;
    if (uid == null) return false;

    final settings = await _fcm.getNotificationSettings();
    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
    if (!granted) return false;

    final token = await _getTokenSafely();
    if (token == null) return false;

    return _persist(token);
  }

  /// Writes the token and VERIFIES it landed. The old code ran a bare
  /// update() with no .select(), so a zero-row update looked identical to a
  /// successful one and every failure was invisible.
  Future<bool> _persist(String token) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) {
      debugPrint('FCM token not saved: no signed-in user yet');
      return false;
    }
    try {
      final rows = await _db
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', uid)
          .select('id');
      if (rows.isEmpty) {
        debugPrint('FCM token save affected 0 rows (uid=$uid) — check RLS/row');
        return false;
      }
      debugPrint('FCM token saved (${token.length} chars) for $uid');
      return true;
    } catch (e) {
      debugPrint('Failed to save FCM token: $e');
      return false;
    }
  }

  /// Public entry points kept for the permission screen / profile toggle.
  Future<bool> saveTokenForCurrentUser() => syncToken();

  /// Previously called deleteToken() first. That invalidated the live token
  /// before minting a new one and was in the exact path used by every manual
  /// test. Now it is simply a forced re-sync.
  Future<bool> refreshAndSaveToken() => syncToken();

  Future<void> clearTokenForCurrentUser() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await _db.from('profiles').update({'fcm_token': null}).eq('id', uid);
    } catch (e) {
      debugPrint('Failed to clear FCM token: $e');
    }
  }

  Future<bool> _isPushEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pushEnabledKey) ?? true;
  }

  void _onForegroundMessage(RemoteMessage message) async {
    if (!await _isPushEnabled()) return;
    unawaited(syncAppBadge());
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
    // Opening the notifications screen also marks everything read for this
    // user (see NotificationsScreen.initState).
    try {
      appRouter.push('/notifications');
    } catch (e) {
      debugPrint('Could not route to /notifications: $e');
    }
  }

  // ── Supabase helpers ───────────────────────────────────────────────────────
  static final _db = Supabase.instance.client;

  /// Read state is per-user (notification_reads). The old code updated the
  /// shared notifications.is_read column, which marked the notification read
  /// for every user in the app at once.
  Future<void> markAsRead(String id) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await _db.from('notification_reads').upsert(
        {'notification_id': id, 'user_id': uid},
        onConflict: 'notification_id,user_id',
      );
      await clearDelivered();
      await syncAppBadge();
    } catch (e) {
      debugPrint('markAsRead failed: $e');
    }
  }

  Future<void> markAllAsRead() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final rows = await _db.from('notifications').select('id');
      if (rows.isEmpty) return;
      await _db.from('notification_reads').upsert(
        rows
            .map((r) => {'notification_id': r['id'], 'user_id': uid})
            .toList(),
        onConflict: 'notification_id,user_id',
      );
      await clearDelivered();
      await syncAppBadge();
    } catch (e) {
      debugPrint('markAllAsRead failed: $e');
    }
  }

  /// FCM token — send this to your backend to target this device.
  Future<String?> getToken() => _getTokenSafely();

  /// Removes delivered notifications so the launcher badge / notification
  /// centre entry disappears once the user has read them in-app.
  Future<void> clearDelivered() async {
    try {
      await _localNotifications.cancelAll();
    } catch (e) {
      debugPrint('clearDelivered failed: $e');
    }
  }

  static const _badgeChannel = MethodChannel('iraqpharma/badge');

  /// Recomputes this user's unread count and pushes it onto the app icon.
  /// The push payload sets the badge once at delivery time and never updates
  /// it again, which is why the number survived reading the notification.
  Future<void> syncAppBadge() async {
    if (!Platform.isIOS) return;
    var count = 0;
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid != null) {
        final notifs = await _db
            .from('notifications')
            .select('id')
            .or('user_id.is.null,user_id.eq.$uid');
        final reads = await _db
            .from('notification_reads')
            .select('notification_id')
            .eq('user_id', uid);
        final readIds =
            reads.map((r) => r['notification_id'].toString()).toSet();
        count = notifs
            .where((n) => !readIds.contains(n['id'].toString()))
            .length;
      }
    } catch (e) {
      debugPrint('syncAppBadge count failed: $e');
      return;
    }
    try {
      await _badgeChannel.invokeMethod('setBadge', {'count': count});
    } catch (e) {
      debugPrint('setBadge failed: $e');
    }
  }

  /// Hidden support tool (long-press "الإشعارات" in the profile screen).
  /// Everything needed to explain why a device is not receiving push, without
  /// needing a Mac or a cable.
  Future<Map<String, String>> diagnostics() async {
    final out = <String, String>{};
    out['platform'] = Platform.operatingSystem;

    try {
      final s = await _fcm.getNotificationSettings();
      out['authorization'] = s.authorizationStatus.name;
      out['alert'] = s.alert.name;
    } catch (e) {
      out['authorization'] = 'error: $e';
    }

    out['inAppToggle'] = (await _isPushEnabled()).toString();
    out['userId'] = _db.auth.currentUser?.id ?? 'NOT SIGNED IN';

    if (Platform.isIOS) {
      try {
        final apns = await _fcm.getAPNSToken();
        out['apnsToken'] =
            apns == null ? 'NULL (device never registered with APNs)' : 'ok (${apns.length} chars)';
      } catch (e) {
        out['apnsToken'] = 'error: $e';
      }
    }

    String? token;
    try {
      token = await _fcm.getToken();
      out['fcmToken'] = token == null
          ? 'NULL'
          : '${token.substring(0, token.length < 16 ? token.length : 16)}… (${token.length})';
    } catch (e) {
      out['fcmToken'] = 'error: $e';
    }

    if (token != null) {
      out['savedToDb'] = (await _persist(token)).toString();
    } else {
      out['savedToDb'] = 'skipped (no token)';
    }

    try {
      final uid = _db.auth.currentUser?.id;
      if (uid != null) {
        final row = await _db
            .from('profiles')
            .select('fcm_token')
            .eq('id', uid)
            .maybeSingle();
        final stored = row?['fcm_token'] as String?;
        out['dbToken'] = stored == null
            ? 'NULL'
            : '${stored.substring(0, stored.length < 16 ? stored.length : 16)}… (${stored.length})';
      }
    } catch (e) {
      out['dbToken'] = 'error: $e';
    }

    return out;
  }
}

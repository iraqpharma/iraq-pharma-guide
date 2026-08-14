import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class NotificationPermissionService {
  NotificationPermissionService._();
  static final instance = NotificationPermissionService._();

  static const _askedKey = 'notif_permission_asked';

  /// Returns true if the onboarding screen should be shown.
  ///
  /// When the OS permission is already granted we skip the screen — but we
  /// now make sure the token is persisted on the way out. Previously this
  /// early-return was the reason iPhones ended up with permission granted and
  /// no fcm_token at all.
  Future<bool> shouldShowScreen() async {
    final prefs = await SharedPreferences.getInstance();

    // Android reports authorizationStatus.denied both when the user has never
    // been asked and when they refused, so FirebaseMessaging's settings cannot
    // be used to decide here — doing so skipped the screen forever and
    // POST_NOTIFICATIONS was never requested on Android 13+.
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      if (status.isGranted) {
        await NotificationService.instance.syncToken();
        await prefs.setBool(_askedKey, true);
        return false;
      }
      if (status.isPermanentlyDenied) return false;
      return prefs.getBool(_askedKey) != true;
    }

    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    if (granted) {
      await NotificationService.instance.syncToken();
      await prefs.setBool(_askedKey, true);
      return false;
    }

    if (prefs.getBool(_askedKey) == true) return false;
    return settings.authorizationStatus != AuthorizationStatus.denied;
  }

  /// Request permission. Call when user taps "تفعيل الآن".
  Future<bool> requestPermission() async {
    bool granted = false;

    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      granted = status.isGranted;
    }

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert:         true,
      badge:         true,
      sound:         true,
      announcement:  false,
      carPlay:       false,
      criticalAlert: false,
      provisional:   false,
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      granted = true;
    }

    if (granted) {
      // Deliberately not awaited: fetching the APNs + FCM token can take
      // several seconds, and the user should not sit on a spinner for it.
      unawaited(NotificationService.instance.syncToken());
    }

    await _markAsked();
    return granted;
  }

  Future<void> deny() async => _markAsked();

  Future<void> _markAsked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_askedKey, true);
  }

  // ── In-app on/off toggle (Profile screen) ────────────────────────────────
  static const _enabledKey = 'push_notifications_enabled';

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? true;
  }

  Future<bool> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();

    if (!enabled) {
      await NotificationService.instance.clearTokenForCurrentUser();
      await prefs.setBool(_enabledKey, false);
      return false;
    }

    // Flip the flag first: syncToken() refuses to run while it is false.
    await prefs.setBool(_enabledKey, true);

    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    final alreadyGranted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    bool granted;
    if (alreadyGranted) {
      granted = true;
      unawaited(NotificationService.instance.syncToken());
    } else {
      granted = await requestPermission();
    }

    await prefs.setBool(_enabledKey, granted);
    return granted;
  }
}

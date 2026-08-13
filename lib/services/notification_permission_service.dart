import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class NotificationPermissionService {
  NotificationPermissionService._();
  static final instance = NotificationPermissionService._();

  static const _askedKey = 'notif_permission_asked';

  /// Returns true if the screen should be shown (not yet decided).
  Future<bool> shouldShowScreen() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_askedKey) == true) return false;
    // Also skip if already granted
    final status = await Permission.notification.status;
    return !status.isGranted && !status.isPermanentlyDenied;
  }

  /// Request permission. Call when user taps "تفعيل الآن".
  Future<bool> requestPermission() async {
    bool granted = false;

    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      granted = status.isGranted;
    }

    // iOS & supplementary Firebase request
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

    // Fetch a fresh FCM token and persist it, so the server can actually
    // target this device with push notifications. Force-refresh instead of
    // reusing a possibly stale cached token (see refreshAndSaveToken docs).
    if (granted) {
      await NotificationService.instance.refreshAndSaveToken();
    }

    await _markAsked();
    return granted;
  }

  /// Call when user taps "ليس الآن".
  Future<void> deny() async => _markAsked();

  Future<void> _markAsked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_askedKey, true);
  }

  // ── In-app on/off toggle (Profile screen) ────────────────────────────────
  static const _enabledKey = 'push_notifications_enabled';

  /// Whether the user has push notifications turned on via the in-app
  /// toggle. Defaults to true (matches the onboarding flow default).
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? true;
  }

  /// Turn the in-app toggle on: (re)requests OS permission if needed and
  /// saves a fresh token. Returns the actual resulting state (false if the
  /// OS permission was denied).
  Future<bool> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();

    if (!enabled) {
      await NotificationService.instance.clearTokenForCurrentUser();
      await prefs.setBool(_enabledKey, false);
      return false;
    }

    final status = await Permission.notification.status;
    bool granted = status.isGranted;
    if (!granted) {
      granted = await requestPermission();
    } else {
      await NotificationService.instance.refreshAndSaveToken();
    }

    await prefs.setBool(_enabledKey, granted);
    return granted;
  }
}

import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    // Fetch FCM token if granted
    if (granted) {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        // Token is ready — can be sent to Supabase profiles if needed
        debugPrintToken(token);
      }
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

  void debugPrintToken(String token) {
    // ignore: avoid_print
    print('[FCM Token] $token');
  }
}

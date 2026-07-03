import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

    // حفظ FCM Token في Supabase حتى نتمكن من إرسال إشعارات للجهاز
    if (granted) {
      await _saveFcmToken();
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

  /// حفظ FCM Token في جدول profiles لإرسال الإشعارات لهذا الجهاز
  Future<void> _saveFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      debugPrint('[FCM Token] $token');
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return;
      await Supabase.instance.client
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', uid);
    } catch (e) {
      debugPrint('[FCM] Failed to save token: $e');
    }
  }

  /// حذف FCM Token عند إيقاف الإشعارات
  Future<void> disableNotifications() async {
    try {
      await FirebaseMessaging.instance.deleteToken();
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return;
      await Supabase.instance.client
          .from('profiles')
          .update({'fcm_token': null})
          .eq('id', uid);
    } catch (e) {
      debugPrint('[FCM] Failed to delete token: $e');
    }
  }

  /// إعادة تفعيل الإشعارات
  Future<void> enableNotifications() async => _saveFcmToken();
}

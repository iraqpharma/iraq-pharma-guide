import 'package:flutter/material.dart';

enum NotificationType {
  update, // إشعار تحديث — أخضر
  alert,  // تنبيه طبي   — أحمر
  price,  // تحديث أسعار — أزرق
  promo;  // إعلان        — ذهبي

  static NotificationType fromString(String v) {
    switch (v) {
      case 'alert': return NotificationType.alert;
      case 'price': return NotificationType.price;
      case 'promo': return NotificationType.promo;
      default:      return NotificationType.update;
    }
  }

  String get arabicLabel {
    switch (this) {
      case update: return 'إشعار تحديث';
      case alert:  return 'تنبيه طبي';
      case price:  return 'تحديث أسعار';
      case promo:  return 'إعلان';
    }
  }

  String label(bool isAr) {
    if (isAr) return arabicLabel;
    switch (this) {
      case update: return 'Update Notice';
      case alert:  return 'Medical Alert';
      case price:  return 'Price Update';
      case promo:  return 'Promotion';
    }
  }

  IconData get icon {
    switch (this) {
      case update: return Icons.system_update_alt_rounded;
      case alert:  return Icons.warning_amber_rounded;
      case price:  return Icons.price_change_outlined;
      case promo:  return Icons.campaign_rounded;
    }
  }

  Color get color {
    switch (this) {
      case update: return const Color(0xFF10B981); // أخضر
      case alert:  return const Color(0xFFEF4444); // أحمر
      case price:  return const Color(0xFF3B82F6); // أزرق
      case promo:  return const Color(0xFFF59E0B); // ذهبي
    }
  }

  Color get tint {
    switch (this) {
      case update: return const Color(0xFFF0FFF4);
      case alert:  return const Color(0xFFFFF5F5);
      case price:  return const Color(0xFFEFF6FF);
      case promo:  return const Color(0xFFFFFBEB);
    }
  }
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final bool isRead;
  final DateTime? expiresAt;
  final String? actionUrl;
  final String? actionLabel;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    this.expiresAt,
    this.actionUrl,
    this.actionLabel,
    required this.createdAt,
  });

  // Parsed defensively: Supabase realtime can hand back id as an int (int4
  // primary key) rather than a String, and a malformed/incomplete row must
  // never throw and break the whole stream — a single bad row silently
  // killed the unread-count badge before this fix.
  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id']?.toString() ?? '',
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        type: NotificationType.fromString(json['type'] as String? ?? 'update'),
        isRead: json['is_read'] as bool? ?? false,
        expiresAt: _tryParseDate(json['expires_at']),
        actionUrl:   json['action_url']   as String?,
        actionLabel: json['action_label'] as String?,
        createdAt: _tryParseDate(json['created_at']) ?? DateTime.now(),
      );

  static DateTime? _tryParseDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);
}

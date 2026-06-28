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

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        type: NotificationType.fromString(json['type'] as String? ?? 'update'),
        isRead: json['is_read'] as bool? ?? false,
        expiresAt: json['expires_at'] != null
            ? DateTime.parse(json['expires_at'] as String)
            : null,
        actionUrl:   json['action_url']   as String?,
        actionLabel: json['action_label'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);
}

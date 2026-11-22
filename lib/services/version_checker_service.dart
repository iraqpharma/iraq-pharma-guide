import 'dart:io' show Platform;

import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VersionCheckResult {
  final bool forceUpdate;
  final bool showUpdateDialog;
  final String minVersion;
  final String latestVersion;
  final String currentVersion;
  final String updateMessage;
  /// رابط المتجر من السيرفر لهذه المنصّة (فارغ = الرابط المبني في التطبيق).
  final String storeUrl;

  const VersionCheckResult({
    required this.forceUpdate,
    required this.showUpdateDialog,
    required this.minVersion,
    required this.latestVersion,
    required this.currentVersion,
    required this.updateMessage,
    this.storeUrl = '',
  });

  factory VersionCheckResult.passthrough() => const VersionCheckResult(
        forceUpdate: false,
        showUpdateDialog: false,
        minVersion: '0.0.0',
        latestVersion: '0.0.0',
        currentVersion: '0.0.0',
        updateMessage: '',
      );
}

class VersionCheckerService {
  VersionCheckerService._();
  static final VersionCheckerService instance = VersionCheckerService._();

  final _client = Supabase.instance.client;

  Future<VersionCheckResult> check() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final current = info.version;

      // select('*') لا قائمة أعمدة: الأعمدة الخاصة بكل منصّة اختيارية، فإن
      // لم تكن موجودة في الجدول يبقى الاستعلام سليماً ونرجع للأعمدة العامة.
      // المهلة تمنع تعليق شاشة البداية على اتصال ضعيف.
      final row = await _client
          .from('app_config')
          .select()
          .limit(1)
          .maybeSingle()
          .timeout(const Duration(seconds: 6));

      if (row == null) return VersionCheckResult.passthrough();

      // قيمة المنصّة إن وُجدت (min_version_ios / min_version_android …)،
      // وإلا القيمة العامة. بهذا يُفرض التحديث على منصّة نزل تحديثها في
      // متجرها دون أن يُقفل التطبيق على المنصّة الأخرى.
      final p = Platform.isIOS ? 'ios' : 'android';
      String str(String key, String fallback) {
        final specific = (row['${key}_$p'] as String?)?.trim() ?? '';
        if (specific.isNotEmpty) return specific;
        final general = (row[key] as String?)?.trim() ?? '';
        return general.isNotEmpty ? general : fallback;
      }

      final minVersion       = str('min_version', '0.0.0');
      final latestVersion    = str('latest_version', '0.0.0');
      final updateMessage    = str('update_message', '');
      final storeUrl         = str('store_url', '');
      final isForceUpdate    = row['is_force_update']    as bool?   ?? false;
      final showUpdateDialog = row['show_update_dialog'] as bool?   ?? false;

      final forceUpdate = isForceUpdate && _isLower(current, minVersion);
      // Show soft-update dialog only if enabled AND user hasn't updated yet
      final showSoft = showUpdateDialog &&
          !forceUpdate &&
          _isLower(current, latestVersion) &&
          updateMessage.isNotEmpty;

      return VersionCheckResult(
        forceUpdate:      forceUpdate,
        showUpdateDialog: showSoft,
        minVersion:       minVersion,
        latestVersion:    latestVersion,
        currentVersion:   current,
        updateMessage:    updateMessage,
        storeUrl:         storeUrl,
      );
    } catch (_) {
      return VersionCheckResult.passthrough();
    }
  }

  bool _isLower(String current, String minimum) {
    final cur = _parse(current);
    final min = _parse(minimum);
    for (int i = 0; i < 3; i++) {
      if (cur[i] < min[i]) return true;
      if (cur[i] > min[i]) return false;
    }
    return false;
  }

  List<int> _parse(String version) {
    final parts = version.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    while (parts.length < 3) parts.add(0);
    return parts.sublist(0, 3);
  }
}

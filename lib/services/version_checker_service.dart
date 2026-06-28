import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VersionCheckResult {
  final bool forceUpdate;
  final bool showUpdateDialog;
  final String minVersion;
  final String latestVersion;
  final String currentVersion;
  final String updateMessage;

  const VersionCheckResult({
    required this.forceUpdate,
    required this.showUpdateDialog,
    required this.minVersion,
    required this.latestVersion,
    required this.currentVersion,
    required this.updateMessage,
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

      final row = await _client
          .from('app_config')
          .select('min_version, is_force_update, latest_version, update_message, show_update_dialog')
          .limit(1)
          .maybeSingle();

      if (row == null) return VersionCheckResult.passthrough();

      final minVersion       = row['min_version']        as String? ?? '0.0.0';
      final isForceUpdate    = row['is_force_update']    as bool?   ?? false;
      final latestVersion    = row['latest_version']     as String? ?? '0.0.0';
      final updateMessage    = row['update_message']     as String? ?? '';
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

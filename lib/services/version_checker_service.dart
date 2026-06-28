import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Result of a version check.
class VersionCheckResult {
  final bool forceUpdate;
  final String minVersion;
  final String currentVersion;

  const VersionCheckResult({
    required this.forceUpdate,
    required this.minVersion,
    required this.currentVersion,
  });

  /// Graceful default when Supabase is unreachable — never block the user.
  factory VersionCheckResult.passthrough() => const VersionCheckResult(
        forceUpdate: false,
        minVersion: '0.0.0',
        currentVersion: '0.0.0',
      );
}

class VersionCheckerService {
  VersionCheckerService._();
  static final VersionCheckerService instance = VersionCheckerService._();

  final _client = Supabase.instance.client;

  Future<VersionCheckResult> check() async {
    try {
      // 1. Get current installed version
      final info = await PackageInfo.fromPlatform();
      final current = info.version; // e.g. "2.1.0"

      // 2. Fetch remote config
      final row = await _client
          .from('app_config')
          .select('min_version, is_force_update')
          .limit(1)
          .maybeSingle();

      if (row == null) return VersionCheckResult.passthrough();

      final minVersion    = row['min_version']    as String? ?? '0.0.0';
      final isForceUpdate = row['is_force_update'] as bool?   ?? false;

      // 3. Compare
      final needsUpdate = isForceUpdate && _isLower(current, minVersion);

      return VersionCheckResult(
        forceUpdate:    needsUpdate,
        minVersion:     minVersion,
        currentVersion: current,
      );
    } catch (_) {
      // Network error, Supabase down, etc. → never block the user
      return VersionCheckResult.passthrough();
    }
  }

  /// Returns true if [current] is strictly older than [minimum].
  /// Compares semantic version strings: "major.minor.patch".
  bool _isLower(String current, String minimum) {
    final cur = _parse(current);
    final min = _parse(minimum);
    for (int i = 0; i < 3; i++) {
      if (cur[i] < min[i]) return true;
      if (cur[i] > min[i]) return false;
    }
    return false; // equal → no force update
  }

  List<int> _parse(String version) {
    final parts = version.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    while (parts.length < 3) parts.add(0);
    return parts.sublist(0, 3);
  }
}

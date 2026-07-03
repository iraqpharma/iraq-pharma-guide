import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

/// Controls visibility of the "إدارة قاعدة البيانات" (database admin) feature.
///
/// The owner account always has access, even offline. Any other account
/// must have a matching row in the `database_admins` Supabase table
/// (managed by the owner via the Supabase dashboard).
class AdminAccessService {
  AdminAccessService._();
  static final instance = AdminAccessService._();

  static const _kOwnerEmail = String.fromEnvironment(
    'OWNER_EMAIL',
    defaultValue: 'mustafaqais750@gmail.com',
  );

  final _client = Supabase.instance.client;

  Future<bool> hasAccess() async {
    final email = AuthService.instance.currentUser?.email?.trim().toLowerCase();
    if (email == null || email.isEmpty) return false;

    // Owner always has access, no network round-trip required.
    if (email == _kOwnerEmail) return true;

    try {
      final rows = await _client
          .from('database_admins')
          .select('email')
          .eq('email', email)
          .limit(1);
      return rows.isNotEmpty;
    } catch (_) {
      // Table missing, RLS issue, or offline — fail closed (no access).
      return false;
    }
  }
}

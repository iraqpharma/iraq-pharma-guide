import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UserRole { manager, trainee }

class UserRoleNotifier extends StateNotifier<UserRole> {
  static const _key = 'user_role_v1';

  UserRoleNotifier() : super(UserRole.trainee) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    state = stored == 'manager' ? UserRole.manager : UserRole.trainee;
  }

  Future<void> setRole(UserRole role) async {
    state = role;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, role.name);
  }
}

final userRoleProvider =
    StateNotifierProvider<UserRoleNotifier, UserRole>((_) => UserRoleNotifier());

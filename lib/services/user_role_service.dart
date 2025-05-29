// lib/services/user_role_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class UserRoleService {
  static final _supabase = Supabase.instance.client;

  /// Fetches the user's role from the `user_roles` table.
  static Future<String?> getCurrentUserRole() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final res = await _supabase
        .from('user_roles')
        .select('role')
        .eq('user_id', userId)
        .maybeSingle();

    return res != null ? res['role'] as String : null;
  }
}

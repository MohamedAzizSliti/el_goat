import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' ;

class SupabaseAuthService {
  final _client = Supabase.instance.client;

  /// Returns the newly created userId, or null on failure.
  Future<String?> register(String email, String password) async {
    final res = await _client.auth.signUp(
      email: email,
      password: password,
    );
    return res.user?.id;
  }

   Future<void> login(String email, String password) async {
    // signInWithPassword will throw AuthException on failure
    await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }


  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  String? get currentUserId => _client.auth.currentUser?.id;
}

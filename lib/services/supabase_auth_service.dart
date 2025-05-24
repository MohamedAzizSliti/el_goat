import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class SupabaseAuthService {
  final _client = Supabase.instance.client;

  // Stream controller for auth state changes
  final _authStateController = StreamController<AuthState>.broadcast();

  SupabaseAuthService() {
    // Listen to auth state changes
    _client.auth.onAuthStateChange.listen((data) {
      _authStateController.add(data);
    });
  }

  /// Stream of authentication state changes
  Stream<AuthState> get authStateChanges => _authStateController.stream;

  /// Returns the newly created user, or throws AuthException on failure.
  Future<User> register(String email, String password) async {
    try {
      final res = await _client.auth.signUp(email: email, password: password);

      if (res.user == null) {
        throw const AuthException('Registration failed: No user returned');
      }

      return res.user!;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Registration failed: $e');
    }
  }

  /// Signs in user with email and password
  Future<User> login(String email, String password) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user == null) {
        throw const AuthException('Login failed: No user returned');
      }

      return res.user!;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Login failed: $e');
    }
  }

  /// Signs out the current user
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw AuthException('Sign out failed: $e');
    }
  }

  /// Sends password reset email
  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw AuthException('Password reset failed: $e');
    }
  }

  /// Updates user password
  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } catch (e) {
      throw AuthException('Password update failed: $e');
    }
  }

  /// Checks if user is currently signed in
  bool get isSignedIn => _client.auth.currentUser != null;

  /// Gets current user ID
  String? get currentUserId => _client.auth.currentUser?.id;

  /// Gets current user
  User? get currentUser => _client.auth.currentUser;

  /// Gets current session
  Session? get currentSession => _client.auth.currentSession;

  /// Dispose resources
  void dispose() {
    _authStateController.close();
  }
}

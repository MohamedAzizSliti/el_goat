import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  /// Registers a user using Supabase Admin OTP flow.
  /// If [otp] is null, generates and sends the OTP; returns null and expects OTP input.
  /// If [otp] is provided, verifies the OTP and completes registration.
  ///
  /// [supabaseUrl] and [serviceRoleKey] must be set with your project credentials.
  Future<User?> registerWithOtp({
    required String email,
    String? otp,
    required String supabaseUrl,
    required String serviceRoleKey,
  }) async {
    if (otp == null) {
      // Step 1: Generate OTP using admin API
      final url = Uri.parse('$supabaseUrl/auth/v1/otp');
      final response = await http.post(
        url,
        headers: {
          'apikey': serviceRoleKey,
          'Authorization': 'Bearer $serviceRoleKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'email': email, 'create_user': true}),
      );
      if (response.statusCode == 200) {
        // In production, Supabase sends the OTP directly to the user's email.
        // Do NOT try to read 'otp' from the response or send the OTP email yourself.
        return null; // Indicate OTP sent, waiting for user input
      } else {
        throw AuthException('OTP generation failed: ${response.body}');
      }
    } else {
      // Step 2: Verify OTP
      try {
        final res = await _client.auth.verifyOTP(
          type: OtpType.email,
          token: otp,
          email: email,
        );
        if (res.user == null) {
          throw const AuthException(
            'OTP verification failed: No user returned',
          );
        }
        return res.user!;
      } on AuthException {
        rethrow;
      } catch (e) {
        throw AuthException('OTP verification failed: $e');
      }
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

  /// Requests an OTP for email sign-in (does not create user)
  Future<void> signInWithOtp({
    required String email,
    required String supabaseUrl,
    required String serviceRoleKey,
  }) async {
    // Step 1: Generate OTP using admin API (no user creation)
    final url = Uri.parse('$supabaseUrl/auth/v1/otp');
    final response = await http.post(
      url,
      headers: {
        'apikey': serviceRoleKey,
        'Authorization': 'Bearer $serviceRoleKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'email': email, 'create_user': false}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final generatedOtp = data['otp'] as String?;
      if (generatedOtp == null) {
        throw AuthException('OTP not generated by Supabase response');
      }
      // Send OTP to user via email
      await _sendOtpEmail(email, generatedOtp);
    } else {
      throw AuthException('OTP generation failed: \\${response.body}');
    }
  }

  /// Verifies the OTP for sign-in
  /// Verifies the OTP for sign-in (email only)
  Future<User?> verifyOtp({required String email, required String otp}) async {
    if (email.isEmpty || otp.isEmpty) {
      throw AuthException('Email and OTP are required');
    }
    try {
      final res = await _client.auth.verifyOTP(
        type: OtpType.email,
        token: otp,
        email: email,
      );
      if (res.user == null) {
        throw const AuthException('OTP verification failed: No user returned');
      }
      return res.user!;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('OTP verification failed: $e');
    }
  }

  /// Dispose resources
  // Sends OTP email to the user
  Future<void> _sendOtpEmail(String email, String otp) async {
    // Example: Using a simple SMTP relay API (replace with your provider)
    final smtpApiUrl =
        'https://api.yoursmtpservice.com/send'; // Replace with your real endpoint
    final response = await http.post(
      Uri.parse(smtpApiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'to': email,
        'subject': 'Your OTP Code',
        'html':
            '<h2>Your OTP Code</h2><p>Use this code to log in:</p><h1>$otp</h1>',
      }),
    );
    if (response.statusCode != 200) {
      throw AuthException('Failed to send OTP email: \\${response.body}');
    }
  }

  void dispose() {
    _authStateController.close();
  }
}

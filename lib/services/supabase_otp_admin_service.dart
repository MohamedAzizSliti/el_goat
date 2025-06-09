import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for admin OTP generation and verification using Supabase Admin API.
/// WARNING: Do not use service_role key in production Flutter apps!
class SupabaseOtpAdminService {
  final String supabaseUrl;
  final String serviceRoleKey;

  SupabaseOtpAdminService({required this.supabaseUrl, required this.serviceRoleKey});

  /// Generates an OTP for the given email using Supabase Admin API.
  /// Returns the OTP code if successful, otherwise null.
  Future<String?> generateOtp({required String email}) async {
    final url = Uri.parse('$supabaseUrl/auth/v1/otp');
    final response = await http.post(
      url,
      headers: {
        'apikey': serviceRoleKey,
        'Authorization': 'Bearer $serviceRoleKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'create_user': true,
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['otp'] as String?;
    } else {
      print('Failed to generate OTP: \\${response.body}');
      return null;
    }
  }

  /// Verifies the OTP for the given email using Supabase client.
  Future<AuthResponse?> verifyOtp({required String email, required String otp}) async {
    final supabase = Supabase.instance.client;
    try {
      final response = await supabase.auth.verifyOTP(
        type: OtpType.email,
        token: otp,
        email: email,
      );
      return response;
    } catch (e) {
      print('OTP verification failed: $e');
      return null;
    }
  }
}

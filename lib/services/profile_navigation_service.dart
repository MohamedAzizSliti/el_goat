import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileNavigationService {
  static final _supabase = Supabase.instance.client;

  /// Determines the user's role and navigates to the appropriate profile page
  static Future<void> navigateToUserProfile(BuildContext context) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        Navigator.pushNamed(context, '/login');
        return;
      }

      // Check user role by looking at which profile table has their data
      final userRole = await _getUserRole(userId);
      
      switch (userRole) {
        case 'footballer':
          Navigator.pushNamed(context, '/footballer_profile');
          break;
        case 'scout':
          Navigator.pushNamed(context, '/scout_profile');
          break;
        case 'club':
          Navigator.pushNamed(context, '/club_profile');
          break;
        case 'fan':
          Navigator.pushNamed(context, '/fan_profile');
          break;
        default:
          // If no profile found, redirect to registration
          Navigator.pushNamed(context, '/registration');
          break;
      }
    } catch (e) {
      print('Error navigating to profile: $e');
      // Fallback to footballer profile
      Navigator.pushNamed(context, '/footballer_profile');
    }
  }

  /// Gets the user's role by checking which profile table contains their data
  static Future<String?> _getUserRole(String userId) async {
    try {
      // First check if there's a user_roles table entry
      final roleResponse = await _supabase
          .from('user_roles')
          .select('role')
          .eq('user_id', userId)
          .maybeSingle();

      if (roleResponse != null) {
        return roleResponse['role'] as String;
      }

      // Fallback: Check each profile table to determine role
      final tables = [
        {'table': 'footballer_profiles', 'role': 'footballer'},
        {'table': 'scout_profiles', 'role': 'scout'},
        {'table': 'club_profiles', 'role': 'club'},
        {'table': 'fan_profiles', 'role': 'fan'},
      ];

      for (final tableInfo in tables) {
        final response = await _supabase
            .from(tableInfo['table']!)
            .select('id')
            .eq('user_id', userId)
            .maybeSingle();

        if (response != null) {
          return tableInfo['role'];
        }
      }

      return null;
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  /// Gets the user's role (public method for other services to use)
  static Future<String?> getUserRole([String? userId]) async {
    final targetUserId = userId ?? _supabase.auth.currentUser?.id;
    if (targetUserId == null) return null;
    
    return await _getUserRole(targetUserId);
  }

  /// Gets the appropriate profile route for a user role
  static String getProfileRouteForRole(String role) {
    switch (role.toLowerCase()) {
      case 'footballer':
        return '/footballer_profile';
      case 'scout':
        return '/scout_profile';
      case 'club':
        return '/club_profile';
      case 'fan':
        return '/fan_profile';
      default:
        return '/footballer_profile'; // Default fallback
    }
  }

  /// Checks if user has completed their profile setup
  static Future<bool> hasCompletedProfile([String? userId]) async {
    try {
      final targetUserId = userId ?? _supabase.auth.currentUser?.id;
      if (targetUserId == null) return false;

      final role = await _getUserRole(targetUserId);
      if (role == null) return false;

      // Check if profile exists and has required fields
      switch (role) {
        case 'footballer':
          final profile = await _supabase
              .from('footballer_profiles')
              .select('full_name, position')
              .eq('user_id', targetUserId)
              .maybeSingle();
          return profile != null && 
                 profile['full_name'] != null && 
                 profile['position'] != null;

        case 'scout':
          final profile = await _supabase
              .from('scout_profiles')
              .select('full_name, country')
              .eq('user_id', targetUserId)
              .maybeSingle();
          return profile != null && 
                 profile['full_name'] != null;

        case 'club':
          final profile = await _supabase
              .from('club_profiles')
              .select('club_name')
              .eq('user_id', targetUserId)
              .maybeSingle();
          return profile != null && 
                 profile['club_name'] != null;

        case 'fan':
          final profile = await _supabase
              .from('fan_profiles')
              .select('full_name')
              .eq('user_id', targetUserId)
              .maybeSingle();
          return profile != null && 
                 profile['full_name'] != null;

        default:
          return false;
      }
    } catch (e) {
      print('Error checking profile completion: $e');
      return false;
    }
  }

  /// Creates a user role entry in the user_roles table
  static Future<bool> setUserRole(String userId, String role) async {
    try {
      await _supabase.from('user_roles').upsert({
        'user_id': userId,
        'role': role,
        'is_primary': true,
      });
      return true;
    } catch (e) {
      print('Error setting user role: $e');
      return false;
    }
  }

  /// Gets profile data for any user type
  static Future<Map<String, dynamic>?> getProfileData(String userId) async {
    try {
      final role = await _getUserRole(userId);
      if (role == null) return null;

      final tableName = '${role}_profiles';
      final response = await _supabase
          .from(tableName)
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        response['profile_type'] = role;
      }

      return response;
    } catch (e) {
      print('Error getting profile data: $e');
      return null;
    }
  }
}

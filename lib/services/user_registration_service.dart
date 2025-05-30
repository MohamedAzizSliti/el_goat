import 'package:supabase_flutter/supabase_flutter.dart';

class UserRegistrationService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Ensure user is properly registered in all necessary tables
  static Future<void> ensureUserRegistration() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      // Since you don't have a profiles table, we'll ensure user exists in their specific profile table
      // The foreign key constraint might be referencing auth.users or one of the profile tables

      // Check if user has a role assigned
      final roleResponse =
          await _client
              .from('user_roles')
              .select('role')
              .eq('user_id', user.id)
              .maybeSingle();

      if (roleResponse == null) {
        // User doesn't have a role, this might be a new user
        // For now, we'll skip automatic role assignment
        // The user should go through proper registration
        print('User ${user.id} has no role assigned');
        return;
      }

      final userRole = roleResponse['role'] as String;
      print('User ${user.id} has role: $userRole');

      // Ensure user exists in the appropriate profile table
      await _ensureProfileExists(user.id, userRole, user.email);
    } catch (e) {
      print('Error ensuring user registration: $e');
      // Don't throw, just log the error
    }
  }

  /// Ensure user exists in the main "profiles" table
  static Future<void> _ensureUserInUsersTable(
    String userId,
    String? email,
  ) async {
    try {
      // Check if user exists in the profiles table
      final existingUser =
          await _client
              .from('profiles')
              .select('id')
              .eq('id', userId)
              .maybeSingle();

      if (existingUser == null) {
        // User doesn't exist in profiles table, create them with minimal required fields
        await _client.from('profiles').insert({
          'id': userId,
          // Add other fields that might be required by your profiles table
          // We'll start with just the ID and add more if needed
        });
        print('Created user in profiles table: $userId');
      } else {
        print('User already exists in profiles table: $userId');
      }
    } catch (e) {
      print('Error ensuring user in profiles table: $e');
      // Try alternative approach - maybe the profiles table has different structure
      await _tryAlternativeProfilesInsert(userId, email);
    }
  }

  /// Try alternative approach for profiles table
  static Future<void> _tryAlternativeProfilesInsert(
    String userId,
    String? email,
  ) async {
    try {
      // Try with minimal fields
      await _client.from('profiles').insert({'id': userId});
      print('Created user in profiles table with minimal fields: $userId');
    } catch (e) {
      print('Alternative profiles insert failed: $e');
      // If this also fails, the table structure might be very different
      // Let's try to understand the table structure
      await _analyzeProfilesTable(userId);
    }
  }

  /// Analyze profiles table structure and try to insert
  static Future<void> _analyzeProfilesTable(String userId) async {
    try {
      // Try to get any existing record to understand the structure
      final sample =
          await _client.from('profiles').select().limit(1).maybeSingle();

      print('Sample profiles record: $sample');

      // Try with just the user ID and common fields
      await _client.from('profiles').insert({
        'id': userId,
        'user_id': userId, // Some tables might use user_id instead of id
      });
      print('Created user in profiles table with user_id field: $userId');
    } catch (e) {
      print('Final profiles insert attempt failed: $e');
      // At this point, we've tried multiple approaches
      // The user might need to complete their profile through the UI
    }
  }

  /// Ensure user has a profile in the appropriate table
  static Future<void> _ensureProfileExists(
    String userId,
    String role,
    String? email,
  ) async {
    try {
      switch (role) {
        case 'footballer':
          await _ensureFootballerProfile(userId, email);
          break;
        case 'scout':
          await _ensureScoutProfile(userId, email);
          break;
        case 'club':
          await _ensureClubProfile(userId, email);
          break;
        case 'fan':
          await _ensureFanProfile(userId, email);
          break;
        default:
          print('Unknown role: $role');
      }
    } catch (e) {
      print('Error ensuring profile for role $role: $e');
    }
  }

  /// Ensure footballer profile exists
  static Future<void> _ensureFootballerProfile(
    String userId,
    String? email,
  ) async {
    try {
      final existing =
          await _client
              .from('footballer_profiles')
              .select('user_id')
              .eq('user_id', userId)
              .maybeSingle();

      if (existing == null) {
        // Create basic footballer profile
        await _client.from('footballer_profiles').insert({
          'user_id': userId,
          'full_name': email?.split('@').first ?? 'Player',
          'position': 'Forward',
          'experience': 'Amateur',
          'date_of_birth': '2000-01-01',
          'height': 175,
          'weight': 70,
          'preferred_foot': 'Right',
          'bio': 'New player on El-Goat',
          'created_at': DateTime.now().toIso8601String(),
        });
        print('Created footballer profile for user $userId');
      }
    } catch (e) {
      print('Error ensuring footballer profile: $e');
    }
  }

  /// Ensure scout profile exists
  static Future<void> _ensureScoutProfile(String userId, String? email) async {
    try {
      final existing =
          await _client
              .from('scout_profiles')
              .select('user_id')
              .eq('user_id', userId)
              .maybeSingle();

      if (existing == null) {
        // Create basic scout profile
        await _client.from('scout_profiles').insert({
          'user_id': userId,
          'full_name': email?.split('@').first ?? 'Scout',
          'experience_years': 1,
          'specialization': 'General',
          'location': 'Unknown',
          'bio': 'New scout on El-Goat',
          'created_at': DateTime.now().toIso8601String(),
        });
        print('Created scout profile for user $userId');
      }
    } catch (e) {
      print('Error ensuring scout profile: $e');
    }
  }

  /// Ensure club profile exists
  static Future<void> _ensureClubProfile(String userId, String? email) async {
    try {
      final existing =
          await _client
              .from('club_profiles')
              .select('user_id')
              .eq('user_id', userId)
              .maybeSingle();

      if (existing == null) {
        // Create basic club profile
        await _client.from('club_profiles').insert({
          'user_id': userId,
          'club_name': email?.split('@').first ?? 'Club',
          'location': 'Unknown',
          'founded_year': DateTime.now().year,
          'description': 'New club on El-Goat',
          'created_at': DateTime.now().toIso8601String(),
        });
        print('Created club profile for user $userId');
      }
    } catch (e) {
      print('Error ensuring club profile: $e');
    }
  }

  /// Ensure fan profile exists
  static Future<void> _ensureFanProfile(String userId, String? email) async {
    try {
      final existing =
          await _client
              .from('fan_profiles')
              .select('user_id')
              .eq('user_id', userId)
              .maybeSingle();

      if (existing == null) {
        // Create basic fan profile
        await _client.from('fan_profiles').insert({
          'user_id': userId,
          'full_name': email?.split('@').first ?? 'Fan',
          'favorite_team': 'Unknown',
          'location': 'Unknown',
          'bio': 'New fan on El-Goat',
          'created_at': DateTime.now().toIso8601String(),
        });
        print('Created fan profile for user $userId');
      }
    } catch (e) {
      print('Error ensuring fan profile: $e');
    }
  }

  /// Check if user is properly registered for messaging
  static Future<bool> isUserRegisteredForMessaging(String userId) async {
    try {
      // First check if user exists in profiles table (main requirement for messaging)
      final profileExists =
          await _client
              .from('profiles')
              .select('id')
              .eq('id', userId)
              .maybeSingle();

      if (profileExists == null) {
        print('User $userId not found in profiles table');
        return false;
      }

      // Check if user has a role
      final roleResponse =
          await _client
              .from('user_roles')
              .select('role')
              .eq('user_id', userId)
              .maybeSingle();

      if (roleResponse == null) {
        print('User $userId has no role assigned');
        return false;
      }

      print('User $userId is properly registered for messaging');
      return true;
    } catch (e) {
      print('Error checking user registration: $e');
      return false;
    }
  }
}

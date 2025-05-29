// lib/services/profile_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../models/footballer_profile.dart';
import '../models/scout_profile.dart';
import '../models/club_profile.dart';

class ProfileService {
  static final _supabase = Supabase.instance.client;

  // Get current user profile
  static Future<UserProfile?> getCurrentUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response =
          await _supabase.from('profiles').select().eq('id', user.id).single();

      return UserProfile.fromJson(response);
    } catch (e) {
      print('Error getting current user profile: $e');
      return null;
    }
  }

  // Get footballer profile
  static Future<FootballerProfile?> getFootballerProfile(String userId) async {
    try {
      final response =
          await _supabase
              .from('footballer_profiles')
              .select()
              .eq('user_id', userId)
              .single();

      return FootballerProfile.fromJson(response);
    } catch (e) {
      print('Error getting footballer profile: $e');
      return null;
    }
  }

  // Get scout profile
  static Future<ScoutProfile?> getScoutProfile(String userId) async {
    try {
      final response =
          await _supabase
              .from('scout_profiles')
              .select()
              .eq('user_id', userId)
              .single();

      return ScoutProfile.fromJson(response);
    } catch (e) {
      print('Error getting scout profile: $e');
      return null;
    }
  }

  // Get club profile
  static Future<ClubProfile?> getClubProfile(String userId) async {
    try {
      final response =
          await _supabase
              .from('club_profiles')
              .select()
              .eq('user_id', userId)
              .single();

      return ClubProfile.fromJson(response);
    } catch (e) {
      print('Error getting club profile: $e');
      return null;
    }
  }

  // Update footballer profile
  static Future<bool> updateFootballerProfile(FootballerProfile profile) async {
    try {
      await _supabase
          .from('footballer_profiles')
          .update(profile.toJson())
          .eq('user_id', profile.userId);
      return true;
    } catch (e) {
      print('Error updating footballer profile: $e');
      return false;
    }
  }

  // Update scout profile
  static Future<bool> updateScoutProfile(ScoutProfile profile) async {
    try {
      await _supabase
          .from('scout_profiles')
          .update(profile.toJson())
          .eq('user_id', profile.userId);
      return true;
    } catch (e) {
      print('Error updating scout profile: $e');
      return false;
    }
  }

  // Update club profile
  static Future<bool> updateClubProfile(ClubProfile profile) async {
    try {
      await _supabase
          .from('club_profiles')
          .update(profile.toJson())
          .eq('user_id', profile.userId);
      return true;
    } catch (e) {
      print('Error updating club profile: $e');
      return false;
    }
  }

  // Get user role
  static Future<String?> getUserRole(String userId) async {
    try {
      final response =
          await _supabase
              .from('user_roles')
              .select('role')
              .eq('user_id', userId)
              .single();

      return response['role'] as String?;
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  // Search footballers
  static Future<List<FootballerProfile>> searchFootballers({
    String? position,
    String? experienceLevel,
    int? minAge,
    int? maxAge,
  }) async {
    try {
      var query = _supabase.from('footballer_profiles').select();

      if (position != null) {
        query = query.eq('position', position);
      }
      if (experienceLevel != null) {
        query = query.eq('experience_level', experienceLevel);
      }

      final response = await query;
      return (response as List)
          .map((json) => FootballerProfile.fromJson(json))
          .toList();
    } catch (e) {
      print('Error searching footballers: $e');
      return [];
    }
  }

  // Search scouts
  static Future<List<ScoutProfile>> searchScouts({
    String? country,
    String? scoutingLevel,
  }) async {
    try {
      var query = _supabase.from('scout_profiles').select();

      if (country != null) {
        query = query.eq('country', country);
      }
      if (scoutingLevel != null) {
        query = query.eq('scouting_level', scoutingLevel);
      }

      final response = await query;
      return (response as List)
          .map((json) => ScoutProfile.fromJson(json))
          .toList();
    } catch (e) {
      print('Error searching scouts: $e');
      return [];
    }
  }

  // Search clubs
  static Future<List<ClubProfile>> searchClubs({
    String? location,
    String? league,
  }) async {
    try {
      var query = _supabase.from('club_profiles').select();

      if (location != null) {
        query = query.ilike('location', '%$location%');
      }
      // Note: league field doesn't exist in current schema, so we skip it
      // if (league != null) {
      //   query = query.eq('league', league);
      // }

      final response = await query;
      return (response as List)
          .map((json) => ClubProfile.fromJson(json))
          .toList();
    } catch (e) {
      print('Error searching clubs: $e');
      return [];
    }
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseSetup {
  static final _supabase = Supabase.instance.client;

  static Future<void> setupPlayerSkills() async {
    try {
      // Create player_skills table
      await _supabase.rpc('create_player_skills_table');

      print('Successfully created player_skills table');
    } catch (e) {
      print('Error setting up player_skills table: $e');
      rethrow;
    }
  }

  static Future<void> checkAndSetupTables() async {
    try {
      // Check if player_skills table exists
      final response =
          await _supabase
              .from('player_skills')
              .select('count')
              .limit(1)
              .maybeSingle();

      if (response == null) {
        print('player_skills table does not exist, creating it...');
        await setupPlayerSkills();
      } else {
        print('player_skills table already exists');
      }
    } catch (e) {
      print('Error checking/setting up tables: $e');
      rethrow;
    }
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/skill_progress.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final _supabase = Supabase.instance.client;

  // Achievement Methods
  Future<void> updateAchievement(String userId, String achievementId, {
    required bool isUnlocked,
    DateTime? unlockedAt,
  }) async {
    await _supabase.from('user_achievements').upsert({
      'user_id': userId,
      'achievement_id': achievementId,
      'is_unlocked': isUnlocked,
      'unlocked_at': unlockedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getUserAchievements(String userId) async {
    return await _supabase
        .from('user_achievements')
        .select('''
          *,
          achievements:achievement_id (
            id,
            title,
            description,
            points_reward,
            icon_path
          )
        ''')
        .eq('user_id', userId);
  }

  // Skill Progress Methods
  Future<void> updateSkillProgress(String userId, String skillId, {
    required int currentLevel,
    required double progress,
  }) async {
    await _supabase.from('user_skill_progress').upsert({
      'user_id': userId,
      'skill_id': skillId,
      'current_level': currentLevel,
      'progress': progress,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getUserSkillProgress(String userId) async {
    return await _supabase
        .from('user_skill_progress')
        .select('''
          *,
          skills:skill_id (
            id,
            name,
            description,
            category_id,
            max_level,
            attributes
          )
        ''')
        .eq('user_id', userId);
  }

  // Video Progress Methods
  Future<void> updateVideoProgress(String userId, String videoId, double progress) async {
    await _supabase.from('video_progress').upsert({
      'user_id': userId,
      'video_id': videoId,
      'progress': progress,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, double>> getUserVideoProgress(String userId) async {
    final result = await _supabase
        .from('video_progress')
        .select('video_id, progress')
        .eq('user_id', userId);
    
    return Map.fromEntries(
      result.map((r) => MapEntry(r['video_id'] as String, r['progress'] as double))
    );
  }

  // Points and Stats Methods
  Future<void> updateUserPoints(String userId, int points) async {
    await _supabase.from('user_stats').upsert({
      'user_id': userId,
      'total_points': points,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> getUserPoints(String userId) async {
    final result = await _supabase
        .from('user_stats')
        .select('total_points')
        .eq('user_id', userId)
        .single();
    
    return result?['total_points'] ?? 0;
  }
} 
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/challenge.dart';
import '../models/skill_progress.dart';
import '../models/playlist.dart';

class GamificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Skill Progress Methods
  Future<void> updateSkillProgress(String skillId, double progressIncrement) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // Get current skill progress
    final res = await _supabase
        .from('skill_progress')
        .select()
        .eq('user_id', user.id)
        .eq('skill_id', skillId)
        .single();

    if (res == null) {
      // Create new skill progress
      await _supabase.from('skill_progress').insert({
        'user_id': user.id,
        'skill_id': skillId,
        'current_level': 1,
        'progress': progressIncrement,
      });
    } else {
      double newProgress = (res['progress'] as double) + progressIncrement;
      int currentLevel = res['current_level'] as int;

      // Level up if progress reaches 100%
      if (newProgress >= 1.0) {
        currentLevel++;
        newProgress = newProgress - 1.0;
      }

      // Update skill progress
      await _supabase
          .from('skill_progress')
          .update({
            'current_level': currentLevel,
            'progress': newProgress,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', user.id)
          .eq('skill_id', skillId);
    }
  }

  // Challenge Methods
  Future<void> updateChallengeProgress(String challengeId, int progressIncrement) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // Get current challenge progress
    final res = await _supabase
        .from('user_challenge_progress')
        .select('*, challenge:challenges(*)')
        .eq('user_id', user.id)
        .eq('challenge_id', challengeId)
        .single();

    if (res == null) {
      // Create new challenge progress
      await _supabase.from('user_challenge_progress').insert({
        'user_id': user.id,
        'challenge_id': challengeId,
        'current_progress': progressIncrement,
      });
    } else {
      int newProgress = (res['current_progress'] as int) + progressIncrement;
      bool wasCompleted = res['is_completed'] as bool;
      final challenge = res['challenge'] as Map<String, dynamic>;

      // Check if challenge is completed
      if (!wasCompleted && newProgress >= challenge['target_progress']) {
        // Update challenge progress and mark as completed
        await _supabase
            .from('user_challenge_progress')
            .update({
              'current_progress': newProgress,
              'is_completed': true,
              'completed_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', user.id)
            .eq('challenge_id', challengeId);

        // Update user stats (points will be added by trigger)
        await _updateUserStats(challenge['points_reward'] as int);
      } else {
        // Just update progress
        await _supabase
            .from('user_challenge_progress')
            .update({
              'current_progress': newProgress,
            })
            .eq('user_id', user.id)
            .eq('challenge_id', challengeId);
      }
    }
  }

  Future<void> _updateUserStats(int pointsToAdd) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase
        .from('user_stats')
        .update({
          'total_points': await _supabase.rpc(
            'increment_points',
            params: {'points_to_add': pointsToAdd},
          ),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', user.id);
  }

  // Video Watching Progress
  Future<void> onVideoWatched(String videoPath) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // Get video metadata
    final videoMeta = await _supabase
        .from('video_metadata')
        .select('skill_id, challenge_ids')
        .eq('video_path', videoPath)
        .single();

    if (videoMeta != null) {
      // Update skill progress if video is related to a skill
      if (videoMeta['skill_id'] != null) {
        await updateSkillProgress(videoMeta['skill_id'], 0.1); // 10% progress per video
      }

      // Update challenge progress if video is part of any challenges
      if (videoMeta['challenge_ids'] != null) {
        for (String challengeId in videoMeta['challenge_ids']) {
          await updateChallengeProgress(challengeId, 1);
        }
      }
    }
  }

  // Playlist Methods
  Future<Playlist> createPlaylist({
    required String name,
    required String description,
    required List<String> videoUrls,
    required List<String> tags,
    bool isPublic = true,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final res = await _supabase.from('playlists').insert({
      'name': name,
      'description': description,
      'created_by': user.id,
      'video_urls': videoUrls,
      'tags': tags,
      'is_public': isPublic,
    }).select().single();

    return Playlist.fromJson(res);
  }

  Future<void> updatePlaylist(Playlist playlist) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _supabase
        .from('playlists')
        .update(playlist.toJson())
        .eq('id', playlist.id)
        .eq('created_by', user.id);
  }

  Future<void> deletePlaylist(String playlistId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _supabase
        .from('playlists')
        .delete()
        .eq('id', playlistId)
        .eq('created_by', user.id);
  }
} 
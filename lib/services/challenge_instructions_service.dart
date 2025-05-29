import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/challenge_instructions.dart';

class ChallengeInstructionsService {
  final _supabase = Supabase.instance.client;

  Future<ChallengeInstructions?> getInstructions(String challengeId) async {
    try {
      final response = await _supabase
          .from('challenge_instructions')
          .select()
          .eq('challenge_id', challengeId)
          .single();

      if (response != null) {
        return ChallengeInstructions.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Error fetching challenge instructions: $e');
      return null;
    }
  }

  Future<bool> checkPrerequisites(String challengeId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      final instructions = await getInstructions(challengeId);
      if (instructions == null) return true; // No prerequisites to check

      // Get user stats
      final userStats = await _supabase
          .from('user_stats')
          .select()
          .eq('user_id', user.id)
          .single();

      if (userStats == null) return false;

      // Check minimum level
      final minLevel = instructions.prerequisites['minimum_level'] ?? 1;
      if ((userStats['level'] ?? 1) < minLevel) return false;

      // Check required accuracy
      final reqAccuracy = double.tryParse(
          instructions.prerequisites['required_accuracy']?.toString() ?? '0') ?? 0;
      if ((userStats['shooting_accuracy'] ?? 0) < reqAccuracy) return false;

      // Check completed tutorials
      final requiredTutorials = List<String>.from(
          instructions.prerequisites['completed_tutorials'] ?? []);
      final completedTutorials =
          List<String>.from(userStats['completed_tutorials'] ?? []);
      if (!requiredTutorials.every(
          (tutorial) => completedTutorials.contains(tutorial))) {
        return false;
      }

      return true;
    } catch (e) {
      print('Error checking prerequisites: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> trackStepProgress(
      String challengeId, int stepIndex, Map<String, dynamic> progress) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return {'error': 'User not authenticated'};
    }

    try {
      // Get current progress
      final currentProgress = await _supabase
          .from('user_challenge_progress')
          .select('step_progress')
          .eq('user_id', user.id)
          .eq('challenge_id', challengeId)
          .single();

      List<Map<String, dynamic>> stepProgress;
      if (currentProgress == null || currentProgress['step_progress'] == null) {
        stepProgress = [];
      } else {
        stepProgress = List<Map<String, dynamic>>.from(
            currentProgress['step_progress']);
      }

      // Update or add step progress
      while (stepProgress.length <= stepIndex) {
        stepProgress.add({});
      }
      stepProgress[stepIndex] = progress;

      // Update progress in database
      await _supabase.from('user_challenge_progress').upsert({
        'user_id': user.id,
        'challenge_id': challengeId,
        'step_progress': stepProgress,
        'updated_at': DateTime.now().toIso8601String(),
      });

      return {'success': true, 'step_progress': stepProgress};
    } catch (e) {
      print('Error tracking step progress: $e');
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getStepProgress(
      String challengeId, int stepIndex) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return {'error': 'User not authenticated'};
    }

    try {
      final progress = await _supabase
          .from('user_challenge_progress')
          .select('step_progress')
          .eq('user_id', user.id)
          .eq('challenge_id', challengeId)
          .single();

      if (progress == null ||
          progress['step_progress'] == null ||
          stepIndex >= (progress['step_progress'] as List).length) {
        return {};
      }

      return Map<String, dynamic>.from(progress['step_progress'][stepIndex]);
    } catch (e) {
      print('Error getting step progress: $e');
      return {'error': e.toString()};
    }
  }
} 
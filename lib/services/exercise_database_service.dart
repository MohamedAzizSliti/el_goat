import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/exercise_model.dart';

class ExerciseDatabaseService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Save exercises to database
  static Future<List<ExerciseModel>> saveExercises(
    List<ExerciseModel> exercises,
  ) async {
    try {
      final exerciseData =
          exercises.map((e) {
            final json = e.toJson();
            // Remove the id field to let the database generate it
            json.remove('id');
            return json;
          }).toList();

      final response =
          await _supabase.from('exercises').insert(exerciseData).select();

      return response.map((data) => ExerciseModel.fromJson(data)).toList();
    } catch (e) {
      print('Error saving exercises: $e');
      throw Exception('Failed to save exercises to database');
    }
  }

  /// Get all exercises for a user
  static Future<List<ExerciseModel>> getUserExercises(String userId) async {
    try {
      final response = await _supabase
          .from('exercises')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return response.map((data) => ExerciseModel.fromJson(data)).toList();
    } catch (e) {
      print('Error fetching user exercises: $e');
      throw Exception('Failed to fetch exercises');
    }
  }

  /// Get exercises by status
  static Future<List<ExerciseModel>> getExercisesByStatus(
    String userId,
    ExerciseStatus status,
  ) async {
    try {
      final response = await _supabase
          .from('exercises')
          .select()
          .eq('user_id', userId)
          .eq('status', status.name)
          .order('created_at', ascending: false);

      return response.map((data) => ExerciseModel.fromJson(data)).toList();
    } catch (e) {
      print('Error fetching exercises by status: $e');
      throw Exception('Failed to fetch exercises by status');
    }
  }

  /// Update exercise status
  static Future<ExerciseModel> updateExerciseStatus(
    String exerciseId,
    ExerciseStatus newStatus,
  ) async {
    try {
      final updateData = <String, dynamic>{'status': newStatus.name};

      // Add timestamps based on status
      switch (newStatus) {
        case ExerciseStatus.doing:
          updateData['started_at'] = DateTime.now().toIso8601String();
          break;
        case ExerciseStatus.done:
          updateData['completed_at'] = DateTime.now().toIso8601String();
          break;
        case ExerciseStatus.pending:
          // Reset timestamps if going back to pending
          updateData['started_at'] = null;
          updateData['completed_at'] = null;
          break;
      }

      final response =
          await _supabase
              .from('exercises')
              .update(updateData)
              .eq('id', exerciseId)
              .select()
              .single();

      return ExerciseModel.fromJson(response);
    } catch (e) {
      print('Error updating exercise status: $e');
      throw Exception('Failed to update exercise status');
    }
  }

  /// Update exercise score and feedback
  static Future<ExerciseModel> updateExerciseScore(
    String exerciseId,
    int score,
    String? feedback,
  ) async {
    try {
      final response =
          await _supabase
              .from('exercises')
              .update({
                'score': score,
                'feedback': feedback,
                'status': ExerciseStatus.done.name,
                'completed_at': DateTime.now().toIso8601String(),
              })
              .eq('id', exerciseId)
              .select()
              .single();

      return ExerciseModel.fromJson(response);
    } catch (e) {
      print('Error updating exercise score: $e');
      throw Exception('Failed to update exercise score');
    }
  }

  /// Delete exercise
  static Future<void> deleteExercise(String exerciseId) async {
    try {
      await _supabase.from('exercises').delete().eq('id', exerciseId);
    } catch (e) {
      print('Error deleting exercise: $e');
      throw Exception('Failed to delete exercise');
    }
  }

  /// Get exercise statistics for user
  static Future<Map<String, dynamic>> getExerciseStats(String userId) async {
    try {
      final exercises = await getUserExercises(userId);

      final totalExercises = exercises.length;
      final completedExercises = exercises.where((e) => e.isCompleted).length;
      final inProgressExercises = exercises.where((e) => e.isInProgress).length;
      final pendingExercises = exercises.where((e) => e.isPending).length;

      final completedWithScores = exercises.where(
        (e) => e.isCompleted && e.score != null,
      );
      final averageScore =
          completedWithScores.isNotEmpty
              ? completedWithScores
                      .map((e) => e.score!)
                      .reduce((a, b) => a + b) /
                  completedWithScores.length
              : 0.0;

      // Calculate total time spent
      final totalTimeSpent = exercises
          .where((e) => e.timeSpent != null)
          .map((e) => e.timeSpent!.inMinutes)
          .fold(0, (sum, minutes) => sum + minutes);

      // Exercise type distribution
      final typeDistribution = <String, int>{};
      for (final exercise in exercises) {
        typeDistribution[exercise.type.name] =
            (typeDistribution[exercise.type.name] ?? 0) + 1;
      }

      return {
        'totalExercises': totalExercises,
        'completedExercises': completedExercises,
        'inProgressExercises': inProgressExercises,
        'pendingExercises': pendingExercises,
        'completionRate':
            totalExercises > 0
                ? (completedExercises / totalExercises * 100)
                : 0.0,
        'averageScore': averageScore,
        'totalTimeSpent': totalTimeSpent,
        'typeDistribution': typeDistribution,
      };
    } catch (e) {
      print('Error getting exercise stats: $e');
      throw Exception('Failed to get exercise statistics');
    }
  }

  /// Get recent exercises (last 7 days)
  static Future<List<ExerciseModel>> getRecentExercises(String userId) async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

      final response = await _supabase
          .from('exercises')
          .select()
          .eq('user_id', userId)
          .gte('created_at', sevenDaysAgo.toIso8601String())
          .order('created_at', ascending: false);

      return response.map((data) => ExerciseModel.fromJson(data)).toList();
    } catch (e) {
      print('Error fetching recent exercises: $e');
      throw Exception('Failed to fetch recent exercises');
    }
  }

  /// Search exercises by title or description
  static Future<List<ExerciseModel>> searchExercises(
    String userId,
    String query,
  ) async {
    try {
      final response = await _supabase
          .from('exercises')
          .select()
          .eq('user_id', userId)
          .or('title.ilike.%$query%,description.ilike.%$query%')
          .order('created_at', ascending: false);

      return response.map((data) => ExerciseModel.fromJson(data)).toList();
    } catch (e) {
      print('Error searching exercises: $e');
      throw Exception('Failed to search exercises');
    }
  }

  /// Get exercises by type
  static Future<List<ExerciseModel>> getExercisesByType(
    String userId,
    ExerciseType type,
  ) async {
    try {
      final response = await _supabase
          .from('exercises')
          .select()
          .eq('user_id', userId)
          .eq('type', type.name)
          .order('created_at', ascending: false);

      return response.map((data) => ExerciseModel.fromJson(data)).toList();
    } catch (e) {
      print('Error fetching exercises by type: $e');
      throw Exception('Failed to fetch exercises by type');
    }
  }

  /// Get exercises by difficulty
  static Future<List<ExerciseModel>> getExercisesByDifficulty(
    String userId,
    ExerciseDifficulty difficulty,
  ) async {
    try {
      final response = await _supabase
          .from('exercises')
          .select()
          .eq('user_id', userId)
          .eq('difficulty', difficulty.name)
          .order('created_at', ascending: false);

      return response.map((data) => ExerciseModel.fromJson(data)).toList();
    } catch (e) {
      print('Error fetching exercises by difficulty: $e');
      throw Exception('Failed to fetch exercises by difficulty');
    }
  }
}

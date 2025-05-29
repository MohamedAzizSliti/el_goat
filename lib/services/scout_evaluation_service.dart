import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/scout_evaluation.dart';

class ScoutEvaluationService {
  static final ScoutEvaluationService _instance = ScoutEvaluationService._internal();
  factory ScoutEvaluationService() => _instance;
  ScoutEvaluationService._internal();

  final _supabase = Supabase.instance.client;

  /// Create a new scout evaluation
  Future<ScoutEvaluation?> createEvaluation(ScoutEvaluation evaluation) async {
    try {
      final data = await _supabase
          .from('scout_evaluations')
          .insert(evaluation.toJson())
          .select()
          .single();

      return ScoutEvaluation.fromJson(data);
    } catch (e) {
      print('Error creating evaluation: $e');
      return null;
    }
  }

  /// Update an existing evaluation
  Future<ScoutEvaluation?> updateEvaluation(ScoutEvaluation evaluation) async {
    try {
      final data = await _supabase
          .from('scout_evaluations')
          .update(evaluation.toJson())
          .eq('id', evaluation.id)
          .select()
          .single();

      return ScoutEvaluation.fromJson(data);
    } catch (e) {
      print('Error updating evaluation: $e');
      return null;
    }
  }

  /// Get evaluations by scout ID
  Future<List<ScoutEvaluation>> getEvaluationsByScout(String scoutId) async {
    try {
      final data = await _supabase
          .from('scout_evaluations')
          .select()
          .eq('scout_id', scoutId)
          .order('evaluation_date', ascending: false);

      return data.map((json) => ScoutEvaluation.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching scout evaluations: $e');
      return [];
    }
  }

  /// Get evaluations for a specific player
  Future<List<ScoutEvaluation>> getEvaluationsForPlayer(String playerId) async {
    try {
      final data = await _supabase
          .from('scout_evaluations')
          .select()
          .eq('player_id', playerId)
          .order('evaluation_date', ascending: false);

      return data.map((json) => ScoutEvaluation.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching player evaluations: $e');
      return [];
    }
  }

  /// Get a specific evaluation by ID
  Future<ScoutEvaluation?> getEvaluationById(String evaluationId) async {
    try {
      final data = await _supabase
          .from('scout_evaluations')
          .select()
          .eq('id', evaluationId)
          .single();

      return ScoutEvaluation.fromJson(data);
    } catch (e) {
      print('Error fetching evaluation: $e');
      return null;
    }
  }

  /// Delete an evaluation
  Future<bool> deleteEvaluation(String evaluationId) async {
    try {
      await _supabase
          .from('scout_evaluations')
          .delete()
          .eq('id', evaluationId);

      return true;
    } catch (e) {
      print('Error deleting evaluation: $e');
      return false;
    }
  }

  /// Check if scout has already evaluated a player on a specific date
  Future<bool> hasEvaluatedPlayerOnDate(
    String scoutId, 
    String playerId, 
    DateTime date
  ) async {
    try {
      final data = await _supabase
          .from('scout_evaluations')
          .select('id')
          .eq('scout_id', scoutId)
          .eq('player_id', playerId)
          .eq('evaluation_date', date.toIso8601String().split('T')[0]);

      return data.isNotEmpty;
    } catch (e) {
      print('Error checking evaluation existence: $e');
      return false;
    }
  }

  /// Get evaluation statistics for a player
  Future<Map<String, dynamic>?> getPlayerEvaluationStats(String playerId) async {
    try {
      final data = await _supabase
          .from('scout_evaluation_stats')
          .select()
          .eq('player_id', playerId)
          .maybeSingle();

      return data;
    } catch (e) {
      print('Error fetching player evaluation stats: $e');
      return null;
    }
  }

  /// Get recent evaluations (last 30 days)
  Future<List<ScoutEvaluation>> getRecentEvaluations({int days = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      
      final data = await _supabase
          .from('scout_evaluations')
          .select()
          .gte('evaluation_date', cutoffDate.toIso8601String().split('T')[0])
          .order('evaluation_date', ascending: false);

      return data.map((json) => ScoutEvaluation.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching recent evaluations: $e');
      return [];
    }
  }

  /// Get top-rated players based on evaluations
  Future<List<Map<String, dynamic>>> getTopRatedPlayers({int limit = 10}) async {
    try {
      final data = await _supabase
          .from('scout_evaluation_stats')
          .select()
          .order('avg_overall_rating', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('Error fetching top-rated players: $e');
      return [];
    }
  }

  /// Search evaluations with filters
  Future<List<ScoutEvaluation>> searchEvaluations({
    String? scoutId,
    String? playerId,
    String? playerPosition,
    RecommendationType? recommendation,
    int? minOverallRating,
    int? maxOverallRating,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      var query = _supabase.from('scout_evaluations').select();

      if (scoutId != null) {
        query = query.eq('scout_id', scoutId);
      }

      if (playerId != null) {
        query = query.eq('player_id', playerId);
      }

      if (playerPosition != null) {
        query = query.eq('player_position', playerPosition);
      }

      if (recommendation != null) {
        query = query.eq('recommendation', recommendation.value);
      }

      if (minOverallRating != null) {
        query = query.gte('overall_rating', minOverallRating);
      }

      if (maxOverallRating != null) {
        query = query.lte('overall_rating', maxOverallRating);
      }

      if (fromDate != null) {
        query = query.gte('evaluation_date', fromDate.toIso8601String().split('T')[0]);
      }

      if (toDate != null) {
        query = query.lte('evaluation_date', toDate.toIso8601String().split('T')[0]);
      }

      final data = await query.order('evaluation_date', ascending: false);

      return data.map((json) => ScoutEvaluation.fromJson(json)).toList();
    } catch (e) {
      print('Error searching evaluations: $e');
      return [];
    }
  }
}

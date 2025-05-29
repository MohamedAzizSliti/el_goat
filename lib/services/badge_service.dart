import 'package:supabase_flutter/supabase_flutter.dart';

enum BadgeType {
  topScorer,
  scoutApproved,
  fanFavorite,
  skillMaster,
  challengeChampion,
  risingTalent,
  teamPlayer,
  perfectAttendance,
  trainingExcellence,
  matchMVP,
}

class BadgeService {
  static final BadgeService _instance = BadgeService._internal();
  factory BadgeService() => _instance;
  BadgeService._internal();

  final _supabase = Supabase.instance.client;

  final Map<BadgeType, Map<String, dynamic>> badgeDefinitions = {
    BadgeType.topScorer: {
      'title': 'Top Scorer',
      'description': 'Score the most goals in your league',
      'requirements': [
        {'description': 'Score 10 goals', 'target': 10, 'type': 'goals'},
        {
          'description': 'Maintain 75% shot accuracy',
          'target': 75,
          'type': 'accuracy',
        },
      ],
      'background_color': 0xFF1B4D3E, // Dark green
      'icon_color': 0xFFFFD700, // Gold
    },
    BadgeType.scoutApproved: {
      'title': 'Scout Approved',
      'description': 'Get noticed by professional scouts',
      'requirements': [
        {
          'description': 'Get 3 scout recommendations',
          'target': 3,
          'type': 'recommendations',
        },
        {
          'description': 'Complete skill assessments',
          'target': 1,
          'type': 'assessment',
        },
      ],
      'background_color': 0xFF1B4D3E,
      'icon_color': 0xFFFFD700,
    },
    BadgeType.fanFavorite: {
      'title': 'Fan Favorite',
      'description': 'Become a crowd favorite with outstanding performances',
      'requirements': [
        {
          'description': 'Receive 50 fan votes',
          'target': 50,
          'type': 'fan_votes',
        },
        {
          'description': 'Achieve 90% positive ratings',
          'target': 90,
          'type': 'rating',
        },
      ],
      'background_color': 0xFF0A1E3D, // Dark blue
      'icon_color': 0xFFFFD700,
    },
    BadgeType.skillMaster: {
      'title': 'Skill Master',
      'description': 'Master multiple football skills',
      'requirements': [
        {
          'description': 'Reach level 5 in any skill',
          'target': 5,
          'type': 'skill_level',
        },
        {
          'description': 'Complete advanced drills',
          'target': 10,
          'type': 'drills',
        },
      ],
      'background_color': 0xFF1B4D3E,
      'icon_color': 0xFFFFD700,
    },
  };

  Future<List<Map<String, dynamic>>> getUserBadges() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final badgesRes = await _supabase
          .from('player_badges')
          .select()
          .eq('player_id', user.id);

      return List<Map<String, dynamic>>.from(badgesRes).map((badge) {
        final BadgeType type = BadgeType.values.firstWhere(
          (t) => t.toString().split('.').last == badge['badge_type'],
          orElse: () => BadgeType.topScorer,
        );

        return {
          ...badge,
          ...badgeDefinitions[type]!,
          'is_unlocked': badge['is_unlocked'] ?? false,
          'progress': _calculateProgress(badge, type),
        };
      }).toList();
    } catch (e) {
      print('Error fetching badges: $e');
      return [];
    }
  }

  Future<void> checkAndUpdateBadges() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Check each badge type's requirements
      for (var type in BadgeType.values) {
        final meetsRequirements = await _checkBadgeRequirements(type);
        if (meetsRequirements) {
          await _unlockBadge(type);
        }
      }
    } catch (e) {
      print('Error updating badges: $e');
    }
  }

  Future<bool> _checkBadgeRequirements(BadgeType type) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    final definition = badgeDefinitions[type];
    if (definition == null) return false;

    try {
      switch (type) {
        case BadgeType.topScorer:
          final stats =
              await _supabase
                  .from('player_stats')
                  .select('goals, shot_accuracy')
                  .eq('player_id', user.id)
                  .single();

          return (stats['goals'] ?? 0) >= 10 &&
              (stats['shot_accuracy'] ?? 0) >= 75;

        case BadgeType.scoutApproved:
          final recommendations = await _supabase
              .from('scout_recommendations')
              .select('id')
              .eq('player_id', user.id);

          return recommendations.length >= 3;

        case BadgeType.fanFavorite:
          final fanStats =
              await _supabase
                  .from('player_fan_stats')
                  .select('votes, rating')
                  .eq('player_id', user.id)
                  .single();

          return (fanStats['votes'] ?? 0) >= 50 &&
              (fanStats['rating'] ?? 0) >= 90;

        case BadgeType.skillMaster:
          final skills = await _supabase
              .from('player_skills')
              .select('level')
              .eq('player_id', user.id)
              .gte('level', 5);

          return skills.isNotEmpty;

        default:
          return false;
      }
    } catch (e) {
      print('Error checking badge requirements: $e');
      return false;
    }
  }

  Future<void> _unlockBadge(BadgeType type) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase.from('player_badges').upsert({
        'player_id': user.id,
        'badge_type': type.toString().split('.').last,
        'is_unlocked': true,
        'unlocked_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error unlocking badge: $e');
    }
  }

  double _calculateProgress(Map<String, dynamic> badge, BadgeType type) {
    if (badge['is_unlocked'] ?? false) return 1.0;

    final requirements = badgeDefinitions[type]?['requirements'] as List?;
    if (requirements == null || requirements.isEmpty) return 0.0;

    double totalProgress = 0;
    for (var req in requirements) {
      final current = badge['progress']?[req['type']] ?? 0;
      final target = req['target'] ?? 1;
      totalProgress += (current / target).clamp(0.0, 1.0);
    }

    return (totalProgress / requirements.length).clamp(0.0, 1.0);
  }
}

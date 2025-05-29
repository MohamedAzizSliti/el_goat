import 'package:flutter/material.dart';
import '../widgets/achievement_notification.dart';
import 'database_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final String? iconPath;
  final int pointsReward;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final BuildContext? context;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    this.iconPath,
    required this.pointsReward,
    this.isUnlocked = false,
    this.unlockedAt,
    this.context,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      iconPath: json['icon_path'],
      pointsReward: json['points_reward'],
      isUnlocked: json['is_unlocked'] ?? false,
      unlockedAt: json['unlocked_at'] != null 
          ? DateTime.parse(json['unlocked_at'])
          : null,
      context: null,
    );
  }
}

class AchievementService {
  static final AchievementService _instance = AchievementService._internal();
  factory AchievementService() => _instance;
  AchievementService._internal();

  final List<Achievement> _achievements = [];
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final DatabaseService _db = DatabaseService();
  final _supabase = Supabase.instance.client;

  Future<void> initialize() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final achievements = await _db.getUserAchievements(user.id);
    _achievements.clear();
    _achievements.addAll(
      achievements.map((a) => Achievement.fromJson({
        ...a['achievements'],
        'is_unlocked': a['is_unlocked'],
        'unlocked_at': a['unlocked_at'],
      })),
    );
  }

  void showAchievementNotification(BuildContext context, Achievement achievement) {
    OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.emoji_events, color: Colors.amber, size: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Achievement Unlocked!',
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        achievement.title,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      Text(
                        '+${achievement.pointsReward} points',
                        style: const TextStyle(color: Colors.green, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
              .animate()
              .slideX(
                begin: 1,
                end: 0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutBack,
              )
              .then()
              .shimmer(
                duration: const Duration(milliseconds: 800),
                color: Colors.amber.withOpacity(0.3),
              ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    Future.delayed(const Duration(seconds: 4), () {
      overlayEntry.remove();
    });
  }

  Future<void> unlockAchievement(String achievementId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase.from('user_achievements').insert({
        'user_id': userId,
        'achievement_id': achievementId,
        'unlocked_at': DateTime.now().toIso8601String(),
      });

      final achievement = _achievements.firstWhere((a) => a.id == achievementId);
      if (achievement.context != null && achievement.context is BuildContext) {
        showAchievementNotification(achievement.context as BuildContext, achievement);
      }
    } catch (e) {
      debugPrint('Error unlocking achievement: $e');
    }
  }

  List<Achievement> getUnlockedAchievements() {
    return _achievements.where((a) => a.isUnlocked).toList();
  }

  List<Achievement> getAllAchievements() {
    return List.from(_achievements);
  }

  double getCompletionPercentage() {
    if (_achievements.isEmpty) return 0.0;
    final unlockedCount = _achievements.where((a) => a.isUnlocked).length;
    return unlockedCount / _achievements.length;
  }
} 
import 'package:flutter/material.dart';
import '../models/skill_progress.dart';
import 'database_service.dart';
import 'achievement_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SkillProgressService {
  static final SkillProgressService _instance = SkillProgressService._internal();
  factory SkillProgressService() => _instance;
  SkillProgressService._internal();

  final _supabase = Supabase.instance.client;
  final Map<String, SkillCategory> _categories = {};
  final Map<String, double> _videoProgress = {};
  final DatabaseService _db = DatabaseService();
  final AchievementService _achievements = AchievementService();

  Future<void> initialize() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Fetch skill categories and their skills
      final skillsData = await _supabase
          .from('skills')
          .select('*, skill_categories(*)');

      // Group skills by category
      final Map<String, List<Skill>> skillsByCategory = {};
      for (final skillData in skillsData) {
        final categoryId = skillData['skill_categories']['id'];
        skillsByCategory.putIfAbsent(categoryId, () => []);

        // Create skill object
        final skill = Skill(
          id: skillData['id'],
          name: skillData['name'],
          description: skillData['description'],
          icon: skillData['icon_name'] != null 
              ? IconData(int.parse(skillData['icon_name']), fontFamily: 'MaterialIcons')
              : null,
          currentLevel: skillData['current_level'] ?? 1,
          maxLevel: skillData['max_level'] ?? 100,
          progress: skillData['progress']?.toDouble() ?? 0.0,
          relatedVideos: List<String>.from(skillData['related_videos'] ?? []),
          attributes: Map<String, double>.from(skillData['attributes'] ?? {}),
          position: Offset(
            skillData['position_x']?.toDouble() ?? 0.0,
            skillData['position_y']?.toDouble() ?? 0.0,
          ),
        );

        skillsByCategory[categoryId]!.add(skill);
      }

      // Create categories
      for (final entry in skillsByCategory.entries) {
        final categoryData = skillsData.first['skill_categories'];
        _categories[entry.key] = SkillCategory(
          id: categoryData['id'],
          name: categoryData['name'],
          description: categoryData['description'],
          skills: entry.value,
          progress: categoryData['progress']?.toDouble() ?? 0.0,
        );
      }
    } catch (e) {
      debugPrint('Error initializing skill progress: $e');
    }
  }

  Future<void> updateVideoProgress(String videoId, double progress) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Update video progress
      await _supabase.from('video_progress').upsert({
        'user_id': user.id,
        'video_id': videoId,
        'progress': progress,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Update related skills
      final relatedSkills = await _supabase
          .from('video_skills')
          .select('skill_id')
          .eq('video_id', videoId);

      for (final skillData in relatedSkills) {
        final skillId = skillData['skill_id'];
        await _updateSkillProgress(skillId);
      }

      // Refresh data
      await initialize();
    } catch (e) {
      debugPrint('Error updating video progress: $e');
    }
  }

  Future<void> _updateSkillProgress(String skillId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Get all videos related to this skill
      final relatedVideos = await _supabase
          .from('video_skills')
          .select('video_id')
          .eq('skill_id', skillId);

      // Get progress for all related videos
      double totalProgress = 0;
      for (final videoData in relatedVideos) {
        final videoProgress = await _supabase
            .from('video_progress')
            .select('progress')
            .eq('video_id', videoData['video_id'])
            .eq('user_id', user.id)
            .single();

        totalProgress += videoProgress['progress'] ?? 0;
      }

      // Calculate average progress
      final averageProgress = totalProgress / relatedVideos.length;

      // Update skill progress
      await _supabase.from('skills').update({
        'progress': averageProgress,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', skillId);
    } catch (e) {
      debugPrint('Error updating skill progress: $e');
    }
  }

  List<SkillCategory> getAllCategories() {
    return _categories.values.toList();
  }

  Skill? getSkill(String skillId) {
    for (final category in _categories.values) {
      final skill = category.skills.firstWhere(
        (s) => s.id == skillId,
        orElse: () => null as Skill,
      );
      if (skill != null) return skill;
    }
    return null;
  }

  double getOverallProgress() {
    if (_categories.isEmpty) return 0.0;
    final totalProgress = _categories.values
        .map((c) => c.progress)
        .reduce((a, b) => a + b);
    return totalProgress / _categories.length;
  }
} 
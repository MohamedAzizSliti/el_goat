import 'package:flutter/material.dart';

class ChallengeStep {
  final String title;
  final String description;
  final String? videoUrl;
  final List<String> tips;
  final Map<String, dynamic> requirements;
  final List<String> equipment;

  ChallengeStep({
    required this.title,
    required this.description,
    this.videoUrl,
    required this.tips,
    required this.requirements,
    required this.equipment,
  });

  factory ChallengeStep.fromJson(Map<String, dynamic> json) {
    return ChallengeStep(
      title: json['title'],
      description: json['description'],
      videoUrl: json['video_url'],
      tips: List<String>.from(json['tips'] ?? []),
      requirements: Map<String, dynamic>.from(json['requirements'] ?? {}),
      equipment: List<String>.from(json['equipment'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'video_url': videoUrl,
      'tips': tips,
      'requirements': requirements,
      'equipment': equipment,
    };
  }
}

class ChallengeInstructions {
  final String challengeId;
  final List<ChallengeStep> steps;
  final Map<String, dynamic> prerequisites;
  final List<String> learningOutcomes;
  final int estimatedTimeMinutes;
  final String difficultyLevel;
  final List<String> requiredSkills;
  final Map<String, int> skillPointsReward;

  ChallengeInstructions({
    required this.challengeId,
    required this.steps,
    required this.prerequisites,
    required this.learningOutcomes,
    required this.estimatedTimeMinutes,
    required this.difficultyLevel,
    required this.requiredSkills,
    required this.skillPointsReward,
  });

  factory ChallengeInstructions.fromJson(Map<String, dynamic> json) {
    return ChallengeInstructions(
      challengeId: json['challenge_id'],
      steps: (json['steps'] as List).map((step) => ChallengeStep.fromJson(step)).toList(),
      prerequisites: Map<String, dynamic>.from(json['prerequisites'] ?? {}),
      learningOutcomes: List<String>.from(json['learning_outcomes'] ?? []),
      estimatedTimeMinutes: json['estimated_time_minutes'],
      difficultyLevel: json['difficulty_level'],
      requiredSkills: List<String>.from(json['required_skills'] ?? []),
      skillPointsReward: Map<String, int>.from(json['skill_points_reward'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'challenge_id': challengeId,
      'steps': steps.map((step) => step.toJson()).toList(),
      'prerequisites': prerequisites,
      'learning_outcomes': learningOutcomes,
      'estimated_time_minutes': estimatedTimeMinutes,
      'difficulty_level': difficultyLevel,
      'required_skills': requiredSkills,
      'skill_points_reward': skillPointsReward,
    };
  }
} 
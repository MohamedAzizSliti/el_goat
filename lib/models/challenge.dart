import 'package:flutter/material.dart';

enum ChallengeType {
  daily,
  weekly
}

enum ChallengeCategory {
  shooting,
  dribbling,
  passing,
  fitness,
  tactics
}

class Challenge {
  final String id;
  final String title;
  final String description;
  final ChallengeType type;
  final ChallengeCategory category;
  final int pointsReward;
  final DateTime startDate;
  final DateTime endDate;
  final int targetProgress;
  final int currentProgress;
  final bool isCompleted;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    required this.pointsReward,
    required this.startDate,
    required this.endDate,
    required this.targetProgress,
    this.currentProgress = 0,
    this.isCompleted = false,
  });

  double get progressPercentage => currentProgress / targetProgress;

  bool get isExpired => DateTime.now().isAfter(endDate);

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: ChallengeType.values.firstWhere(
        (e) => e.toString() == 'ChallengeType.${json['type']}'),
      category: ChallengeCategory.values.firstWhere(
        (e) => e.toString() == 'ChallengeCategory.${json['category']}'),
      pointsReward: json['points_reward'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      targetProgress: json['target_progress'],
      currentProgress: json['current_progress'] ?? 0,
      isCompleted: json['is_completed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'category': category.toString().split('.').last,
      'points_reward': pointsReward,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'target_progress': targetProgress,
      'current_progress': currentProgress,
      'is_completed': isCompleted,
    };
  }
} 
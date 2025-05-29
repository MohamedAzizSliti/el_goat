import 'package:flutter/material.dart';

class SkillCategory {
  final String id;
  final String name;
  final String description;
  final List<Skill> skills;
  final double progress;

  SkillCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.skills,
    required this.progress,
  });

  factory SkillCategory.fromJson(Map<String, dynamic> json) {
    return SkillCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      skills: (json['skills'] as List?)
          ?.map((skill) => Skill.fromJson(skill))
          .toList() ?? [],
      progress: json['progress']?.toDouble() ?? 0.0,
    );
  }
}

class Skill {
  final String id;
  final String name;
  final String description;
  final IconData? icon;
  final int currentLevel;
  final int maxLevel;
  final double progress;
  final List<String> relatedVideos;
  final Map<String, double> attributes;
  final Offset position;

  Skill({
    required this.id,
    required this.name,
    required this.description,
    this.icon,
    this.currentLevel = 1,
    this.maxLevel = 100,
    required this.progress,
    required this.relatedVideos,
    required this.attributes,
    required this.position,
  });

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      icon: json['icon_name'] != null ? IconData(int.parse(json['icon_name']), fontFamily: 'MaterialIcons') : null,
      currentLevel: json['current_level'] ?? 1,
      maxLevel: json['max_level'] ?? 100,
      progress: json['progress']?.toDouble() ?? 0.0,
      relatedVideos: List<String>.from(json['related_videos'] ?? []),
      attributes: Map<String, double>.from(json['attributes'] ?? {}),
      position: Offset(
        json['position_x']?.toDouble() ?? 0.0,
        json['position_y']?.toDouble() ?? 0.0,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'current_level': currentLevel,
      'max_level': maxLevel,
      'progress': progress,
      'related_videos': relatedVideos,
      'attributes': attributes,
      'position_x': position.dx,
      'position_y': position.dy,
    };
  }
} 
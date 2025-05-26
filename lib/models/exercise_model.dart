enum ExerciseStatus { pending, doing, done }

enum ExerciseType { technical, physical, tactical, mental }

enum ExerciseDifficulty { beginner, intermediate, advanced, professional }

class ExerciseModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String instructions;
  final ExerciseType type;
  final ExerciseDifficulty difficulty;
  final String targetPosition;
  final List<String> targetSkills;
  final int estimatedDuration; // in minutes
  final ExerciseStatus status;
  final int? score; // 0-100
  final String? feedback;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? metadata; // Additional AI-generated data

  ExerciseModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.instructions,
    required this.type,
    required this.difficulty,
    required this.targetPosition,
    required this.targetSkills,
    required this.estimatedDuration,
    required this.status,
    this.score,
    this.feedback,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.metadata,
  });

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      instructions: json['instructions']?.toString() ?? '',
      type: ExerciseType.values.firstWhere(
        (e) => e.name == json['type']?.toString(),
        orElse: () => ExerciseType.technical,
      ),
      difficulty: ExerciseDifficulty.values.firstWhere(
        (e) => e.name == json['difficulty']?.toString(),
        orElse: () => ExerciseDifficulty.beginner,
      ),
      targetPosition: json['target_position']?.toString() ?? '',
      targetSkills:
          json['target_skills'] != null
              ? List<String>.from(json['target_skills'] as List)
              : <String>[],
      estimatedDuration: (json['estimated_duration'] as num?)?.toInt() ?? 30,
      status: ExerciseStatus.values.firstWhere(
        (e) => e.name == json['status']?.toString(),
        orElse: () => ExerciseStatus.pending,
      ),
      score: (json['score'] as num?)?.toInt(),
      feedback: json['feedback']?.toString(),
      createdAt:
          json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString()) ??
                  DateTime.now()
              : DateTime.now(),
      startedAt:
          json['started_at'] != null
              ? DateTime.tryParse(json['started_at'].toString())
              : null,
      completedAt:
          json['completed_at'] != null
              ? DateTime.tryParse(json['completed_at'].toString())
              : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'instructions': instructions,
      'type': type.name,
      'difficulty': difficulty.name,
      'target_position': targetPosition,
      'target_skills': targetSkills,
      'estimated_duration': estimatedDuration,
      'status': status.name,
      'score': score,
      'feedback': feedback,
      'created_at': createdAt.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  ExerciseModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? instructions,
    ExerciseType? type,
    ExerciseDifficulty? difficulty,
    String? targetPosition,
    List<String>? targetSkills,
    int? estimatedDuration,
    ExerciseStatus? status,
    int? score,
    String? feedback,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    Map<String, dynamic>? metadata,
  }) {
    return ExerciseModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      instructions: instructions ?? this.instructions,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      targetPosition: targetPosition ?? this.targetPosition,
      targetSkills: targetSkills ?? this.targetSkills,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      status: status ?? this.status,
      score: score ?? this.score,
      feedback: feedback ?? this.feedback,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper methods
  String get statusDisplayName {
    switch (status) {
      case ExerciseStatus.pending:
        return 'Pending';
      case ExerciseStatus.doing:
        return 'In Progress';
      case ExerciseStatus.done:
        return 'Completed';
    }
  }

  String get typeDisplayName {
    switch (type) {
      case ExerciseType.technical:
        return 'Technical';
      case ExerciseType.physical:
        return 'Physical';
      case ExerciseType.tactical:
        return 'Tactical';
      case ExerciseType.mental:
        return 'Mental';
    }
  }

  String get difficultyDisplayName {
    switch (difficulty) {
      case ExerciseDifficulty.beginner:
        return 'Beginner';
      case ExerciseDifficulty.intermediate:
        return 'Intermediate';
      case ExerciseDifficulty.advanced:
        return 'Advanced';
      case ExerciseDifficulty.professional:
        return 'Professional';
    }
  }

  bool get isCompleted => status == ExerciseStatus.done;
  bool get isInProgress => status == ExerciseStatus.doing;
  bool get isPending => status == ExerciseStatus.pending;

  Duration? get timeSpent {
    if (startedAt == null) return null;
    final endTime = completedAt ?? DateTime.now();
    return endTime.difference(startedAt!);
  }
}

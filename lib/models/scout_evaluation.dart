enum RecommendationType {
  highlyRecommend,
  recommend,
  consider,
  notRecommend,
}

extension RecommendationTypeExtension on RecommendationType {
  String get value {
    switch (this) {
      case RecommendationType.highlyRecommend:
        return 'highly_recommend';
      case RecommendationType.recommend:
        return 'recommend';
      case RecommendationType.consider:
        return 'consider';
      case RecommendationType.notRecommend:
        return 'not_recommend';
    }
  }

  String get displayName {
    switch (this) {
      case RecommendationType.highlyRecommend:
        return 'Highly Recommend';
      case RecommendationType.recommend:
        return 'Recommend';
      case RecommendationType.consider:
        return 'Consider';
      case RecommendationType.notRecommend:
        return 'Not Recommend';
    }
  }

  static RecommendationType fromString(String value) {
    switch (value) {
      case 'highly_recommend':
        return RecommendationType.highlyRecommend;
      case 'recommend':
        return RecommendationType.recommend;
      case 'consider':
        return RecommendationType.consider;
      case 'not_recommend':
        return RecommendationType.notRecommend;
      default:
        return RecommendationType.consider;
    }
  }
}

class ScoutEvaluation {
  final String id;
  final String scoutId;
  final String playerId;
  final DateTime evaluationDate;
  final String? matchContext;
  final String playerPosition;

  // Technical Skills (1-10)
  final int ballControl;
  final int passingAccuracy;
  final int shootingAbility;
  final int dribblingSkills;
  final int crossingAbility;
  final int headingAbility;

  // Physical Attributes (1-10)
  final int speed;
  final int stamina;
  final int strength;
  final int agility;
  final int jumpingAbility;

  // Mental Attributes (1-10)
  final int decisionMaking;
  final int positioning;
  final int communication;
  final int leadership;
  final int workRate;
  final int attitude;

  // Overall Assessment
  final int overallRating;
  final int potentialRating;

  // Recommendations
  final RecommendationType recommendation;
  final String? strengths;
  final String? areasForImprovement;
  final String? additionalNotes;

  final DateTime createdAt;
  final DateTime? updatedAt;

  ScoutEvaluation({
    required this.id,
    required this.scoutId,
    required this.playerId,
    required this.evaluationDate,
    this.matchContext,
    required this.playerPosition,
    required this.ballControl,
    required this.passingAccuracy,
    required this.shootingAbility,
    required this.dribblingSkills,
    required this.crossingAbility,
    required this.headingAbility,
    required this.speed,
    required this.stamina,
    required this.strength,
    required this.agility,
    required this.jumpingAbility,
    required this.decisionMaking,
    required this.positioning,
    required this.communication,
    required this.leadership,
    required this.workRate,
    required this.attitude,
    required this.overallRating,
    required this.potentialRating,
    required this.recommendation,
    this.strengths,
    this.areasForImprovement,
    this.additionalNotes,
    required this.createdAt,
    this.updatedAt,
  });

  factory ScoutEvaluation.fromJson(Map<String, dynamic> json) {
    return ScoutEvaluation(
      id: json['id'] as String,
      scoutId: json['scout_id'] as String,
      playerId: json['player_id'] as String,
      evaluationDate: DateTime.parse(json['evaluation_date'] as String),
      matchContext: json['match_context'] as String?,
      playerPosition: json['player_position'] as String,
      ballControl: json['ball_control'] as int,
      passingAccuracy: json['passing_accuracy'] as int,
      shootingAbility: json['shooting_ability'] as int,
      dribblingSkills: json['dribbling_skills'] as int,
      crossingAbility: json['crossing_ability'] as int,
      headingAbility: json['heading_ability'] as int,
      speed: json['speed'] as int,
      stamina: json['stamina'] as int,
      strength: json['strength'] as int,
      agility: json['agility'] as int,
      jumpingAbility: json['jumping_ability'] as int,
      decisionMaking: json['decision_making'] as int,
      positioning: json['positioning'] as int,
      communication: json['communication'] as int,
      leadership: json['leadership'] as int,
      workRate: json['work_rate'] as int,
      attitude: json['attitude'] as int,
      overallRating: json['overall_rating'] as int,
      potentialRating: json['potential_rating'] as int,
      recommendation: RecommendationTypeExtension.fromString(json['recommendation'] as String),
      strengths: json['strengths'] as String?,
      areasForImprovement: json['areas_for_improvement'] as String?,
      additionalNotes: json['additional_notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scout_id': scoutId,
      'player_id': playerId,
      'evaluation_date': evaluationDate.toIso8601String().split('T')[0], // Date only
      'match_context': matchContext,
      'player_position': playerPosition,
      'ball_control': ballControl,
      'passing_accuracy': passingAccuracy,
      'shooting_ability': shootingAbility,
      'dribbling_skills': dribblingSkills,
      'crossing_ability': crossingAbility,
      'heading_ability': headingAbility,
      'speed': speed,
      'stamina': stamina,
      'strength': strength,
      'agility': agility,
      'jumping_ability': jumpingAbility,
      'decision_making': decisionMaking,
      'positioning': positioning,
      'communication': communication,
      'leadership': leadership,
      'work_rate': workRate,
      'attitude': attitude,
      'overall_rating': overallRating,
      'potential_rating': potentialRating,
      'recommendation': recommendation.value,
      'strengths': strengths,
      'areas_for_improvement': areasForImprovement,
      'additional_notes': additionalNotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Calculate average technical skills
  double get averageTechnicalSkills {
    return (ballControl + passingAccuracy + shootingAbility + 
            dribblingSkills + crossingAbility + headingAbility) / 6.0;
  }

  // Calculate average physical attributes
  double get averagePhysicalAttributes {
    return (speed + stamina + strength + agility + jumpingAbility) / 5.0;
  }

  // Calculate average mental attributes
  double get averageMentalAttributes {
    return (decisionMaking + positioning + communication + 
            leadership + workRate + attitude) / 6.0;
  }

  ScoutEvaluation copyWith({
    String? id,
    String? scoutId,
    String? playerId,
    DateTime? evaluationDate,
    String? matchContext,
    String? playerPosition,
    int? ballControl,
    int? passingAccuracy,
    int? shootingAbility,
    int? dribblingSkills,
    int? crossingAbility,
    int? headingAbility,
    int? speed,
    int? stamina,
    int? strength,
    int? agility,
    int? jumpingAbility,
    int? decisionMaking,
    int? positioning,
    int? communication,
    int? leadership,
    int? workRate,
    int? attitude,
    int? overallRating,
    int? potentialRating,
    RecommendationType? recommendation,
    String? strengths,
    String? areasForImprovement,
    String? additionalNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ScoutEvaluation(
      id: id ?? this.id,
      scoutId: scoutId ?? this.scoutId,
      playerId: playerId ?? this.playerId,
      evaluationDate: evaluationDate ?? this.evaluationDate,
      matchContext: matchContext ?? this.matchContext,
      playerPosition: playerPosition ?? this.playerPosition,
      ballControl: ballControl ?? this.ballControl,
      passingAccuracy: passingAccuracy ?? this.passingAccuracy,
      shootingAbility: shootingAbility ?? this.shootingAbility,
      dribblingSkills: dribblingSkills ?? this.dribblingSkills,
      crossingAbility: crossingAbility ?? this.crossingAbility,
      headingAbility: headingAbility ?? this.headingAbility,
      speed: speed ?? this.speed,
      stamina: stamina ?? this.stamina,
      strength: strength ?? this.strength,
      agility: agility ?? this.agility,
      jumpingAbility: jumpingAbility ?? this.jumpingAbility,
      decisionMaking: decisionMaking ?? this.decisionMaking,
      positioning: positioning ?? this.positioning,
      communication: communication ?? this.communication,
      leadership: leadership ?? this.leadership,
      workRate: workRate ?? this.workRate,
      attitude: attitude ?? this.attitude,
      overallRating: overallRating ?? this.overallRating,
      potentialRating: potentialRating ?? this.potentialRating,
      recommendation: recommendation ?? this.recommendation,
      strengths: strengths ?? this.strengths,
      areasForImprovement: areasForImprovement ?? this.areasForImprovement,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

import 'user_model.dart';

class FootballerProfileModel {
  final String userId;
  final String fullName;
  final DateTime dateOfBirth;
  final String nationality;
  final String position;
  final String preferredFoot;
  final double height;
  final double weight;
  final String? profileImage;
  final String? bio;
  final List<String> skills;
  final Map<String, dynamic>? statistics;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String experience;
  final String? club;

  FootballerProfileModel({
    required this.userId,
    required this.fullName,
    required this.dateOfBirth,
    required this.nationality,
    required this.position,
    required this.preferredFoot,
    required this.height,
    required this.weight,
    this.profileImage,
    this.bio,
    required this.skills,
    this.statistics,
    required this.createdAt,
    this.updatedAt,
    required this.experience,
    this.club,
  });

  factory FootballerProfileModel.fromJson(Map<String, dynamic> json) {
    return FootballerProfileModel(
      userId: json['user_id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? 'Unknown Player',
      dateOfBirth:
          json['dob'] != null || json['date_of_birth'] != null
              ? DateTime.tryParse(
                    (json['dob'] ?? json['date_of_birth']).toString(),
                  ) ??
                  DateTime(2000)
              : DateTime(2000),
      nationality: json['nationality']?.toString() ?? 'Unknown',
      position: json['position']?.toString() ?? 'Unknown',
      preferredFoot: json['preferred_foot']?.toString() ?? 'Right',
      height: (json['height_cm'] as num?)?.toDouble() ?? 175.0,
      weight: (json['weight_kg'] as num?)?.toDouble() ?? 70.0,
      profileImage: json['profile_image']?.toString(),
      bio: json['bio']?.toString(),
      skills:
          json['skills'] != null
              ? List<String>.from(json['skills'] as List)
              : <String>[],
      statistics: json['statistics'] as Map<String, dynamic>?,
      createdAt:
          json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString()) ??
                  DateTime.now()
              : DateTime.now(),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.tryParse(json['updated_at'].toString())
              : null,
      experience: json['experience_level']?.toString() ?? 'Beginner',
      club: json['current_club']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'date_of_birth': dateOfBirth.toIso8601String(),
      'nationality': nationality,
      'position': position,
      'preferred_foot': preferredFoot,
      'height': height,
      'weight': weight,
      'profile_image': profileImage,
      'bio': bio,
      'skills': skills,
      'statistics': statistics,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'experience_level': experience,
      'current_club': club,
    };
  }

  FootballerProfileModel copyWith({
    String? userId,
    String? fullName,
    DateTime? dateOfBirth,
    String? nationality,
    String? position,
    String? preferredFoot,
    double? height,
    double? weight,
    String? profileImage,
    String? bio,
    List<String>? skills,
    Map<String, dynamic>? statistics,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? experience,
    String? club,
  }) {
    return FootballerProfileModel(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      nationality: nationality ?? this.nationality,
      position: position ?? this.position,
      preferredFoot: preferredFoot ?? this.preferredFoot,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      profileImage: profileImage ?? this.profileImage,
      bio: bio ?? this.bio,
      skills: skills ?? this.skills,
      statistics: statistics ?? this.statistics,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      experience: experience ?? this.experience,
      club: club ?? this.club,
    );
  }
}

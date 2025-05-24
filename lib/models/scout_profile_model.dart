import 'user_model.dart';

class ScoutProfileModel {
  final String userId;
  final String fullName;
  final String organization;
  final String specialization;
  final List<String> regions;
  final String? profileImage;
  final String? bio;
  final Map<String, dynamic>? credentials;
  final List<String>? certifications;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ScoutProfileModel({
    required this.userId,
    required this.fullName,
    required this.organization,
    required this.specialization,
    required this.regions,
    this.profileImage,
    this.bio,
    this.credentials,
    this.certifications,
    required this.createdAt,
    this.updatedAt,
  });

  factory ScoutProfileModel.fromJson(Map<String, dynamic> json) {
    return ScoutProfileModel(
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String,
      organization: json['organization'] as String,
      specialization: json['specialization'] as String,
      regions: List<String>.from(json['regions'] as List),
      profileImage: json['profile_image'] as String?,
      bio: json['bio'] as String?,
      credentials: json['credentials'] as Map<String, dynamic>?,
      certifications:
          json['certifications'] != null
              ? List<String>.from(json['certifications'] as List)
              : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'organization': organization,
      'specialization': specialization,
      'regions': regions,
      'profile_image': profileImage,
      'bio': bio,
      'credentials': credentials,
      'certifications': certifications,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  ScoutProfileModel copyWith({
    String? userId,
    String? fullName,
    String? organization,
    String? specialization,
    List<String>? regions,
    String? profileImage,
    String? bio,
    Map<String, dynamic>? credentials,
    List<String>? certifications,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ScoutProfileModel(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      organization: organization ?? this.organization,
      specialization: specialization ?? this.specialization,
      regions: regions ?? this.regions,
      profileImage: profileImage ?? this.profileImage,
      bio: bio ?? this.bio,
      credentials: credentials ?? this.credentials,
      certifications: certifications ?? this.certifications,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

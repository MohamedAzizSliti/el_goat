import 'user_model.dart';

class ClubProfileModel {
  final String userId;
  final String fullName;
  final String clubType;
  final String country;
  final String city;
  final String? logo;
  final String? website;
  final String? bio;
  final Map<String, dynamic>? contactInfo;
  final List<String>? facilities;
  final Map<String, dynamic>? achievements;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ClubProfileModel({
    required this.userId,
    required this.fullName,
    required this.clubType,
    required this.country,
    required this.city,
    this.logo,
    this.website,
    this.bio,
    this.contactInfo,
    this.facilities,
    this.achievements,
    required this.createdAt,
    this.updatedAt,
  });

  factory ClubProfileModel.fromJson(Map<String, dynamic> json) {
    return ClubProfileModel(
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String,
      clubType: json['club_type'] as String,
      country: json['country'] as String,
      city: json['city'] as String,
      logo: json['logo'] as String?,
      website: json['website'] as String?,
      bio: json['bio'] as String?,
      contactInfo: json['contact_info'] as Map<String, dynamic>?,
      facilities:
          json['facilities'] != null
              ? List<String>.from(json['facilities'] as List)
              : null,
      achievements: json['achievements'] as Map<String, dynamic>?,
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
      'club_type': clubType,
      'country': country,
      'city': city,
      'logo': logo,
      'website': website,
      'bio': bio,
      'contact_info': contactInfo,
      'facilities': facilities,
      'achievements': achievements,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  ClubProfileModel copyWith({
    String? userId,
    String? fullName,
    String? clubType,
    String? country,
    String? city,
    String? logo,
    String? website,
    String? bio,
    Map<String, dynamic>? contactInfo,
    List<String>? facilities,
    Map<String, dynamic>? achievements,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClubProfileModel(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      clubType: clubType ?? this.clubType,
      country: country ?? this.country,
      city: city ?? this.city,
      logo: logo ?? this.logo,
      website: website ?? this.website,
      bio: bio ?? this.bio,
      contactInfo: contactInfo ?? this.contactInfo,
      facilities: facilities ?? this.facilities,
      achievements: achievements ?? this.achievements,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

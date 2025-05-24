// lib/models/scout_profile.dart

class ScoutProfile {
  final String userId;
  final String fullName;
  final String? phone;
  final String? country;
  final String? city;
  final String? scoutingLevel;
  final int yearsExperience;
  final String? bio;
  final String? avatarUrl;
  final String? organization;
  final List<String> specializations;
  final bool isVerified;
  final DateTime? lastSeen;
  final DateTime? createdAt;

  ScoutProfile({
    required this.userId,
    required this.fullName,
    this.phone,
    this.country,
    this.city,
    this.scoutingLevel,
    this.yearsExperience = 0,
    this.bio,
    this.avatarUrl,
    this.organization,
    this.specializations = const [],
    this.isVerified = false,
    this.lastSeen,
    this.createdAt,
  });

  factory ScoutProfile.fromJson(Map<String, dynamic> json) {
    return ScoutProfile(
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      country: json['country'] as String?,
      city: json['city'] as String?,
      scoutingLevel: json['scouting_level'] as String?,
      yearsExperience: json['years_experience'] as int? ?? 0,
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      organization: json['organization'] as String?,
      specializations: json['specializations'] != null 
          ? List<String>.from(json['specializations'] as List)
          : [],
      isVerified: json['is_verified'] as bool? ?? false,
      lastSeen: json['last_seen'] != null 
          ? DateTime.parse(json['last_seen'] as String)
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'phone': phone,
      'country': country,
      'city': city,
      'scouting_level': scoutingLevel,
      'years_experience': yearsExperience,
      'bio': bio,
      'avatar_url': avatarUrl,
      'organization': organization,
      'specializations': specializations,
      'is_verified': isVerified,
      'last_seen': lastSeen?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
    };
  }

  String get locationDisplay {
    if (city != null && country != null) {
      return '$city, $country';
    } else if (country != null) {
      return country!;
    } else if (city != null) {
      return city!;
    }
    return 'Location not specified';
  }

  String get experienceDisplay {
    if (yearsExperience == 0) return 'New Scout';
    if (yearsExperience == 1) return '1 year experience';
    return '$yearsExperience years experience';
  }

  String get levelDisplay => scoutingLevel ?? 'Not specified';
}

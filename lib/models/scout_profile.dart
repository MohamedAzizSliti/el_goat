// lib/models/scout_profile.dart

class ScoutProfile {
  final String id;
  final String userId;
  final String fullName;
  final String? email;
  final String? phone;
  final String? country;
  final String? city;
  final String? scoutingLevel;
  final int experienceYears;
  final String? bio;
  final List<String> preferredPositions;
  final DateTime? lastSeen;
  final DateTime? createdAt;

  ScoutProfile({
    required this.id,
    required this.userId,
    required this.fullName,
    this.email,
    this.phone,
    this.country,
    this.city,
    this.scoutingLevel,
    this.experienceYears = 0,
    this.bio,
    this.preferredPositions = const [],
    this.lastSeen,
    this.createdAt,
  });

  factory ScoutProfile.fromJson(Map<String, dynamic> json) {
    return ScoutProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      country: json['country'] as String?,
      city: json['city'] as String?,
      scoutingLevel: json['scouting_level'] as String?,
      experienceYears: (json['experience_years'] as num?)?.toInt() ?? 0,
      bio: json['bio'] as String?,
      preferredPositions:
          json['preferred_positions'] != null
              ? List<String>.from(json['preferred_positions'] as List)
              : [],
      lastSeen:
          json['last_seen'] != null
              ? DateTime.parse(json['last_seen'] as String)
              : null,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'country': country,
      'city': city,
      'scouting_level': scoutingLevel,
      'experience_years': experienceYears,
      'bio': bio,
      'preferred_positions': preferredPositions,
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
    if (experienceYears == 0) return 'New Scout';
    if (experienceYears == 1) return '1 year experience';
    return '$experienceYears years experience';
  }

  String get levelDisplay => scoutingLevel ?? 'Not specified';

  // Compatibility getters for existing UI code
  String? get avatarUrl => null;
  bool get isVerified => false;
  String? get organization => null;
  List<String> get specializations => preferredPositions;
}

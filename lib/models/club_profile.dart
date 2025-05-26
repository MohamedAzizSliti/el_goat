// lib/models/club_profile.dart

class ClubProfile {
  final String userId;
  final String clubName;
  final String? email;
  final String? location;
  final String? website;
  final String? description;
  final String? logoUrl;
  final String? league;
  final String? division;
  final int? foundedYear;
  final String? stadium;
  final int? capacity;
  final List<String> achievements;
  final bool isVerified;
  final DateTime? createdAt;

  ClubProfile({
    required this.userId,
    required this.clubName,
    this.email,
    this.location,
    this.website,
    this.description,
    this.logoUrl,
    this.league,
    this.division,
    this.foundedYear,
    this.stadium,
    this.capacity,
    this.achievements = const [],
    this.isVerified = false,
    this.createdAt,
  });

  factory ClubProfile.fromJson(Map<String, dynamic> json) {
    return ClubProfile(
      userId: json['user_id'] as String,
      clubName: json['club_name'] as String,
      email: json['email'] as String?,
      location: json['location'] as String?,
      website: json['website'] as String?,
      description: json['description'] as String?,
      logoUrl: json['logo_url'] as String?,
      league: json['league'] as String?,
      division: json['division'] as String?,
      foundedYear: (json['founded_year'] as num?)?.toInt(),
      stadium: json['stadium'] as String?,
      capacity: (json['capacity'] as num?)?.toInt(),
      achievements:
          json['achievements'] != null
              ? List<String>.from(json['achievements'] as List)
              : [],
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'club_name': clubName,
      'email': email,
      'location': location,
      'website': website,
      'description': description,
      'logo_url': logoUrl,
      'league': league,
      'division': division,
      'founded_year': foundedYear,
      'stadium': stadium,
      'capacity': capacity,
      'achievements': achievements,
      'is_verified': isVerified,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  String get foundedDisplay {
    if (foundedYear == null) return 'Founded year not specified';
    return 'Founded in $foundedYear';
  }

  String get leagueDisplay {
    if (league != null && division != null) {
      return '$league - $division';
    } else if (league != null) {
      return league!;
    }
    return 'League not specified';
  }

  String get stadiumDisplay {
    if (stadium != null && capacity != null) {
      return '$stadium (${capacity!.toString()} capacity)';
    } else if (stadium != null) {
      return stadium!;
    }
    return 'Stadium not specified';
  }
}

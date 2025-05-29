// lib/models/club_profile.dart

class ClubProfile {
  final String id;
  final String userId;
  final String clubName;
  final String? location;
  final String? website;
  final String? description;
  final DateTime? createdAt;
  final DateTime? lastSeen;

  ClubProfile({
    required this.id,
    required this.userId,
    required this.clubName,
    this.location,
    this.website,
    this.description,
    this.createdAt,
    this.lastSeen,
  });

  factory ClubProfile.fromJson(Map<String, dynamic> json) {
    return ClubProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      clubName: json['club_name'] as String,
      location: json['location'] as String?,
      website: json['website'] as String?,
      description: json['description'] as String?,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : null,
      lastSeen:
          json['last_seen'] != null
              ? DateTime.parse(json['last_seen'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'club_name': clubName,
      'location': location,
      'website': website,
      'description': description,
      'created_at': createdAt?.toIso8601String(),
      'last_seen': lastSeen?.toIso8601String(),
    };
  }

  String get locationDisplay => location ?? 'Location not specified';

  // Compatibility getters for existing UI code
  String get leagueDisplay => 'League not specified';
  String get foundedDisplay => 'Founded year not specified';
  String get stadiumDisplay => 'Stadium not specified';
  String get countryDisplay => 'Country not specified';

  // Compatibility properties for existing UI code
  String? get logoUrl => null;
  bool get isVerified => false;
  List<String> get achievements => [];
}

// lib/models/footballer_profile.dart

class FootballerProfile {
  final String userId;
  final String fullName;
  final String? phone;
  final DateTime? dateOfBirth;
  final String? position;
  final String? preferredFoot;
  final int? heightCm;
  final int? weightKg;
  final String? experienceLevel;
  final String? currentClub;
  final String? avatarUrl;
  final String? bio;
  final int xpPoints;
  final bool isVerified;
  final DateTime? lastSeen;
  final DateTime? createdAt;

  FootballerProfile({
    required this.userId,
    required this.fullName,
    this.phone,
    this.dateOfBirth,
    this.position,
    this.preferredFoot,
    this.heightCm,
    this.weightKg,
    this.experienceLevel,
    this.currentClub,
    this.avatarUrl,
    this.bio,
    this.xpPoints = 0,
    this.isVerified = false,
    this.lastSeen,
    this.createdAt,
  });

  factory FootballerProfile.fromJson(Map<String, dynamic> json) {
    return FootballerProfile(
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      dateOfBirth: json['dob'] != null 
          ? DateTime.parse(json['dob'] as String)
          : null,
      position: json['position'] as String?,
      preferredFoot: json['preferred_foot'] as String?,
      heightCm: json['height_cm'] as int?,
      weightKg: json['weight_kg'] as int?,
      experienceLevel: json['experience_level'] as String?,
      currentClub: json['current_club'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      xpPoints: json['xp_points'] as int? ?? 0,
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
      'dob': dateOfBirth?.toIso8601String().split('T')[0],
      'position': position,
      'preferred_foot': preferredFoot,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'experience_level': experienceLevel,
      'current_club': currentClub,
      'avatar_url': avatarUrl,
      'bio': bio,
      'xp_points': xpPoints,
      'is_verified': isVerified,
      'last_seen': lastSeen?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
    };
  }

  int get age {
    if (dateOfBirth == null) return 0;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month || 
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  String get displayClub => currentClub?.isEmpty == true ? 'Free Agent' : currentClub ?? 'Free Agent';
  
  String get experienceDisplay => experienceLevel ?? 'Not specified';
  
  String get positionDisplay => position ?? 'Not specified';
}

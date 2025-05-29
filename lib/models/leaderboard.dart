enum LeaderboardType {
  global,
  weekly,
  monthly,
  skillSpecific
}

class LeaderboardEntry {
  final String userId;
  final String username;
  final String? avatarUrl;
  final int rank;
  final int points;
  final Map<String, int> skillLevels;
  final List<String> badges;

  LeaderboardEntry({
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.rank,
    required this.points,
    required this.skillLevels,
    required this.badges,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['user_id'],
      username: json['username'],
      avatarUrl: json['avatar_url'],
      rank: json['rank'],
      points: json['points'],
      skillLevels: Map<String, int>.from(json['skill_levels']),
      badges: List<String>.from(json['badges']),
    );
  }
}

class Leaderboard {
  final LeaderboardType type;
  final String? skillId;
  final DateTime lastUpdated;
  final List<LeaderboardEntry> entries;

  Leaderboard({
    required this.type,
    this.skillId,
    required this.lastUpdated,
    required this.entries,
  });

  factory Leaderboard.fromJson(Map<String, dynamic> json) {
    return Leaderboard(
      type: LeaderboardType.values.firstWhere(
        (e) => e.toString() == 'LeaderboardType.${json['type']}'),
      skillId: json['skill_id'],
      lastUpdated: DateTime.parse(json['last_updated']),
      entries: (json['entries'] as List)
          .map((entry) => LeaderboardEntry.fromJson(entry))
          .toList(),
    );
  }
} 
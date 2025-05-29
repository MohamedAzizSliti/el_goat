class Playlist {
  final String id;
  final String name;
  final String description;
  final String createdBy;
  final DateTime createdAt;
  final List<String> videoUrls;
  final List<String> tags;
  final bool isPublic;
  final int viewCount;
  final int likeCount;

  Playlist({
    required this.id,
    required this.name,
    required this.description,
    required this.createdBy,
    required this.createdAt,
    required this.videoUrls,
    required this.tags,
    this.isPublic = true,
    this.viewCount = 0,
    this.likeCount = 0,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
      videoUrls: List<String>.from(json['video_urls']),
      tags: List<String>.from(json['tags']),
      isPublic: json['is_public'] ?? true,
      viewCount: json['view_count'] ?? 0,
      likeCount: json['like_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'video_urls': videoUrls,
      'tags': tags,
      'is_public': isPublic,
      'view_count': viewCount,
      'like_count': likeCount,
    };
  }
} 
class AppProfile {
  final String id;
  final String username;
  final String? avatarUrl;
  final DateTime createdAt;
  /// Popularity from gifts received on posts (see `gifts_popularity.sql`).
  final int popularityPoints;

  AppProfile({
    required this.id,
    required this.username,
    this.avatarUrl,
    required this.createdAt,
    this.popularityPoints = 0,
  });

  factory AppProfile.fromJson(Map<String, dynamic> json) {
    return AppProfile(
      id: json['id'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      popularityPoints: (json['popularity_points'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'popularity_points': popularityPoints,
    };
  }

  AppProfile copyWith({
    String? id,
    String? username,
    String? avatarUrl,
    DateTime? createdAt,
    int? popularityPoints,
  }) {
    return AppProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      popularityPoints: popularityPoints ?? this.popularityPoints,
    );
  }
}

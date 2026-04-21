import 'app_post.dart';
import 'app_profile.dart';

class SharedPost {
  final String shareId;
  final String userId;
  final String originalPostId;
  final String? shareText;
  final DateTime createdAt;
  final AppProfile? profile;
  final AppPost? originalPost;

  SharedPost({
    required this.shareId,
    required this.userId,
    required this.originalPostId,
    this.shareText,
    required this.createdAt,
    this.profile,
    this.originalPost,
  });

  factory SharedPost.fromJson(Map<String, dynamic> json) {
    return SharedPost(
      shareId: json['share_id'] as String,
      userId: json['user_id'] as String,
      originalPostId: json['original_post_id'] as String,
      shareText: json['share_text'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      profile: json['profiles'] != null
          ? AppProfile.fromJson(json['profiles'] as Map<String, dynamic>)
          : null,
      originalPost: json['original_post'] != null
          ? AppPost.fromJson(json['original_post'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'share_id': shareId,
      'user_id': userId,
      'original_post_id': originalPostId,
      'share_text': shareText,
      'created_at': createdAt.toIso8601String(),
      if (profile != null) 'profiles': profile!.toJson(),
      if (originalPost != null) 'original_post': originalPost!.toJson(),
    };
  }
}

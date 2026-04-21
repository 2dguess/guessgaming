import 'app_profile.dart';

class AppPost {
  /// PostgREST / JSON may return counts as [int], [num], or occasionally [String].
  static int readIntColumn(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.round();
    return int.tryParse(v.toString()) ?? fallback;
  }

  final String postId;
  final String userId;
  final String content;
  final String? imageUrl;
  final int likesCount;
  final int commentsCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool likedByMe;
  final AppProfile? profile;
  /// Sum of `gift_items.popularity_points` for gifts on this post only.
  final int giftPopularityOnPost;
  /// Number of gift sends on this post.
  final int giftCountOnPost;

  AppPost({
    required this.postId,
    required this.userId,
    required this.content,
    this.imageUrl,
    required this.likesCount,
    required this.commentsCount,
    required this.createdAt,
    required this.updatedAt,
    this.likedByMe = false,
    this.profile,
    this.giftPopularityOnPost = 0,
    this.giftCountOnPost = 0,
  });

  bool get hasGiftActivity => giftPopularityOnPost > 0 || giftCountOnPost > 0;

  factory AppPost.fromJson(Map<String, dynamic> json) {
    return AppPost(
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      imageUrl: json['image_url'] as String?,
      likesCount: readIntColumn(json['likes_count']),
      commentsCount: readIntColumn(json['comments_count']),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      likedByMe: json['liked_by_me'] as bool? ?? false,
      profile: json['profiles'] != null 
          ? AppProfile.fromJson(json['profiles'] as Map<String, dynamic>)
          : null,
      giftPopularityOnPost: readIntColumn(json['gift_popularity_on_post']),
      giftCountOnPost: readIntColumn(json['gift_count_on_post']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'post_id': postId,
      'user_id': userId,
      'content': content,
      'image_url': imageUrl,
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'liked_by_me': likedByMe,
      if (profile != null) 'profiles': profile!.toJson(),
      'gift_popularity_on_post': giftPopularityOnPost,
      'gift_count_on_post': giftCountOnPost,
    };
  }

  /// Text safe to show (strips image-only DB placeholder characters).
  String get visibleContent {
    return content
        .replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '')
        .trim();
  }

  AppPost copyWith({
    String? postId,
    String? userId,
    String? content,
    String? imageUrl,
    int? likesCount,
    int? commentsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? likedByMe,
    AppProfile? profile,
    int? giftPopularityOnPost,
    int? giftCountOnPost,
  }) {
    return AppPost(
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likedByMe: likedByMe ?? this.likedByMe,
      profile: profile ?? this.profile,
      giftPopularityOnPost: giftPopularityOnPost ?? this.giftPopularityOnPost,
      giftCountOnPost: giftCountOnPost ?? this.giftCountOnPost,
    );
  }
}

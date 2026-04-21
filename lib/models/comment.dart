import 'app_profile.dart';

class Comment {
  final String commentId;
  final String postId;
  final String userId;
  final String? parentCommentId;
  final String content;
  final DateTime createdAt;
  final AppProfile? profile;
  final List<Comment> replies;
  final int likesCount;
  /// Filled client-side from `comment_likes` for the current user.
  final bool likedByMe;

  Comment({
    required this.commentId,
    required this.postId,
    required this.userId,
    this.parentCommentId,
    required this.content,
    required this.createdAt,
    this.profile,
    this.replies = const [],
    this.likesCount = 0,
    this.likedByMe = false,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      commentId: json['comment_id'] as String,
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      parentCommentId: json['parent_comment_id'] as String?,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      profile: json['profiles'] != null
          ? AppProfile.fromJson(json['profiles'] as Map<String, dynamic>)
          : null,
      replies: [],
      likesCount: json['likes_count'] as int? ?? 0,
      likedByMe: json['liked_by_me'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'comment_id': commentId,
      'post_id': postId,
      'user_id': userId,
      'parent_comment_id': parentCommentId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      if (profile != null) 'profiles': profile!.toJson(),
      'likes_count': likesCount,
    };
  }

  Comment copyWith({
    String? commentId,
    String? postId,
    String? userId,
    String? parentCommentId,
    String? content,
    DateTime? createdAt,
    AppProfile? profile,
    List<Comment>? replies,
    int? likesCount,
    bool? likedByMe,
  }) {
    return Comment(
      commentId: commentId ?? this.commentId,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      profile: profile ?? this.profile,
      replies: replies ?? this.replies,
      likesCount: likesCount ?? this.likesCount,
      likedByMe: likedByMe ?? this.likedByMe,
    );
  }
}

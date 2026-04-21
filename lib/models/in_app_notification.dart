class InAppNotificationItem {
  final String id;
  final String actorUsername;
  final String type;
  final DateTime createdAt;
  final String? postId;
  final String? commentId;

  InAppNotificationItem({
    required this.id,
    required this.actorUsername,
    required this.type,
    required this.createdAt,
    this.postId,
    this.commentId,
  });

  factory InAppNotificationItem.fromRow(
    Map<String, dynamic> r,
    Map<String, String> actorUsernames,
  ) {
    return InAppNotificationItem(
      id: r['id'] as String,
      actorUsername: actorUsernames[r['actor_id'] as String] ?? 'Someone',
      type: r['type'] as String,
      createdAt: DateTime.parse(r['created_at'] as String),
      postId: r['post_id'] as String?,
      commentId: r['comment_id'] as String?,
    );
  }

  String get actionLabel {
    switch (type) {
      case 'post_like':
        return 'liked your post';
      case 'comment':
        return 'commented on your post';
      case 'reply':
        return 'replied to your comment';
      case 'follow':
        return 'started following you';
      default:
        return 'sent you an update';
    }
  }

  IconKind get iconKind {
    switch (type) {
      case 'post_like':
        return IconKind.like;
      case 'comment':
      case 'reply':
        return IconKind.comment;
      case 'follow':
        return IconKind.follow;
      default:
        return IconKind.comment;
    }
  }
}

enum IconKind { like, comment, follow }

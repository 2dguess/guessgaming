/// Per-post gift aggregates (only gifts on this post).
class PostGiftTotals {
  const PostGiftTotals({
    required this.totalPopularity,
    required this.giftCount,
  });

  final int totalPopularity;
  final int giftCount;
}

/// One row when post owner views who sent gifts (RPC `list_post_gifts_for_owner`).
class PostGiftSenderLine {
  const PostGiftSenderLine({
    required this.createdAt,
    required this.senderId,
    required this.senderUsername,
    this.senderAvatarUrl,
    required this.giftKind,
    required this.giftTitle,
    required this.popularityPoints,
  });

  final DateTime createdAt;
  final String senderId;
  final String senderUsername;
  final String? senderAvatarUrl;
  final String giftKind;
  final String giftTitle;
  final int popularityPoints;

  factory PostGiftSenderLine.fromJson(Map<String, dynamic> json) {
    return PostGiftSenderLine(
      createdAt: DateTime.parse(json['created_at'] as String),
      senderId: json['sender_id'] as String,
      senderUsername: json['sender_username'] as String? ?? '?',
      senderAvatarUrl: json['sender_avatar_url'] as String?,
      giftKind: json['gift_kind'] as String? ?? '',
      giftTitle: json['gift_title'] as String? ?? '',
      popularityPoints: (json['popularity_points'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Gifts received on your posts, grouped by catalog item (gift shop footer).
class UserReceivedGiftLine {
  const UserReceivedGiftLine({
    required this.giftItemId,
    required this.kind,
    required this.title,
    required this.giftCount,
    required this.totalPopularity,
  });

  final String giftItemId;
  final String kind;
  final String title;
  final int giftCount;
  final int totalPopularity;

  factory UserReceivedGiftLine.fromRow(Map<String, dynamic> json) {
    return UserReceivedGiftLine(
      giftItemId: json['gift_item_id'] as String,
      kind: json['kind'] as String? ?? '',
      title: json['title'] as String? ?? '',
      giftCount: (json['gift_count'] as num?)?.toInt() ?? 0,
      totalPopularity: (json['total_popularity'] as num?)?.toInt() ?? 0,
    );
  }
}

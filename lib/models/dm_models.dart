import 'app_profile.dart';

class DmThreadPreview {
  final String threadId;
  final String otherUserId;
  final AppProfile? otherProfile;
  final String? lastMessagePreview;
  final DateTime? lastMessageAt;
  /// Inbound messages from the other person that are still after our read cursor.
  final int unreadInboundCount;

  const DmThreadPreview({
    required this.threadId,
    required this.otherUserId,
    this.otherProfile,
    this.lastMessagePreview,
    this.lastMessageAt,
    this.unreadInboundCount = 0,
  });

  bool get hasUnreadFromOther => unreadInboundCount > 0;

  DmThreadPreview copyWith({
    String? threadId,
    String? otherUserId,
    AppProfile? otherProfile,
    String? lastMessagePreview,
    DateTime? lastMessageAt,
    int? unreadInboundCount,
  }) {
    return DmThreadPreview(
      threadId: threadId ?? this.threadId,
      otherUserId: otherUserId ?? this.otherUserId,
      otherProfile: otherProfile ?? this.otherProfile,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadInboundCount: unreadInboundCount ?? this.unreadInboundCount,
    );
  }
}

class DmThreadReadState {
  final String threadId;
  final String userA;
  final String userB;
  final DateTime? userALastReadAt;
  final DateTime? userBLastReadAt;

  const DmThreadReadState({
    required this.threadId,
    required this.userA,
    required this.userB,
    this.userALastReadAt,
    this.userBLastReadAt,
  });

  /// Other participant's last read time (used for "Seen" on our outgoing messages).
  DateTime? peerLastReadAtFor(String me) {
    if (me == userA) return userBLastReadAt;
    if (me == userB) return userALastReadAt;
    return null;
  }
}

class DmMessage {
  final String id;
  final String threadId;
  final String senderId;
  final String body;
  final DateTime createdAt;
  final int likesCount;
  final bool likedByMe;

  const DmMessage({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.body,
    required this.createdAt,
    this.likesCount = 0,
    this.likedByMe = false,
  });

  DmMessage copyWith({
    String? id,
    String? threadId,
    String? senderId,
    String? body,
    DateTime? createdAt,
    int? likesCount,
    bool? likedByMe,
  }) {
    return DmMessage(
      id: id ?? this.id,
      threadId: threadId ?? this.threadId,
      senderId: senderId ?? this.senderId,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      likesCount: likesCount ?? this.likesCount,
      likedByMe: likedByMe ?? this.likedByMe,
    );
  }

  factory DmMessage.fromJson(Map<String, dynamic> json) {
    return DmMessage(
      id: json['id'] as String,
      threadId: json['thread_id'] as String,
      senderId: json['sender_id'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      likedByMe: json['liked_by_me'] as bool? ?? false,
    );
  }
}

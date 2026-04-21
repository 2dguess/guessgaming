class Mission {
  final String missionId;
  final String title;
  final String? description;
  final int rewardAmount;
  final String frequency;
  final String missionType;
  final String? actionLink;
  final String? platform;
  final String? missionKind;
  final String? missionAction;
  final DateTime createdAt;

  Mission({
    required this.missionId,
    required this.title,
    this.description,
    required this.rewardAmount,
    required this.frequency,
    required this.missionType,
    this.actionLink,
    this.platform,
    this.missionKind,
    this.missionAction,
    required this.createdAt,
  });

  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      missionId: json['mission_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      rewardAmount:
          (json['reward_coin'] as num?)?.toInt() ?? (json['reward_amount'] as int),
      frequency: json['frequency'] as String,
      missionType: (json['mission_type'] as String?) ?? 'custom',
      actionLink: json['action_link'] as String?,
      platform: json['platform'] as String?,
      missionKind: json['mission_kind'] as String?,
      missionAction: json['mission_action'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mission_id': missionId,
      'title': title,
      'description': description,
      'reward_amount': rewardAmount,
      'frequency': frequency,
      'mission_type': missionType,
      'action_link': actionLink,
      'platform': platform,
      'mission_kind': missionKind,
      'mission_action': missionAction,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class UserMission {
  final String id;
  final String userId;
  final String missionId;
  final DateTime lastClaimedAt;
  final Mission? mission;

  UserMission({
    required this.id,
    required this.userId,
    required this.missionId,
    required this.lastClaimedAt,
    this.mission,
  });

  factory UserMission.fromJson(Map<String, dynamic> json) {
    return UserMission(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      missionId: json['mission_id'] as String,
      lastClaimedAt: DateTime.parse(json['last_claimed_at'] as String),
      mission: json['missions'] != null
          ? Mission.fromJson(json['missions'] as Map<String, dynamic>)
          : null,
    );
  }

  bool canClaim() {
    final now = DateTime.now();
    final diff = now.difference(lastClaimedAt);
    return diff.inHours >= 24;
  }

  Duration timeUntilNextClaim() {
    final nextClaimTime = lastClaimedAt.add(const Duration(hours: 24));
    final now = DateTime.now();
    return nextClaimTime.difference(now);
  }
}

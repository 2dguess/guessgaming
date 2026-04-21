import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileLeaderboardBadges {
  final int? scoreRank;
  final int? matchRank;
  final bool scoreTop10;
  final bool matchTop10;

  const ProfileLeaderboardBadges({
    this.scoreRank,
    this.matchRank,
    this.scoreTop10 = false,
    this.matchTop10 = false,
  });

  factory ProfileLeaderboardBadges.fromJson(Map<String, dynamic> json) {
    return ProfileLeaderboardBadges(
      scoreRank: json['score_rank'] as int?,
      matchRank: json['match_rank'] as int?,
      scoreTop10: json['score_top10'] as bool? ?? false,
      matchTop10: json['match_top10'] as bool? ?? false,
    );
  }

  bool get hasAnyBadge => scoreTop10 || matchTop10;
}

final profileLeaderboardBadgesProvider =
    FutureProvider.family<ProfileLeaderboardBadges, String>((ref, userId) async {
  final client = Supabase.instance.client;
  final res = await client.rpc(
    'get_profile_leaderboard_badges',
    params: {'p_user_id': userId},
  );
  if (res == null) {
    return const ProfileLeaderboardBadges();
  }
  return ProfileLeaderboardBadges.fromJson(Map<String, dynamic>.from(res as Map));
});

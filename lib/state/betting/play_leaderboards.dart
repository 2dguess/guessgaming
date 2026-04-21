import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PlayLeaderboardEntry {
  final int rank;
  final String userId;
  final String username;
  final String? avatarUrl;
  final int value;

  const PlayLeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.value,
  });

  factory PlayLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return PlayLeaderboardEntry(
      rank: json['rank'] as int,
      userId: json['user_id'] as String,
      username: json['username'] as String? ?? '?',
      avatarUrl: json['avatar_url'] as String?,
      value: (json['value'] as num?)?.toInt() ?? 0,
    );
  }
}

class PlayLeaderboards {
  final List<PlayLeaderboardEntry> byScore;
  final List<PlayLeaderboardEntry> byBestMatch;

  const PlayLeaderboards({
    required this.byScore,
    required this.byBestMatch,
  });

  factory PlayLeaderboards.fromJson(Map<String, dynamic> json) {
    List<PlayLeaderboardEntry> parseList(dynamic raw) {
      if (raw == null) return [];
      final list = raw as List<dynamic>;
      return list
          .map((e) => PlayLeaderboardEntry.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList();
    }

    return PlayLeaderboards(
      byScore: parseList(json['by_score']),
      byBestMatch: parseList(json['by_best_match']),
    );
  }
}

final playLeaderboardsProvider = FutureProvider<PlayLeaderboards>((ref) async {
  final res = await Supabase.instance.client.rpc(
    'get_play_leaderboards',
    params: {'p_limit': 10},
  );
  if (res == null) {
    return const PlayLeaderboards(byScore: [], byBestMatch: []);
  }
  return PlayLeaderboards.fromJson(Map<String, dynamic>.from(res as Map));
});

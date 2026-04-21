import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/app_post.dart';
import '../../models/comment.dart';
import '../auth/auth_controller.dart';
import '../comments/comments_controller.dart';
import '../feed/feed_controller.dart';
import 'profile_leaderboard_badges.dart';
import 'profile_social.dart';

Future<Map<String, ProfileLeaderboardBadges>> fetchLeaderboardBadgesBatch(
  SupabaseClient client,
  List<String> userIds,
) async {
  if (userIds.isEmpty) return {};
  final res = await client.rpc(
    'get_leaderboard_badges_for_users',
    params: {'p_user_ids': userIds},
  );
  if (res == null) return {};
  final list = res as List<dynamic>;
  final out = <String, ProfileLeaderboardBadges>{};
  for (final row in list) {
    final m = Map<String, dynamic>.from(row as Map);
    final uid = m['user_id'] as String?;
    if (uid == null) continue;
    out[uid] = ProfileLeaderboardBadges.fromJson(m);
  }
  return out;
}

void _collectCommentUserIds(List<Comment> list, Set<String> ids) {
  for (final c in list) {
    ids.add(c.userId);
    _collectCommentUserIds(c.replies, ids);
  }
}

/// Fetches leaderboard badge info for all authors on the current feed page.
final feedAuthorLeaderboardBadgesProvider =
    FutureProvider<Map<String, ProfileLeaderboardBadges>>((ref) async {
  final posts = ref.watch(feedControllerProvider).posts;
  final ids = posts.map((p) => p.userId).toSet().toList();
  if (ids.isEmpty) return {};
  final client = ref.watch(supabaseClientProvider);
  return fetchLeaderboardBadgesBatch(client, ids);
});

/// Badges for authors visible on a profile timeline (own posts + shares).
final profileTimelineAuthorBadgesProvider =
    FutureProvider.family<Map<String, ProfileLeaderboardBadges>, String>(
        (ref, profileUserId) async {
  final entries = await ref.watch(profileTimelineProvider(profileUserId).future);
  final ids = entries.map((e) => e.post.userId).toSet().toList();
  if (ids.isEmpty) return {};
  final client = ref.watch(supabaseClientProvider);
  return fetchLeaderboardBadgesBatch(client, ids);
});

/// Post author + all comment authors on the post detail thread.
final postDetailAuthorBadgesProvider =
    FutureProvider.family<Map<String, ProfileLeaderboardBadges>, String>(
        (ref, postId) async {
  final posts = ref.watch(feedControllerProvider).posts;
  AppPost? post;
  for (final p in posts) {
    if (p.postId == postId) {
      post = p;
      break;
    }
  }
  final cs = ref.watch(commentsControllerProvider(postId));
  final ids = <String>{};
  if (post != null) ids.add(post.userId);
  _collectCommentUserIds(cs.comments, ids);
  if (ids.isEmpty) return {};
  final client = ref.watch(supabaseClientProvider);
  return fetchLeaderboardBadgesBatch(client, ids.toList());
});

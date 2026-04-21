import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/app_post.dart';
import '../auth/auth_controller.dart';
import 'feed_controller.dart';

/// Merges `posts.likes_count` when other users like/unlike (trigger updates the row).
/// Enable replication: `supabase/realtime_posts.sql`.
final feedPostsLikesRealtimeProvider = Provider<void>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return;

  void onPostgresChange(PostgresChangePayload payload) {
    if (payload.eventType != PostgresChangeEvent.update) return;
    final row = payload.newRecord;
    final id = row['post_id'];
    if (id is! String) return;
    final visible = ref.read(feedControllerProvider).visiblePostIds;
    if (!visible.contains(id)) return;
    final n = AppPost.readIntColumn(row['likes_count']);
    ref.read(feedControllerProvider.notifier).mergePostLikesCount(id, n);
  }

  final channel = client.channel('public-posts-likes');
  channel
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'posts',
        callback: onPostgresChange,
      )
      .subscribe();

  ref.onDispose(() {
    client.removeChannel(channel);
  });
});

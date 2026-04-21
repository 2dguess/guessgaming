import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_controller.dart';
import 'comments_controller.dart';

/// Realtime sync scoped to one post detail screen.
/// - comments INSERT/DELETE: debounced full reload (structure changed)
/// - comments UPDATE: patch likes_count/content without full reload when possible
final commentsRealtimeProvider =
    Provider.family<void, String>((ref, postId) {
  final client = ref.watch(supabaseClientProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return;

  Timer? reloadDebounce;
  void scheduleReload() {
    reloadDebounce?.cancel();
    reloadDebounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(commentsControllerProvider(postId).notifier).loadComments();
    });
  }

  void onCommentsChange(PostgresChangePayload payload) {
    final row = payload.newRecord.isNotEmpty ? payload.newRecord : payload.oldRecord;
    final pid = row['post_id']?.toString();
    if (pid != postId) return;

    if (payload.eventType == PostgresChangeEvent.insert) {
      scheduleReload();
      return;
    }

    if (payload.eventType == PostgresChangeEvent.delete) {
      final commentId = row['comment_id']?.toString();
      if (commentId != null) {
        ref.read(commentsControllerProvider(postId).notifier).removeCommentById(commentId);
      } else {
        scheduleReload();
      }
      return;
    }

    if (payload.eventType == PostgresChangeEvent.update) {
      final commentId = row['comment_id']?.toString();
      final likesCount = (row['likes_count'] as num?)?.toInt();
      if (commentId != null && likesCount != null) {
        ref
            .read(commentsControllerProvider(postId).notifier)
            .mergeCommentLikeCount(commentId, likesCount);
      } else {
        scheduleReload();
      }
    }
  }

  final channel = client.channel('comments-post-$postId');
  channel
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'comments',
        callback: onCommentsChange,
      )
      .subscribe();

  ref.onDispose(() {
    reloadDebounce?.cancel();
    client.removeChannel(channel);
  });
});


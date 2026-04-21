import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/comment.dart';
import '../auth/auth_controller.dart';

class CommentsState {
  final List<Comment> comments;
  final bool isLoading;
  final String? error;

  CommentsState({
    this.comments = const [],
    this.isLoading = false,
    this.error,
  });

  CommentsState copyWith({
    List<Comment>? comments,
    bool? isLoading,
    String? error,
  }) {
    return CommentsState(
      comments: comments ?? this.comments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CommentsController extends StateNotifier<CommentsState> {
  final SupabaseClient _client;
  final String _postId;
  final String? _userId;

  CommentsController(this._client, this._postId, this._userId)
      : super(CommentsState());

  Future<void> loadComments() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _client.rpc(
        'get_post_comments',
        params: {
          'p_post_id': _postId,
          'p_user_id': _userId,
        },
      );

      final allComments = <Comment>[];
      for (final json in response as List) {
        try {
          final row = Map<String, dynamic>.from(json as Map);
          final comment = Comment.fromJson(row);
          allComments.add(comment);
        } catch (e) {
          print('Error parsing comment row: $e');
        }
      }

      final organizedComments = _organizeComments(allComments);

      if (!mounted) return;
      
      state = state.copyWith(
        comments: organizedComments,
        isLoading: false,
      );
    } catch (e) {
      print('Error loading comments: $e');
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: e.toString(),
        );
      }
    }
  }

  Comment? _findCommentById(List<Comment> comments, String commentId) {
    for (final c in comments) {
      if (c.commentId == commentId) return c;
      for (final r in c.replies) {
        if (r.commentId == commentId) return r;
      }
    }
    return null;
  }

  List<Comment> _patchCommentById(
    List<Comment> comments,
    String commentId,
    Comment Function(Comment) patch,
  ) {
    return comments.map((c) {
      if (c.commentId == commentId) return patch(c);
      final patchedReplies = c.replies.map((r) {
        if (r.commentId == commentId) return patch(r);
        return r;
      }).toList();
      if (identical(patchedReplies, c.replies)) return c;
      return c.copyWith(replies: patchedReplies);
    }).toList();
  }

  void mergeCommentLikeCount(String commentId, int likesCount) {
    if (!mounted) return;
    final current = state.comments;
    final updated = _patchCommentById(
      current,
      commentId,
      (c) => c.copyWith(likesCount: likesCount),
    );
    state = state.copyWith(comments: updated);
  }

  void removeCommentById(String commentId) {
    if (!mounted) return;
    final next = state.comments
        .where((c) => c.commentId != commentId)
        .map(
          (c) => c.copyWith(
            replies: c.replies.where((r) => r.commentId != commentId).toList(),
          ),
        )
        .toList();
    state = state.copyWith(comments: next);
  }

  Future<void> toggleCommentLike(String commentId) async {
    if (_userId == null) return;
    final target = _findCommentById(state.comments, commentId);
    if (target == null) return;

    final willLike = !target.likedByMe;
    final optimistic = _patchCommentById(
      state.comments,
      commentId,
      (c) => c.copyWith(
        likedByMe: willLike,
        likesCount: willLike ? c.likesCount + 1 : ((c.likesCount - 1).clamp(0, 1 << 30) as int),
      ),
    );
    final previous = state.comments;
    state = state.copyWith(comments: optimistic);

    try {
      final existing = await _client
          .from('comment_likes')
          .select()
          .eq('comment_id', commentId)
          .eq('user_id', _userId!)
          .maybeSingle();
      if (existing != null) {
        await _client
            .from('comment_likes')
            .delete()
            .eq('comment_id', commentId)
            .eq('user_id', _userId!);
      } else {
        await _client.from('comment_likes').insert({
          'comment_id': commentId,
          'user_id': _userId!,
        });
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(comments: previous, error: e.toString());
      }
      return;
    }

    // Background reconcile for authoritative likes_count, without full list reload.
    try {
      final row = await _client
          .from('comments')
          .select('likes_count')
          .eq('comment_id', commentId)
          .maybeSingle();
      if (row != null && mounted) {
        final n = (row['likes_count'] as num?)?.toInt();
        if (n != null) {
          state = state.copyWith(
            comments: _patchCommentById(
              state.comments,
              commentId,
              (c) => c.copyWith(likesCount: n),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(error: e.toString());
      }
    }
  }

  List<Comment> _organizeComments(List<Comment> allComments) {
    final topLevelComments = <Comment>[];
    final repliesMap = <String, List<Comment>>{};

    for (final comment in allComments) {
      if (comment.parentCommentId == null) {
        topLevelComments.add(comment);
      } else {
        repliesMap.putIfAbsent(comment.parentCommentId!, () => []);
        repliesMap[comment.parentCommentId!]!.add(comment);
      }
    }

    return topLevelComments.map((comment) {
      return comment.copyWith(
        replies: repliesMap[comment.commentId] ?? [],
      );
    }).toList();
  }

  Future<void> addComment({
    required String content,
    String? parentCommentId,
  }) async {
    if (_userId == null) return;

    try {
      final now = DateTime.now().toUtc();

      final inserted = await _client
          .from('comments')
          .insert({
            'post_id': _postId,
            'user_id': _userId,
            'parent_comment_id': parentCommentId,
            'content': content,
            'created_at': now.toIso8601String(),
          })
          .select()
          .single();

      final json = Map<String, dynamic>.from(inserted as Map);
      final profileData = await _client
          .from('profiles')
          .select()
          .eq('id', _userId!)
          .maybeSingle();
      if (profileData != null) {
        json['profiles'] = profileData;
      }
      final created = Comment.fromJson(json);

      final current = state.comments;
      if (parentCommentId == null) {
        state = state.copyWith(comments: [...current, created]);
      } else {
        final next = current.map((c) {
          if (c.commentId != parentCommentId) return c;
          return c.copyWith(replies: [...c.replies, created]);
        }).toList();
        state = state.copyWith(comments: next);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final commentsControllerProvider = StateNotifierProvider.family<
    CommentsController, CommentsState, String>((ref, postId) {
  final client = ref.watch(supabaseClientProvider);
  final user = ref.watch(currentUserProvider);
  return CommentsController(client, postId, user?.id);
});

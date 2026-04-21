import 'dart:math' show max;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/app_post.dart';
import '../../config/supabase_config.dart';
import '../auth/auth_controller.dart';
import '../gift/gift_providers.dart';
import 'feed_cache.dart';

enum FeedQueryMode {
  home,
  trend,
}

/// First occurrence wins — stable feed order.
List<AppPost> dedupePostsById(List<AppPost> items) {
  final seen = <String>{};
  final out = <AppPost>[];
  for (final p in items) {
    if (seen.add(p.postId)) out.add(p);
  }
  return out;
}

class FeedState {
  final List<AppPost> posts;
  final Set<String> visiblePostIds;
  final bool isLoading;
  final bool hasMore;
  final DateTime? cursorCreatedAt;
  final String? cursorPostId;
  final FeedQueryMode mode;
  final String? error;

  FeedState({
    this.posts = const [],
    this.visiblePostIds = const <String>{},
    this.isLoading = false,
    this.hasMore = true,
    this.cursorCreatedAt,
    this.cursorPostId,
    this.mode = FeedQueryMode.home,
    this.error,
  });

  FeedState copyWith({
    List<AppPost>? posts,
    Set<String>? visiblePostIds,
    bool? isLoading,
    bool? hasMore,
    DateTime? cursorCreatedAt,
    String? cursorPostId,
    FeedQueryMode? mode,
    String? error,
    bool clearCursor = false,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      visiblePostIds: visiblePostIds ?? this.visiblePostIds,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      cursorCreatedAt: clearCursor ? null : (cursorCreatedAt ?? this.cursorCreatedAt),
      cursorPostId: clearCursor ? null : (cursorPostId ?? this.cursorPostId),
      mode: mode ?? this.mode,
      error: error,
    );
  }
}

class FeedController extends StateNotifier<FeedState> {
  final SupabaseClient _client;
  final String? _userId;
  bool _cacheHydrated = false;

  FeedController(this._client, this._userId) : super(FeedState());

  /// Top-level threads (`parent_comment_id` null) — matches post detail list & badge.
  Future<int> topLevelCommentCount(String postId) async {
    try {
      final rows = await _client
          .from('comments')
          .select('parent_comment_id')
          .eq('post_id', postId);
      return (rows as List)
          .where((r) => r['parent_comment_id'] == null)
          .length;
    } catch (e) {
      print('topLevelCommentCount error: $e');
      return 0;
    }
  }

  /// Keep feed card in sync with post detail (same metric as [CommentsController] list).
  /// Applies server `posts.likes_count` (e.g. after another user likes, or post-reconcile).
  void mergePostLikesCount(String postId, int likesCount) {
    if (!mounted) return;
    final idx = state.posts.indexWhere((p) => p.postId == postId);
    if (idx < 0) return;
    final p = state.posts[idx];
    final n = max(0, likesCount);
    if (p.likesCount == n) return;
    final list = [...state.posts];
    list[idx] = p.copyWith(likesCount: n);
    state = state.copyWith(posts: list);
  }

  /// Authoritative like row + count for this user (fixes stale `likedByMe` after RPC/cache).
  Future<void> mergePostLikeStateFromServer(String postId) async {
    if (!mounted || _userId == null) return;
    try {
      final postRow = await _client
          .from('posts')
          .select('likes_count')
          .eq('post_id', postId)
          .maybeSingle();
      final likeRow = await _client
          .from('post_likes')
          .select('post_id')
          .eq('post_id', postId)
          .eq('user_id', _userId!)
          .maybeSingle();
      if (!mounted) return;
      final idx = state.posts.indexWhere((p) => p.postId == postId);
      if (idx < 0) return;
      final p = state.posts[idx];
      final n = AppPost.readIntColumn(
        postRow?['likes_count'],
        fallback: p.likesCount,
      );
      final liked = likeRow != null;
      if (p.likesCount == n && p.likedByMe == liked) return;
      final list = [...state.posts];
      list[idx] = p.copyWith(likesCount: max(0, n), likedByMe: liked);
      state = state.copyWith(posts: list);
    } catch (e) {
      print('mergePostLikeStateFromServer: $e');
    }
  }

  static bool _isDuplicateLikeError(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('23505') ||
        s.contains('duplicate key') ||
        s.contains('unique constraint');
  }

  void setVisiblePostIds(Iterable<String> ids) {
    if (!mounted) return;
    final next = ids.take(200).toSet();
    if (next.length == state.visiblePostIds.length &&
        next.containsAll(state.visiblePostIds)) {
      return;
    }
    state = state.copyWith(visiblePostIds: next);
  }

  Future<List<AppPost>> _mergeGiftTotals(List<AppPost> posts) async {
    if (posts.isEmpty) return posts;
    try {
      final map = await fetchPostGiftTotalsMap(
        _client,
        posts.map((p) => p.postId).toList(),
      );
      return posts
          .map((p) {
            final g = map[p.postId];
            return p.copyWith(
              giftPopularityOnPost: g?.totalPopularity ?? 0,
              giftCountOnPost: g?.giftCount ?? 0,
            );
          })
          .toList();
    } catch (e) {
      print('_mergeGiftTotals: $e');
      return posts;
    }
  }

  /// Refresh per-post gift stats after sending a gift or when syncing one post.
  Future<void> refreshPostGiftStats(String postId) async {
    if (!mounted) return;
    try {
      final map = await fetchPostGiftTotalsMap(_client, [postId]);
      final t = map[postId];
      _applyGiftToPostInState(
        postId,
        t?.totalPopularity ?? 0,
        t?.giftCount ?? 0,
      );
    } catch (e) {
      print('refreshPostGiftStats: $e');
    }
  }

  void _applyGiftToPostInState(String postId, int pop, int count) {
    if (!mounted) return;
    final idx = state.posts.indexWhere((p) => p.postId == postId);
    if (idx < 0) return;
    final p = state.posts[idx];
    final list = [...state.posts];
    list[idx] = p.copyWith(
      giftPopularityOnPost: pop,
      giftCountOnPost: count,
    );
    state = state.copyWith(posts: list);
  }

  void syncPostTopLevelCommentCount(String postId, int topLevelCount) {
    if (!mounted) return;
    final idx = state.posts.indexWhere((p) => p.postId == postId);
    if (idx < 0) return;
    final p = state.posts[idx];
    if (p.commentsCount == topLevelCount) return;
    final list = [...state.posts];
    list[idx] = p.copyWith(commentsCount: topLevelCount);
    state = state.copyWith(posts: list);
  }

  /// Loads a single post into [state.posts] if missing (e.g. opened from profile).
  /// Returns false if the post does not exist. Avoids [firstWhere] falling back to wrong post.
  /// Re-fetch counts from DB for one post already in the feed (e.g. after post detail pop).
  Future<void> refreshPostSnapshot(String postId) async {
    if (!mounted) return;
    final idx = state.posts.indexWhere((p) => p.postId == postId);
    if (idx < 0) return;

    try {
      final row = await _client
          .from('posts')
          .select('likes_count, comments_count')
          .eq('post_id', postId)
          .maybeSingle();
      if (row == null || !mounted) return;

      final topComments = await topLevelCommentCount(postId);
      if (!mounted) return;

      bool likedByMe = false;
      if (_userId != null) {
        final liked = await _client
            .from('post_likes')
            .select()
            .eq('post_id', postId)
            .eq('user_id', _userId!)
            .maybeSingle();
        likedByMe = liked != null;
      }
      if (!mounted) return;

      final giftMap = await fetchPostGiftTotalsMap(_client, [postId]);
      final g = giftMap[postId];

      final existing = state.posts[idx];
      final updated = existing.copyWith(
        likesCount: AppPost.readIntColumn(row['likes_count'], fallback: existing.likesCount),
        commentsCount: topComments,
        likedByMe: likedByMe,
        giftPopularityOnPost: g?.totalPopularity ?? existing.giftPopularityOnPost,
        giftCountOnPost: g?.giftCount ?? existing.giftCountOnPost,
      );
      final list = [...state.posts];
      list[idx] = updated;
      state = state.copyWith(posts: list);
    } catch (e) {
      print('refreshPostSnapshot error: $e');
    }
  }

  Future<bool> ensurePostLoaded(String postId) async {
    if (!mounted) return false;
    if (state.posts.any((p) => p.postId == postId)) return true;

    try {
      final json = await _client
          .from('posts')
          .select()
          .eq('post_id', postId)
          .maybeSingle();
      if (json == null) return false;

      final profileData = await _client
          .from('profiles')
          .select()
          .eq('id', json['user_id'])
          .maybeSingle();
      if (profileData != null) {
        json['profiles'] = profileData;
      }

      final post = AppPost.fromJson(json);
      bool likedByMe = false;
      if (_userId != null) {
        final liked = await _client
            .from('post_likes')
            .select()
            .eq('post_id', post.postId)
            .eq('user_id', _userId!)
            .maybeSingle();
        likedByMe = liked != null;
      }

      if (!mounted) return false;
      final topC = await topLevelCommentCount(post.postId);
      if (!mounted) return false;
      final withGifts = (await _mergeGiftTotals([post])).first;
      final enriched =
          withGifts.copyWith(likedByMe: likedByMe, commentsCount: topC);
      final existingIdx =
          state.posts.indexWhere((p) => p.postId == enriched.postId);
      if (existingIdx >= 0) {
        final list = [...state.posts];
        list[existingIdx] = enriched;
        state = state.copyWith(posts: list);
      } else {
        state = state.copyWith(posts: [enriched, ...state.posts]);
      }
      return true;
    } catch (e) {
      print('ensurePostLoaded error: $e');
      return false;
    }
  }

  Future<void> loadPosts({
    bool refresh = false,
    FeedQueryMode mode = FeedQueryMode.home,
  }) async {
    if (!mounted) return;
    if (state.isLoading) return;
    if (!refresh && !state.hasMore) return;

    final modeChanged = state.mode != mode;
    final shouldRefresh = refresh || modeChanged;

    // SWR: hydrate UI from local cache first, then fetch latest from network.
    if (!_cacheHydrated &&
        _userId != null &&
        state.posts.isEmpty &&
        mode == FeedQueryMode.home) {
      final cached = await FeedCacheStore.read(_userId!);
      if (cached != null && mounted) {
        state = state.copyWith(posts: dedupePostsById(cached.posts));
      }
      _cacheHydrated = true;
    }

    state = state.copyWith(
      isLoading: true,
      error: null,
      mode: mode,
      clearCursor: shouldRefresh,
      posts: shouldRefresh ? const [] : null,
      hasMore: shouldRefresh ? true : null,
    );

    try {
      final response = await _client.rpc(
        'get_feed_posts_page',
        params: {
          'p_user_id': _userId,
          'p_mode': mode.name,
          'p_limit': SupabaseConfig.postsPageSize,
          'p_cursor_created_at': shouldRefresh
              ? null
              : state.cursorCreatedAt?.toUtc().toIso8601String(),
          'p_cursor_post_id': shouldRefresh ? null : state.cursorPostId,
        },
      );

      final newPosts = <AppPost>[];
      for (final json in response as List) {
        try {
          final row = Map<String, dynamic>.from(json as Map);
          newPosts.add(AppPost.fromJson(row));
        } catch (e) {
          print('Error parsing post: $e');
        }
      }

      if (!mounted) return;
      final mergedNew = await _mergeGiftTotals(newPosts);
      final combined = shouldRefresh ? mergedNew : [...state.posts, ...mergedNew];
      final allPosts = dedupePostsById(combined);
      final last = allPosts.isNotEmpty ? allPosts.last : null;
      
      state = state.copyWith(
        posts: allPosts,
        visiblePostIds: allPosts.map((p) => p.postId).take(200).toSet(),
        isLoading: false,
        hasMore: newPosts.length == SupabaseConfig.postsPageSize,
        cursorCreatedAt: last?.createdAt,
        cursorPostId: last?.postId,
      );

      if (_userId != null && mode == FeedQueryMode.home) {
        await FeedCacheStore.write(_userId!, allPosts);
      }
    } catch (e) {
      print('Error loading posts: $e');
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: e.toString(),
        );
      }
    }
  }

  Future<void> toggleLike(String postId) async {
    if (_userId == null) return;
    final userId = _userId!;

    final index = state.posts.indexWhere((p) => p.postId == postId);

    bool currentlyLiked;
    if (index >= 0) {
      currentlyLiked = state.posts[index].likedByMe;
    } else {
      final row = await _client
          .from('post_likes')
          .select()
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();
      currentlyLiked = row != null;
    }

    final newLiked = !currentlyLiked;

    AppPost? previous;
    if (index >= 0) {
      previous = state.posts[index];
      final post = previous;
      final newCount = max(0, post.likesCount + (newLiked ? 1 : -1));
      final updatedPosts = [...state.posts];
      updatedPosts[index] = post.copyWith(
        likedByMe: newLiked,
        likesCount: newCount,
      );
      state = state.copyWith(posts: updatedPosts);
    }

    try {
      if (newLiked) {
        await _client.from('post_likes').insert({
          'post_id': postId,
          'user_id': userId,
        });
      } else {
        await _client
            .from('post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', userId);
      }
      await mergePostLikeStateFromServer(postId);
    } catch (e) {
      // Row already exists: UI was stale — sync from server instead of reverting.
      if (newLiked && _isDuplicateLikeError(e)) {
        await mergePostLikeStateFromServer(postId);
        return;
      }
      if (index >= 0 && previous != null) {
        final updatedPosts = [...state.posts];
        updatedPosts[index] = previous;
        state = state.copyWith(posts: updatedPosts);
      }
    }
  }

  Future<void> createPost({
    required String content,
    String? imageUrl,
  }) async {
    if (_userId == null) {
      throw StateError('Not logged in');
    }
    final userId = _userId!;

    final trimmed = content.trim();
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    // DB CHECK: content NOT NULL and char_length > 0 — use ZWSP for image-only posts.
    const imageOnlyPlaceholder = '\u200B';
    final effectiveContent =
        trimmed.isEmpty && hasImage ? imageOnlyPlaceholder : trimmed;
    if (effectiveContent.isEmpty) {
      throw StateError('Post needs text or an image');
    }

    try {
      final now = DateTime.now().toUtc();

      await _client.from('posts').insert({
        'user_id': userId,
        'content': effectiveContent,
        'image_url': hasImage ? imageUrl : null,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });

      await Future.delayed(const Duration(milliseconds: 500));

      await loadPosts(refresh: true);
    } catch (e) {
      if (mounted) {
        state = state.copyWith(error: e.toString());
      }
      rethrow;
    }
  }
}

final feedControllerProvider = StateNotifierProvider<FeedController, FeedState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final user = ref.watch(currentUserProvider);
  return FeedController(client, user?.id);
});

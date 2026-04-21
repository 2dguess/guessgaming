import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/app_post.dart';
import '../../models/profile_timeline_entry.dart';
import '../gift/gift_providers.dart';
import '../auth/auth_controller.dart';

class ProfileStats {
  final int postsCount;
  final int followersCount;
  final int followingCount;

  const ProfileStats({
    required this.postsCount,
    required this.followersCount,
    required this.followingCount,
  });
}

final profileStatsProvider =
    FutureProvider.family<ProfileStats, String>((ref, userId) async {
  final client = ref.watch(supabaseClientProvider);

  final postsRes = await client
      .from('posts')
      .select('post_id')
      .eq('user_id', userId);
  final postsCount = (postsRes as List).length;

  final followersRes = await client
      .from('follows')
      .select('follower_id')
      .eq('following_id', userId);
  final followersCount = (followersRes as List).length;

  final followingRes = await client
      .from('follows')
      .select('following_id')
      .eq('follower_id', userId);
  final followingCount = (followingRes as List).length;

  return ProfileStats(
    postsCount: postsCount,
    followersCount: followersCount,
    followingCount: followingCount,
  );
});

final isFollowingProvider =
    FutureProvider.family<bool, String>((ref, targetUserId) async {
  final me = ref.watch(currentUserProvider)?.id;
  if (me == null || me == targetUserId) return false;

  final client = ref.watch(supabaseClientProvider);
  final row = await client
      .from('follows')
      .select('follower_id')
      .eq('follower_id', me)
      .eq('following_id', targetUserId)
      .maybeSingle();
  return row != null;
});

Future<void> _attachProfile(SupabaseClient client, Map<String, dynamic> json) async {
  final profileData = await client
      .from('profiles')
      .select()
      .eq('id', json['user_id'])
      .maybeSingle();
  if (profileData != null) {
    json['profiles'] = profileData;
  }
}

Future<bool> _likedByMe(
  SupabaseClient client,
  String postId,
  String userId,
) async {
  final liked = await client
      .from('post_likes')
      .select()
      .eq('post_id', postId)
      .eq('user_id', userId)
      .maybeSingle();
  return liked != null;
}

final profileTimelineProvider =
    FutureProvider.family<List<ProfileTimelineEntry>, String>((ref, userId) async {
  final client = ref.watch(supabaseClientProvider);
  final me = ref.watch(currentUserProvider)?.id;

  final ownRows = await client
      .from('posts')
      .select()
      .eq('user_id', userId)
      .order('created_at', ascending: false);

  List<Map<String, dynamic>> shareRows = [];
  try {
    final raw = await client
        .from('post_shares')
        .select('post_id, created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    shareRows = (raw as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  } catch (_) {
    // Table missing until migration — profile still shows own posts.
  }

  final entries = <ProfileTimelineEntry>[];

  for (final row in ownRows as List) {
    final json = Map<String, dynamic>.from(row as Map);
    await _attachProfile(client, json);
    final post = AppPost.fromJson(json);
    final liked = me != null && await _likedByMe(client, post.postId, me);
    entries.add(ProfileTimelineEntry(
      post: post.copyWith(likedByMe: liked),
      sortTime: post.createdAt,
      isShare: false,
    ));
  }

  for (final s in shareRows) {
    final postId = s['post_id'] as String;
    final sharedAt = DateTime.parse(s['created_at'] as String);
    final postJson = await client
        .from('posts')
        .select()
        .eq('post_id', postId)
        .maybeSingle();
    if (postJson == null) continue;
    final json = Map<String, dynamic>.from(postJson);
    await _attachProfile(client, json);
    final post = AppPost.fromJson(json);
    final liked = me != null && await _likedByMe(client, post.postId, me);
    entries.add(ProfileTimelineEntry(
      post: post.copyWith(likedByMe: liked),
      sortTime: sharedAt,
      isShare: true,
    ));
  }

  entries.sort((a, b) => b.sortTime.compareTo(a.sortTime));

  final postIds = entries.map((e) => e.post.postId).toList();
  final giftTotals = await fetchPostGiftTotalsMap(client, postIds);
  return entries
      .map((e) {
        final g = giftTotals[e.post.postId];
        return ProfileTimelineEntry(
          post: e.post.copyWith(
            giftPopularityOnPost: g?.totalPopularity ?? 0,
            giftCountOnPost: g?.giftCount ?? 0,
          ),
          sortTime: e.sortTime,
          isShare: e.isShare,
        );
      })
      .toList();
});

final followActionsProvider = Provider<FollowActions>((ref) => FollowActions(ref));

class FollowActions {
  FollowActions(this._ref);
  final Ref _ref;

  Future<void> follow(String targetUserId) async {
    final me = _ref.read(currentUserProvider)?.id;
    if (me == null || me == targetUserId) return;
    final client = _ref.read(supabaseClientProvider);
    await client.from('follows').insert({
      'follower_id': me,
      'following_id': targetUserId,
    });
    _ref.invalidate(isFollowingProvider(targetUserId));
    _ref.invalidate(profileStatsProvider(targetUserId));
    _ref.invalidate(profileStatsProvider(me));
  }

  Future<void> unfollow(String targetUserId) async {
    final me = _ref.read(currentUserProvider)?.id;
    if (me == null) return;
    final client = _ref.read(supabaseClientProvider);
    await client
        .from('follows')
        .delete()
        .eq('follower_id', me)
        .eq('following_id', targetUserId);
    _ref.invalidate(isFollowingProvider(targetUserId));
    _ref.invalidate(profileStatsProvider(targetUserId));
    _ref.invalidate(profileStatsProvider(me));
  }
}

final sharePostActionsProvider = Provider<SharePostActions>((ref) => SharePostActions(ref));

class SharePostActions {
  SharePostActions(this._ref);
  final Ref _ref;

  /// Adds a reshare for the current user. Returns true if inserted, false if duplicate.
  /// No-op (returns false) if not logged in. Throws on other errors (e.g. missing table).
  Future<bool> sharePost(String postId) async {
    final me = _ref.read(currentUserProvider)?.id;
    if (me == null) return false;
    final client = _ref.read(supabaseClientProvider);
    try {
      await client.from('post_shares').insert({
        'user_id': me,
        'post_id': postId,
      });
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('duplicate') ||
          msg.contains('unique') ||
          msg.contains('23505')) {
        return false;
      }
      rethrow;
    }
    _ref.invalidate(profileTimelineProvider(me));
    return true;
  }
}

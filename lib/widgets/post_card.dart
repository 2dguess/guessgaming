import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/app_post.dart';
import '../config/theme.dart';
import 'like_button.dart';
import 'leaderboard_rank_badges.dart';
import 'time_display.dart';
import '../state/social/profile_leaderboard_badges.dart';
import '../state/auth/auth_controller.dart';
import 'post_gift_sheet.dart';
import 'post_gift_strip.dart';

class PostCard extends ConsumerWidget {
  final AppPost post;
  final VoidCallback onLike;
  /// Facebook-style “Shared” row on profile timeline.
  final bool isReshare;
  final DateTime? reshareTime;
  final VoidCallback? onShare;
  /// After closing post detail — sync counts on feed/profile (optional).
  final Future<void> Function(String postId)? onReturnFromPostDetail;
  /// Leaderboard badges for [post.userId] (score top 10 + best match top 10).
  final ProfileLeaderboardBadges? leaderboardBadges;

  const PostCard({
    super.key,
    required this.post,
    required this.onLike,
    this.isReshare = false,
    this.reshareTime,
    this.onShare,
    this.onReturnFromPostDetail,
    this.leaderboardBadges,
  });

  Future<void> _openPostDetail(BuildContext context) async {
    await context.push('/post/${post.postId}');
    if (!context.mounted) return;
    final cb = onReturnFromPostDetail;
    if (cb != null) await cb(post.postId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider)?.id;
    final canGift = me != null && me != post.userId;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.paddingL,
        vertical: AppTheme.paddingS,
      ),
      child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isReshare && reshareTime != null) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.paddingS),
                  child: Row(
                    children: [
                      Icon(
                        Icons.repeat,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Shared',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(width: 6),
                      TimeDisplay(
                        dateTime: reshareTime!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
              Row(
                children: [
                  InkWell(
                    onTap: () => context.push('/profile/${post.userId}'),
                    child: CircleAvatar(
                      radius: AppTheme.avatarM / 2,
                      backgroundColor: AppTheme.primaryLight,
                      backgroundImage: post.profile?.avatarUrl != null
                          ? CachedNetworkImageProvider(post.profile!.avatarUrl!)
                          : null,
                      child: post.profile?.avatarUrl == null
                          ? Text(
                              post.profile?.username[0].toUpperCase() ?? 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: AppTheme.paddingM),
                  Expanded(
                    child: InkWell(
                      onTap: () => context.push('/profile/${post.userId}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        Row(
                          children: [
                            if (leaderboardBadges != null &&
                                leaderboardBadges!.hasAnyBadge) ...[
                              LeaderboardBadgesRow(badges: leaderboardBadges!),
                              const SizedBox(width: 6),
                            ],
                            Expanded(
                              child: Text(
                                post.profile?.username ?? 'Unknown',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        TimeDisplay(
                          dateTime: post.createdAt,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.paddingM),
              if (post.visibleContent.isNotEmpty)
                InkWell(
                  onTap: () => _openPostDetail(context),
                  child: Text(
                    post.visibleContent,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              if (post.imageUrl != null) ...[
                const SizedBox(height: AppTheme.paddingM),
                InkWell(
                  onTap: () => _openPostDetail(context),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    child: CachedNetworkImage(
                      imageUrl: post.imageUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 200,
                        color: AppTheme.backgroundColor,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 200,
                        color: AppTheme.backgroundColor,
                        child: const Icon(Icons.error),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.paddingM),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (post.likesCount > 0 || post.likedByMe)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                '${post.likesCount < 1 && post.likedByMe ? 1 : post.likesCount}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: post.likedByMe ? AppTheme.likeColor : AppTheme.textSecondary,
                                    ),
                              ),
                            ),
                          LikeButton(
                            isLiked: post.likedByMe,
                            onTap: onLike,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (post.commentsCount > 0)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                '${post.commentsCount}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textSecondary,
                                    ),
                              ),
                            ),
                          TextButton.icon(
                            onPressed: () => _openPostDetail(context),
                            icon: const Icon(Icons.comment_outlined, size: 20),
                            label: const Text('Comment'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.textSecondary,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PostGiftFireHint(post: post),
                          TextButton.icon(
                            onPressed: canGift
                                ? () => showPostGiftPicker(
                                      context: context,
                                      ref: ref,
                                      postId: post.postId,
                                      recipientUserId: post.userId,
                                    )
                                : null,
                            icon: Icon(
                              Icons.card_giftcard_outlined,
                              size: 20,
                              color: canGift ? null : AppTheme.textHint,
                            ),
                            label: Text(
                              'Gift',
                              style: TextStyle(
                                fontSize: 12,
                                color: canGift ? AppTheme.textSecondary : AppTheme.textHint,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.textSecondary,
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                              disabledForegroundColor: AppTheme.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: onShare,
                        icon: const Icon(Icons.share_outlined, size: 20),
                        label: const Text('Share'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.textSecondary,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }
}

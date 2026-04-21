import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/comment.dart';
import '../config/theme.dart';
import '../state/social/profile_leaderboard_badges.dart';
import 'leaderboard_rank_badges.dart';
import 'time_display.dart';

class CommentCard extends StatelessWidget {
  final Comment comment;
  final void Function(String commentId, String? username) onReplyTo;
  final Function(String commentId)? onLike;
  final bool isReply;
  /// Which comment is the composer replying to (highlights Reply on that row).
  final String? activeReplyTargetId;
  /// Lookup leaderboard badges by user id (post detail batch fetch).
  final Map<String, ProfileLeaderboardBadges>? badgeMap;

  const CommentCard({
    super.key,
    required this.comment,
    required this.onReplyTo,
    this.onLike,
    this.isReply = false,
    this.activeReplyTargetId,
    this.badgeMap,
  });

  @override
  Widget build(BuildContext context) {
    final liked = comment.likedByMe;
    final likesCount = comment.likesCount;
    final isReplyingTo = activeReplyTargetId == comment.commentId;

    return Padding(
      padding: EdgeInsets.only(
        left: isReply ? 40 : 0,
        top: AppTheme.paddingM,
        right: 0,
        bottom: AppTheme.paddingXS,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: isReply ? 14 : 18,
                backgroundColor: AppTheme.primaryLight,
                backgroundImage: comment.profile?.avatarUrl != null
                    ? CachedNetworkImageProvider(comment.profile!.avatarUrl!)
                    : null,
                child: comment.profile?.avatarUrl == null
                    ? Text(
                        comment.profile?.username[0].toUpperCase() ?? 'U',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isReply ? 10 : 12,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: AppTheme.paddingS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.paddingM,
                        vertical: AppTheme.paddingS,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(AppTheme.radiusL),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (badgeMap != null) ...[
                                Builder(
                                  builder: (context) {
                                    final b = badgeMap![comment.userId];
                                    if (b == null || !b.hasAnyBadge) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 5),
                                      child: LeaderboardBadgesRow(
                                        badges: b,
                                        circleSize: 15,
                                        hexHeight: 15,
                                        spacing: 4,
                                      ),
                                    );
                                  },
                                ),
                              ],
                              Expanded(
                                child: Text(
                                  comment.profile?.username ?? 'Unknown',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            comment.content,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 14,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: AppTheme.paddingM),
                      child: Row(
                        children: [
                          TimeDisplay(
                            dateTime: comment.createdAt,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                          ),
                          const SizedBox(width: AppTheme.paddingL),
                          InkWell(
                            onTap: onLike == null
                                ? null
                                : () => onLike!(comment.commentId),
                            child: Text(
                              'Like',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 12,
                                    fontWeight: liked ? FontWeight.bold : FontWeight.normal,
                                    color: liked ? AppTheme.likeColor : AppTheme.textSecondary,
                                  ),
                            ),
                          ),
                          const SizedBox(width: AppTheme.paddingL),
                          InkWell(
                            onTap: () =>
                                onReplyTo(comment.commentId, comment.profile?.username),
                            child: Container(
                              padding: isReplyingTo
                                  ? const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    )
                                  : null,
                              decoration: isReplyingTo
                                  ? BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    )
                                  : null,
                              child: Text(
                                'Reply',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontSize: 12,
                                      fontWeight:
                                          isReplyingTo ? FontWeight.bold : FontWeight.normal,
                                      color: isReplyingTo
                                          ? AppTheme.primaryColor
                                          : AppTheme.textSecondary,
                                    ),
                              ),
                            ),
                          ),
                          if (likesCount > 0) ...[
                            const SizedBox(width: AppTheme.paddingL),
                            Row(
                              children: [
                                Icon(
                                  Icons.favorite,
                                  size: 12,
                                  color: AppTheme.likeColor,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '$likesCount',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (comment.replies.isNotEmpty)
            ...comment.replies.map(
              (reply) => CommentCard(
                key: ValueKey(reply.commentId),
                comment: reply,
                badgeMap: badgeMap,
                onReplyTo: onReplyTo,
                onLike: onLike,
                isReply: true,
                activeReplyTargetId: activeReplyTargetId,
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart' show AppTheme, rootScaffoldMessengerKey;
import '../../state/feed/feed_controller.dart';
import '../../state/feed/feed_posts_realtime.dart';
import '../../state/comments/comments_controller.dart';
import '../../state/comments/comments_realtime.dart';
import '../../state/auth/auth_controller.dart';
import '../../state/social/profile_social.dart';
import '../../state/social/profile_leaderboard_badges.dart';
import '../../state/social/leaderboard_badges_map.dart';
import '../../widgets/like_button.dart';
import '../../widgets/comment_card.dart';
import '../../widgets/time_display.dart';
import '../../widgets/leaderboard_rank_badges.dart';
import '../../widgets/post_gift_sheet.dart';
import '../../widgets/post_gift_strip.dart';
import '../../models/app_post.dart';

class PostDetailPage extends ConsumerStatefulWidget {
  final String postId;

  const PostDetailPage({
    super.key,
    required this.postId,
  });

  @override
  ConsumerState<PostDetailPage> createState() => _PostDetailPageState();
}

/// Top-level threads (matches the comment list); after load prefer live count.
int _liveCommentCount(CommentsState s, AppPost post) {
  final n = s.comments.length;
  if (!s.isLoading) return n;
  if (n > 0) return n;
  return post.commentsCount;
}

class _PostDetailPageState extends ConsumerState<PostDetailPage> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  String? _replyToCommentId;
  String? _replyToUsername;
  bool _postResolved = false;

  @override
  void initState() {
    super.initState();
    _commentController.addListener(() {
      setState(() {});
    });
    Future.microtask(() async {
      await ref
          .read(feedControllerProvider.notifier)
          .ensurePostLoaded(widget.postId);
      if (!mounted) return;
      setState(() => _postResolved = true);
      ref.read(commentsControllerProvider(widget.postId).notifier).loadComments();
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSendComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final commentText = _commentController.text.trim();
    _commentController.clear();
    
    final replyId = _replyToCommentId;
    setState(() {
      _replyToCommentId = null;
      _replyToUsername = null;
    });

    FocusScope.of(context).unfocus();

    await ref.read(commentsControllerProvider(widget.postId).notifier).addComment(
          content: commentText,
          parentCommentId: replyId,
        );
  }

  Widget _buildPostCardWithDisabledComment(
    AppPost post,
    CommentsState commentsState,
    Map<String, ProfileLeaderboardBadges>? authorBadgeMap,
  ) {
    final commentCount = _liveCommentCount(commentsState, post);
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
            Row(
              children: [
                InkWell(
                  onTap: () => context.push('/profile/${post.userId}'),
                  child: CircleAvatar(
                    radius: AppTheme.avatarM / 2,
                    backgroundColor: AppTheme.primaryLight,
                    child: Text(
                      post.profile?.username[0].toUpperCase() ?? 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                            if (authorBadgeMap != null) ...[
                              Builder(
                                builder: (context) {
                                  final b = authorBadgeMap[post.userId];
                                  if (b == null || !b.hasAnyBadge) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: LeaderboardBadgesRow(badges: b),
                                  );
                                },
                              ),
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
              Text(
                post.visibleContent,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            if (post.imageUrl != null) ...[
              const SizedBox(height: AppTheme.paddingM),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                child: CachedNetworkImage(
                  imageUrl: post.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
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
                          onTap: () {
                            ref.read(feedControllerProvider.notifier).toggleLike(post.postId);
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (commentCount > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              '$commentCount',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondary,
                                  ),
                            ),
                          ),
                        TextButton.icon(
                          onPressed: null, // Disabled
                          icon: const Icon(Icons.comment_outlined, size: 20),
                          label: const Text('Comment'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.textHint,
                            disabledForegroundColor: AppTheme.textHint,
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
                      onPressed: () async {
                        try {
                          final added = await ref
                              .read(sharePostActionsProvider)
                              .sharePost(post.postId);
                          if (!context.mounted) return;
                          rootScaffoldMessengerKey.currentState?.showSnackBar(
                            SnackBar(
                              content: Text(
                                added
                                    ? 'Shared to your profile'
                                    : 'Already on your profile',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          rootScaffoldMessengerKey.currentState?.showSnackBar(
                            SnackBar(
                              content: Text('Share failed: $e'),
                              backgroundColor: AppTheme.errorColor,
                            ),
                          );
                        }
                      },
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

  @override
  Widget build(BuildContext context) {
    ref.watch(feedPostsLikesRealtimeProvider);
    ref.watch(commentsRealtimeProvider(widget.postId));

    final feedState = ref.watch(feedControllerProvider);
    final commentsState = ref.watch(commentsControllerProvider(widget.postId));
    final userProfile = ref.watch(userProfileProvider);
    final authorBadgeMap = ref.watch(postDetailAuthorBadgesProvider(widget.postId));

    AppPost? post;
    for (final p in feedState.posts) {
      if (p.postId == widget.postId) {
        post = p;
        break;
      }
    }

    if (post == null && !_postResolved) {
      return Scaffold(
        appBar: AppBar(title: const Text('Post')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (post == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Post')),
        body: const Center(child: Text('Post not found')),
      );
    }

    ref.listen<CommentsState>(
      commentsControllerProvider(widget.postId),
      (previous, next) {
        if (next.isLoading) return;
        ref.read(feedControllerProvider.notifier).syncPostTopLevelCommentCount(
              widget.postId,
              next.comments.length,
            );
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              children: [
                _buildPostCardWithDisabledComment(
                  post,
                  commentsState,
                  authorBadgeMap.valueOrNull,
                ),
                const Divider(height: 1),
                if (commentsState.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppTheme.paddingXL),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (commentsState.comments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.paddingXL),
                    child: Center(
                      child: Text(
                        'No comments yet. Be the first to comment!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingL),
                    child: Column(
                      children: commentsState.comments
                          .map(
                            (comment) => CommentCard(
                              key: ValueKey(comment.commentId),
                              comment: comment,
                              badgeMap: authorBadgeMap.valueOrNull,
                              activeReplyTargetId: _replyToCommentId,
                              onReplyTo: (id, username) {
                                setState(() {
                                  _replyToCommentId = id;
                                  _replyToUsername = username;
                                });
                                FocusScope.of(context).requestFocus(FocusNode());
                              },
                              onLike: (commentId) {
                                ref
                                    .read(commentsControllerProvider(widget.postId).notifier)
                                    .toggleCommentLike(commentId);
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ),
                const SizedBox(height: 80),
              ],
            ),
          ),
          _buildCommentComposer(userProfile),
        ],
      ),
    );
  }

  Widget _buildCommentComposer(AsyncValue userProfile) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border(
          top: BorderSide(
            color: AppTheme.dividerColor,
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.only(
        left: AppTheme.paddingL,
        right: AppTheme.paddingL,
        top: AppTheme.paddingM,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.paddingM,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyToUsername != null)
            Container(
              padding: const EdgeInsets.all(AppTheme.paddingS),
              margin: const EdgeInsets.only(bottom: AppTheme.paddingS),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.reply,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: AppTheme.paddingS),
                  Text(
                    'Replying to @$_replyToUsername',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _replyToCommentId = null;
                        _replyToUsername = null;
                      });
                    },
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primaryLight,
                child: userProfile.when(
                  data: (profile) => Text(
                    profile?.username[0].toUpperCase() ?? 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  loading: () => const SizedBox(),
                  error: (_, __) => const Icon(Icons.person, size: 16),
                ),
              ),
              const SizedBox(width: AppTheme.paddingM),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.paddingM,
                    vertical: AppTheme.paddingS,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: _commentController,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: _replyToUsername != null 
                          ? 'Write a reply...' 
                          : 'Write a comment...',
                      hintStyle: TextStyle(
                        color: AppTheme.textHint,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.paddingS),
              IconButton(
                icon: Icon(
                  _commentController.text.trim().isEmpty 
                      ? Icons.send_outlined 
                      : Icons.send,
                  size: 24,
                ),
                color: _commentController.text.trim().isEmpty 
                    ? AppTheme.textHint 
                    : AppTheme.primaryColor,
                onPressed: _commentController.text.trim().isEmpty 
                    ? null 
                    : _handleSendComment,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

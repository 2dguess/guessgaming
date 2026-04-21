import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme.dart' show AppTheme, rootScaffoldMessengerKey;
import '../../config/app_legal.dart';
import '../../state/feed/feed_controller.dart';
import '../../state/feed/feed_posts_realtime.dart';
import '../../state/auth/auth_controller.dart';
import '../../state/social/profile_social.dart';
import '../../state/social/profile_leaderboard_badges.dart';
import '../../state/social/leaderboard_badges_map.dart';
import '../../state/chat/dm_controller.dart';
import '../../models/app_profile.dart';
import '../../models/app_post.dart';
import '../../widgets/post_card.dart';
import '../../widgets/chat_inbox_button.dart';
import '../../widgets/notification_bell_button.dart';

final _followingIdsProvider = FutureProvider<Set<String>>((ref) async {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return <String>{};
  final client = Supabase.instance.client;
  final rows = await client
      .from('follows')
      .select('following_id')
      .eq('follower_id', userId);
  return (rows as List)
      .map((e) => (e as Map<String, dynamic>)['following_id'] as String?)
      .whereType<String>()
      .toSet();
});

final _followSuggestionsProvider = FutureProvider<List<AppProfile>>((ref) async {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return const <AppProfile>[];
  final client = Supabase.instance.client;
  final followingIds = await ref.watch(_followingIdsProvider.future);
  final blocked = {...followingIds, userId};
  final raw = await client
      .from('profiles')
      .select()
      .order('created_at', ascending: false)
      .limit(20);
  final list = <AppProfile>[];
  for (final row in raw as List) {
    final m = Map<String, dynamic>.from(row as Map);
    final id = m['id'] as String?;
    if (id == null || blocked.contains(id)) continue;
    list.add(AppProfile.fromJson(m));
    if (list.length >= 8) break;
  }
  return list;
});

class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> {
  final _scrollController = ScrollController();
  final _tabController = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(feedControllerProvider.notifier).loadPosts(
          mode: FeedQueryMode.home,
        ));
    
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent * 0.9) {
        final mode =
            _tabController.value == 1 ? FeedQueryMode.trend : FeedQueryMode.home;
        ref.read(feedControllerProvider.notifier).loadPosts(mode: mode);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(feedPostsLikesRealtimeProvider);
    ref.watch(dmInboxRealtimeBootstrapProvider);

    ref.listen<User?>(currentUserProvider, (prev, next) {
      if (prev?.id != next?.id) {
        Future.microtask(() {
          ref.read(feedControllerProvider.notifier).loadPosts(refresh: true);
          ref.invalidate(dmUnreadConversationsCountProvider);
          ref.invalidate(dmThreadListProvider);
        });
      }
    });

    final feedState = ref.watch(feedControllerProvider);
    final userProfile = ref.watch(userProfileProvider);
    final suggestionsAsync = ref.watch(_followSuggestionsProvider);
    final feedAuthorBadges = ref.watch(feedAuthorLeaderboardBadgesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Feed'),
            const SizedBox(width: AppTheme.paddingL),
            Expanded(
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    hintStyle: TextStyle(
                      color: AppTheme.textHint,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppTheme.textSecondary,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.paddingM,
                      vertical: 8,
                    ),
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.card_giftcard_outlined),
            tooltip: 'Gift shop',
            onPressed: () => context.push('/gift-shop'),
          ),
          const ChatInboxButton(),
          const NotificationBellButton(),
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: _openFeedSideMenu,
          ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Material(
              color: AppTheme.cardColor,
              child: TabBar(
                onTap: (index) {
                  _tabController.value = index;
                  ref.read(feedControllerProvider.notifier).loadPosts(
                        refresh: true,
                        mode: index == 1 ? FeedQueryMode.trend : FeedQueryMode.home,
                      );
                },
                tabs: const [
                  Tab(text: 'Home'),
                  Tab(text: 'Daily Trend'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  RefreshIndicator(
                    onRefresh: () async {
                      await ref.read(feedControllerProvider.notifier).loadPosts(
                            refresh: true,
                            mode: FeedQueryMode.home,
                          );
                      ref.invalidate(_followingIdsProvider);
                      ref.invalidate(_followSuggestionsProvider);
                      ref.invalidate(dmUnreadConversationsCountProvider);
                      ref.invalidate(dmThreadListProvider);
                    },
                    child: CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        SliverToBoxAdapter(
                          child: _buildPostComposer(context, userProfile),
                        ),
                        SliverToBoxAdapter(
                          child: _buildSuggestionsCard(context, suggestionsAsync),
                        ),
                        ..._buildFeedPostSlivers(
                          context: context,
                          posts: feedState.mode == FeedQueryMode.home
                              ? feedState.posts
                              : const <AppPost>[],
                          isLoading: feedState.isLoading,
                          emptyText: 'No following posts yet.',
                          authorBadgeByUserId: feedAuthorBadges.valueOrNull,
                        ),
                      ],
                    ),
                  ),
                  RefreshIndicator(
                    onRefresh: () async {
                      await ref.read(feedControllerProvider.notifier).loadPosts(
                            refresh: true,
                            mode: FeedQueryMode.trend,
                          );
                    },
                    child: CustomScrollView(
                      slivers: _buildFeedPostSlivers(
                        context: context,
                        posts: feedState.mode == FeedQueryMode.trend
                            ? feedState.posts
                            : const <AppPost>[],
                        isLoading: feedState.isLoading,
                        emptyText: 'No posts in last 24 hours.',
                        authorBadgeByUserId: feedAuthorBadges.valueOrNull,
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

  List<Widget> _buildFeedPostSlivers({
    required BuildContext context,
    required List<AppPost> posts,
    required bool isLoading,
    required String emptyText,
    Map<String, ProfileLeaderboardBadges>? authorBadgeByUserId,
  }) {
    if (posts.isEmpty && !isLoading) {
      return [
        SliverFillRemaining(
          child: Center(child: Text(emptyText)),
        ),
      ];
    }

    final totalItems = posts.length + _adSlotsForPosts(posts.length);
    return [
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index < totalItems) {
              if (_isAdIndex(index)) {
                return _buildAdCard(index ~/ 5 + 1);
              }
              final post = posts[_postIndexForMixedIndex(index)];
              return GestureDetector(
                onDoubleTap: () {
                  if (!post.likedByMe) {
                    ref.read(feedControllerProvider.notifier).toggleLike(post.postId);
                  }
                },
                child: PostCard(
                  post: post,
                  leaderboardBadges: authorBadgeByUserId?[post.userId],
                  onLike: () {
                    ref.read(feedControllerProvider.notifier).toggleLike(post.postId);
                  },
                  onReturnFromPostDetail: (postId) =>
                      ref.read(feedControllerProvider.notifier).refreshPostSnapshot(postId),
                  onShare: () async {
                    try {
                      final added =
                          await ref.read(sharePostActionsProvider).sharePost(post.postId);
                      if (!context.mounted) return;
                      rootScaffoldMessengerKey.currentState?.showSnackBar(
                        SnackBar(
                          content: Text(
                            added ? 'Shared to your profile' : 'Already on your profile',
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
                ),
              );
            } else if (isLoading) {
              return const Padding(
                padding: EdgeInsets.all(AppTheme.paddingL),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return null;
          },
          childCount: totalItems + (isLoading ? 1 : 0),
        ),
      ),
    ];
  }

  bool _isAdIndex(int mixedIndex) => mixedIndex > 0 && (mixedIndex + 1) % 5 == 0;

  int _postIndexForMixedIndex(int mixedIndex) {
    final adsBefore = (mixedIndex + 1) ~/ 5;
    return mixedIndex - adsBefore;
  }

  int _adSlotsForPosts(int postCount) => postCount ~/ 4;

  Widget _buildAdCard(int slot) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.paddingL,
        vertical: AppTheme.paddingS,
      ),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.campaign_outlined)),
        title: Text('Sponsored #$slot'),
        subtitle: const Text('Ad placement'),
        trailing: TextButton(
          onPressed: () {},
          child: const Text('Learn more'),
        ),
      ),
    );
  }

  Widget _buildSuggestionsCard(
    BuildContext context,
    AsyncValue<List<AppProfile>> suggestionsAsync,
  ) {
    return suggestionsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Card(
          margin: const EdgeInsets.symmetric(
            horizontal: AppTheme.paddingL,
            vertical: AppTheme.paddingS,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suggestions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppTheme.paddingS),
                ...items.take(4).map(
                  (p) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(p.username),
                    trailing: TextButton(
                      onPressed: () async {
                        await ref.read(followActionsProvider).follow(p.id);
                        ref.invalidate(_followingIdsProvider);
                        ref.invalidate(_followSuggestionsProvider);
                        if (mounted) {
                          ref.read(feedControllerProvider.notifier).loadPosts(refresh: true);
                        }
                      },
                      child: const Text('Follow'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPostComposer(BuildContext context, AsyncValue userProfile) {
    return Card(
      margin: const EdgeInsets.all(AppTheme.paddingL),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingL),
        child: Row(
          children: [
            CircleAvatar(
              radius: AppTheme.avatarM / 2,
              backgroundColor: AppTheme.primaryLight,
              child: userProfile.when(
                data: (profile) => Text(
                  profile?.username[0].toUpperCase() ?? 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                loading: () => const SizedBox(),
                error: (_, __) => const Icon(Icons.person),
              ),
            ),
            const SizedBox(width: AppTheme.paddingM),
            Expanded(
              child: GestureDetector(
                onTap: () => context.push('/compose'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.paddingL,
                    vertical: AppTheme.paddingM,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  ),
                  child: Text(
                    "What's on your mind?",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textHint,
                        ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Slides in from the right, ~half screen width (phone).
  void _openFeedSideMenu() {
    final barrierLabel =
        MaterialLocalizations.of(context).modalBarrierDismissLabel;
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: barrierLabel,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (ctx, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
          ),
          child: child,
        );
      },
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final w = MediaQuery.sizeOf(dialogContext).width * 0.5;
        final h = MediaQuery.sizeOf(dialogContext).height;
        return Align(
          alignment: AlignmentDirectional.centerEnd,
          child: SizedBox(
            width: w,
            height: h,
            child: Material(
              elevation: 12,
              shadowColor: Colors.black26,
              clipBehavior: Clip.antiAlias,
              color: Theme.of(dialogContext).colorScheme.surface,
              child: SafeArea(
                left: false,
                child: _buildMenuSheet(dialogContext),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuSheet(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(
        vertical: AppTheme.paddingS,
        horizontal: AppTheme.paddingS,
      ),
      children: [
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              context.go('/home');
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              final userId = ref.read(currentUserProvider)?.id;
              if (userId != null) {
                context.push('/profile/$userId');
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.sports_esports),
            title: const Text('2D Play'),
            onTap: () {
              Navigator.pop(context);
              context.push('/picks');
            },
          ),
          ListTile(
            leading: const Icon(Icons.card_giftcard),
            title: const Text('Missions'),
            onTap: () {
              Navigator.pop(context);
              context.push('/missions');
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            onTap: AppLegal.hasProductionUrls
                ? () async {
              Navigator.pop(context);
              await AppLegal.openPrivacyPolicy();
            }
                : null,
          ),
          ListTile(
            leading: const Icon(Icons.article_outlined),
            title: const Text('Terms of Service'),
            onTap: AppLegal.hasProductionUrls
                ? () async {
              Navigator.pop(context);
              await AppLegal.openTermsOfService();
            }
                : null,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.errorColor),
            title: const Text('Logout', style: TextStyle(color: AppTheme.errorColor)),
            onTap: () async {
              Navigator.pop(context);
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
      ],
    );
  }
}

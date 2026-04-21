import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart' show AppTheme, rootScaffoldMessengerKey;
import '../../models/app_profile.dart';
import '../../state/auth/auth_controller.dart';
import '../../state/feed/feed_controller.dart';
import '../../state/social/profile_social.dart';
import '../../state/social/profile_leaderboard_badges.dart';
import '../../state/social/leaderboard_badges_map.dart';
import '../../state/chat/dm_controller.dart';
import '../../widgets/post_card.dart';
import '../../widgets/profile_header_avatar.dart';
import '../../widgets/leaderboard_rank_badges.dart';

class ProfilePage extends ConsumerStatefulWidget {
  final String userId;

  const ProfilePage({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _isUpdating = false;
  bool _followBusy = false;
  bool _dmOpenBusy = false;

  void _showEditUsernameDialog() {
    print('🔧 Edit username button clicked');
    
    final usernameController = TextEditingController();
    
    // Get current username
    final profileAsync = ref.read(userProfileProvider);
    profileAsync.whenOrNull(
      data: (profile) {
        if (profile != null) {
          usernameController.text = profile.username;
          print('✅ Current username: ${profile.username}');
        }
      },
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        print('✨ Dialog building...');
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Username'),
              content: TextField(
                controller: usernameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  hintText: 'Enter new username',
                  border: OutlineInputBorder(),
                  helperText: '3-30 characters',
                ),
                maxLength: 30,
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    print('❌ Cancel clicked');
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isUpdating
                      ? null
                      : () async {
                          print('💾 Save clicked');
                          final newUsername = usernameController.text.trim();
                          
                          if (newUsername.isEmpty) {
                            _profileMessenger(
                              (m) => m.showSnackBar(
                                const SnackBar(
                                  content: Text('Username cannot be empty'),
                                  backgroundColor: AppTheme.errorColor,
                                ),
                              ),
                            );
                            return;
                          }
                          
                          if (newUsername.length < 3) {
                            _profileMessenger(
                              (m) => m.showSnackBar(
                                const SnackBar(
                                  content: Text('Username must be at least 3 characters'),
                                  backgroundColor: AppTheme.errorColor,
                                ),
                              ),
                            );
                            return;
                          }

                          setDialogState(() => _isUpdating = true);
                          setState(() => _isUpdating = true);

                          try {
                            final userId = ref.read(currentUserProvider)?.id;
                            if (userId == null) {
                              throw Exception('Not logged in');
                            }

                            await Supabase.instance.client
                                .from('profiles')
                                .update({'username': newUsername})
                                .eq('id', userId);

                            ref.invalidate(userProfileProvider);

                            if (!context.mounted || !dialogContext.mounted) {
                              return;
                            }
                            Navigator.pop(dialogContext);
                            _profileMessenger(
                              (m) => m.showSnackBar(
                                const SnackBar(
                                  content: Text('✓ Username updated!'),
                                  backgroundColor: AppTheme.successColor,
                                ),
                              ),
                            );
                          } catch (e) {
                            print('❌ Update error: $e');
                            if (mounted) {
                              _profileMessenger(
                                (m) => m.showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: AppTheme.errorColor,
                                  ),
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setDialogState(() => _isUpdating = false);
                              setState(() => _isUpdating = false);
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: _isUpdating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
    
    print('✅ Dialog shown');
  }

  void _showUploadPictureDialog() {
    print('📷 Camera icon clicked');
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Upload Profile Picture'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(dialogContext);
                _uploadProfilePicture();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateUsername() async {
    // This method is kept for compatibility but not used anymore
  }

  String _extensionFromXFile(XFile file) {
    final name = file.name;
    final i = name.lastIndexOf('.');
    if (i >= 0 && i < name.length - 1) {
      return name.substring(i + 1).toLowerCase();
    }
    final path = file.path;
    final j = path.lastIndexOf('.');
    if (j >= 0 && j < path.length - 1) {
      return path.substring(j + 1).toLowerCase();
    }
    return 'jpg';
  }

  String _contentTypeForExt(String ext) {
    return switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'heic' => 'image/heic',
      'heif' => 'image/heic',
      _ => 'image/jpeg',
    };
  }

  String _publicUrlToString(dynamic raw) {
    if (raw is String) return raw;
    return raw.toString();
  }

  /// SnackBars after picker/async: next frame + root messenger avoids deactivated lookups.
  void _profileMessenger(void Function(ScaffoldMessengerState m) fn) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final root = rootScaffoldMessengerKey.currentState;
      if (root != null) {
        fn(root);
        return;
      }
      if (!mounted) return;
      final m = ScaffoldMessenger.maybeOf(context);
      if (m != null) fn(m);
    });
  }

  Future<void> _uploadProfilePicture() async {
    print('📸 Starting image upload...');
    
    try {
      final userId = ref.read(currentUserProvider)?.id;
      if (userId == null) {
        throw Exception('Not logged in');
      }

      final supabase = ref.read(supabaseClientProvider);

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (!context.mounted) return;

      if (image == null) {
        print('❌ No image selected');
        return;
      }

      print('✅ Image selected: ${image.path}');

      setState(() => _isUpdating = true);

      _profileMessenger(
        (m) => m.showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 16),
                Text('Uploading...'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        ),
      );

      final bytes = await image.readAsBytes();
      if (!context.mounted) return;

      print('📦 File size: ${bytes.length} bytes');
      
      if (bytes.length > 5 * 1024 * 1024) {
        throw Exception('Image too large (max 5MB)');
      }

      final fileExt = _extensionFromXFile(image);
      // Path is relative to bucket root (same pattern as post images).
      final pathInBucket =
          '$userId-${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      print('⬆️ Uploading to bucket avatars: $pathInBucket');

      await supabase.storage.from('avatars').uploadBinary(
            pathInBucket,
            bytes,
            fileOptions: FileOptions(
              contentType: _contentTypeForExt(fileExt),
              upsert: true,
            ),
          );

      if (!context.mounted) return;

      print('✅ Upload complete');

      final rawPublicUrl =
          supabase.storage.from('avatars').getPublicUrl(pathInBucket);
      final imageUrl = _publicUrlToString(rawPublicUrl);
      if (imageUrl.isEmpty) {
        throw Exception('Could not build avatar URL');
      }

      print('🔗 Public URL: $imageUrl');

      await supabase.from('profiles').update({'avatar_url': imageUrl}).eq('id', userId);

      if (!context.mounted) return;

      print('✅ Profile updated');

      ref.invalidate(profileByIdProvider(userId));
      ref.invalidate(userProfileProvider);
      await ref.read(profileByIdProvider(userId).future);
      if (context.mounted) setState(() {});

      _profileMessenger((m) {
        m.clearSnackBars();
        m.showSnackBar(
          const SnackBar(
            content: Text('✓ Profile picture updated!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      });
    } on StorageException catch (e) {
      print('❌ Storage error: ${e.message}');
      String errorMessage = 'Upload failed';
      if (e.message.contains('not found')) {
        errorMessage = 'Storage bucket "avatars" not found';
      } else if (e.message.contains('policy')) {
        errorMessage = 'Permission denied';
      }
      _profileMessenger((m) {
        m.clearSnackBars();
        m.showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      });
    } catch (e) {
      print('❌ Error: $e');
      _profileMessenger((m) {
        m.clearSnackBars();
        m.showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  List<Widget> _timelineSlivers() {
    final async = ref.watch(profileTimelineProvider(widget.userId));
    final timelineBadges = ref.watch(profileTimelineAuthorBadgesProvider(widget.userId));
    return [
      async.when(
        data: (entries) {
          if (entries.isEmpty) {
            return const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('No posts yet')),
            );
          }
          final badgeMap = timelineBadges.valueOrNull;
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final e = entries[index];
                return PostCard(
                  post: e.post,
                  leaderboardBadges: badgeMap?[e.post.userId],
                  isReshare: e.isShare,
                  reshareTime: e.isShare ? e.sortTime : null,
                  onReturnFromPostDetail: (_) async {
                    ref.invalidate(profileTimelineProvider(widget.userId));
                  },
                  onLike: () async {
                    await ref
                        .read(feedControllerProvider.notifier)
                        .toggleLike(e.post.postId);
                    ref.invalidate(profileTimelineProvider(widget.userId));
                  },
                  onShare: () async {
                    try {
                      final added = await ref
                          .read(sharePostActionsProvider)
                          .sharePost(e.post.postId);
                      if (!mounted) return;
                      rootScaffoldMessengerKey.currentState?.showSnackBar(
                        SnackBar(
                          content: Text(
                            added
                                ? 'Shared to your profile'
                                : 'Already on your profile',
                          ),
                        ),
                      );
                    } catch (err) {
                      if (!mounted) return;
                      rootScaffoldMessengerKey.currentState?.showSnackBar(
                        SnackBar(
                          content: Text('Share failed: $err'),
                          backgroundColor: AppTheme.errorColor,
                        ),
                      );
                    }
                  },
                );
              },
              childCount: entries.length,
            ),
          );
        },
        loading: () => const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, st) => SliverFillRemaining(
          child: Center(child: Text('Could not load posts: $e')),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final isOwnProfile = currentUser?.id == widget.userId;
    final profileAsync = ref.watch(profileByIdProvider(widget.userId));
    final titleName = profileAsync.asData?.value?.username;

    return Scaffold(
      appBar: AppBar(
        title: Text(titleName ?? 'Profile'),
        actions: [
          if (isOwnProfile)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                print('🔧 AppBar edit button clicked');
                _showEditUsernameDialog();
              },
            ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _profileHeaderBody(context, profile, isOwnProfile),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.paddingL,
                  0,
                  AppTheme.paddingL,
                  AppTheme.paddingS,
                ),
                child: Text(
                  'Posts & shares',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
              ),
            ),
            ..._timelineSlivers(),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.paddingXL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
                const SizedBox(height: AppTheme.paddingM),
                Text('Error loading profile: $error'),
                const SizedBox(height: AppTheme.paddingM),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(profileByIdProvider(widget.userId));
                    ref.invalidate(userProfileProvider);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const double _headerAvatarRadius = 50;

  /// [CircleAvatar] + [CachedNetworkImageProvider] often fails to paint; use [CachedNetworkImage].
  Widget _buildHeaderAvatar(AppProfile? profile, {required bool tappable}) {
    const r = _headerAvatarRadius;
    final d = r * 2;
    final letter = (profile?.username.isNotEmpty == true)
        ? profile!.username[0].toUpperCase()
        : 'U';

    final url = profile?.avatarUrl;
    Widget core;
    if (url != null && url.isNotEmpty) {
      core = ClipOval(
        child: SizedBox(
          width: d,
          height: d,
          child: CachedNetworkImage(
            key: ValueKey<String>(url),
            imageUrl: url,
            fit: BoxFit.cover,
            fadeInDuration: const Duration(milliseconds: 200),
            placeholder: (context, _) => Container(
              color: AppTheme.primaryLight,
              alignment: Alignment.center,
              child: const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (context, _, __) => Container(
              color: AppTheme.primaryLight,
              alignment: Alignment.center,
              child: Text(
                letter,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      core = CircleAvatar(
        radius: r,
        backgroundColor: AppTheme.primaryLight,
        child: Text(
          letter,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (!tappable) {
      return core;
    }
    return GestureDetector(
      onTap: () {
        print('📷 Avatar tapped');
        _showUploadPictureDialog();
      },
      child: core,
    );
  }

  Widget _profileHeaderBody(
    BuildContext context,
    AppProfile? profile,
    bool isOwnProfile,
  ) {
    final statsAsync = ref.watch(profileStatsProvider(widget.userId));
    final viewer = ref.watch(currentUserProvider);

    final d = _headerAvatarRadius * 2;
    Widget avatarChild = _buildHeaderAvatar(profile, tappable: false);
    if (isOwnProfile) {
      avatarChild = GestureDetector(
        onTap: _showUploadPictureDialog,
        child: avatarChild,
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingXL),
      child: Column(
        children: [
          profileHeaderAvatarStack(
            avatarDiameter: d,
            avatar: avatarChild,
            showCameraBadge: isOwnProfile,
            onCameraTap: () {
              print('📷 Camera icon tapped');
              _showUploadPictureDialog();
            },
            cameraBusy: _isUpdating,
          ),
          const SizedBox(height: AppTheme.paddingM),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ref.watch(profileLeaderboardBadgesProvider(widget.userId)).when(
                    data: (badges) {
                      if (!badges.hasAnyBadge) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: LeaderboardBadgesRow(
                          badges: badges,
                          circleSize: 22,
                          hexHeight: 22,
                          spacing: 6,
                        ),
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
              Flexible(
                child: Text(
                  profile?.username ?? 'Unknown',
                  style: Theme.of(context).textTheme.displayMedium,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isOwnProfile) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () {
                    print('✏️ Username edit icon clicked');
                    _showEditUsernameDialog();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Edit username',
                ),
              ],
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Popularity ${profile?.popularityPoints ?? 0}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          if (!isOwnProfile && viewer != null) ...[
            const SizedBox(height: AppTheme.paddingM),
            ref.watch(isFollowingProvider(widget.userId)).when(
                  data: (isFollowing) => SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _followBusy
                          ? null
                          : () async {
                              setState(() => _followBusy = true);
                              try {
                                final actions = ref.read(followActionsProvider);
                                if (isFollowing) {
                                  await actions.unfollow(widget.userId);
                                } else {
                                  await actions.follow(widget.userId);
                                }
                              } catch (e) {
                                _profileMessenger(
                                  (m) => m.showSnackBar(
                                    SnackBar(
                                      content: Text('Follow error: $e'),
                                      backgroundColor: AppTheme.errorColor,
                                    ),
                                  ),
                                );
                              } finally {
                                if (mounted) {
                                  setState(() => _followBusy = false);
                                }
                              }
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: isFollowing
                            ? AppTheme.backgroundColor
                            : AppTheme.primaryColor,
                        foregroundColor: isFollowing
                            ? AppTheme.textPrimary
                            : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(isFollowing ? 'Following' : 'Follow'),
                    ),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
            const SizedBox(height: AppTheme.paddingS),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _dmOpenBusy
                    ? null
                    : () async {
                        setState(() => _dmOpenBusy = true);
                        try {
                          final me = ref.read(currentUserProvider)?.id;
                          if (me == null) return;
                          final threadId = await ref
                              .read(dmRepositoryProvider)
                              .getOrCreateThread(
                                me: me,
                                otherUserId: widget.userId,
                              );
                          final title = profile?.username ?? 'Chat';
                          if (context.mounted) {
                            context.push(
                              '/chats/thread/$threadId',
                              extra: title,
                            );
                          }
                        } catch (e) {
                          _profileMessenger(
                            (m) => m.showSnackBar(
                              SnackBar(
                                content: Text('Could not open chat: $e'),
                                backgroundColor: AppTheme.errorColor,
                              ),
                            ),
                          );
                        } finally {
                          if (mounted) {
                            setState(() => _dmOpenBusy = false);
                          }
                        }
                      },
                icon: _dmOpenBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chat_bubble_outline),
                label: const Text('Message'),
              ),
            ),
          ],
          const SizedBox(height: AppTheme.paddingM),
          statsAsync.when(
            data: (s) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatColumn(context, '${s.postsCount}', 'Posts'),
                _buildStatColumn(context, '${s.followersCount}', 'Followers'),
                _buildStatColumn(context, '${s.followingCount}', 'Following'),
              ],
            ),
            loading: () => Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatColumn(context, '—', 'Posts'),
                _buildStatColumn(context, '—', 'Followers'),
                _buildStatColumn(context, '—', 'Following'),
              ],
            ),
            error: (_, __) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatColumn(context, '0', 'Posts'),
                _buildStatColumn(context, '0', 'Followers'),
                _buildStatColumn(context, '0', 'Following'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: Theme.of(context).textTheme.displayMedium,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

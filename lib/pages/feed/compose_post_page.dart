import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme.dart';
import '../../state/feed/feed_controller.dart';
import '../../state/auth/auth_controller.dart';
import '../../state/social/profile_social.dart';
import '../../state/social/profile_leaderboard_badges.dart';
import '../../widgets/leaderboard_rank_badges.dart';

class ComposePostPage extends ConsumerStatefulWidget {
  const ComposePostPage({super.key});

  @override
  ConsumerState<ComposePostPage> createState() => _ComposePostPageState();
}

class _ComposePostPageState extends ConsumerState<ComposePostPage> {
  static const int _minUploadBytes = 100 * 1024; // 100KB
  static const int _maxUploadBytes = 500 * 1024; // 500KB
  final _contentController = TextEditingController();
  final _imagePicker = ImagePicker();
  XFile? _selectedImage;
  bool _isPosting = false;
  static const List<String> _blockedKeywords = [
    '18+',
    'sex',
    'sexy',
    'porn',
    'xxx',
    'nude',
    'nsfw',
    'adult only',
  ];

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
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
      _ => 'image/jpeg',
    };
  }

  String _publicUrlToString(dynamic raw) {
    if (raw is String) return raw;
    return raw.toString();
  }

  void _composeSnack(SnackBar bar) {
    rootScaffoldMessengerKey.currentState?.showSnackBar(bar);
  }

  Future<Uint8List> _compressToUploadRange(XFile file) async {
    final sourcePath = file.path;
    final original = await file.readAsBytes();
    if (original.lengthInBytes <= _maxUploadBytes) {
      return original;
    }

    // Step down quality until payload reaches <= 500KB.
    for (int quality = 85; quality >= 25; quality -= 10) {
      final out = await FlutterImageCompress.compressWithFile(
        sourcePath,
        quality: quality,
        keepExif: false,
        format: CompressFormat.jpeg,
      );
      if (out == null) continue;
      if (out.lengthInBytes <= _maxUploadBytes) {
        return out;
      }
    }

    // Last attempt: lower resolution + quality.
    final out = await FlutterImageCompress.compressWithFile(
      sourcePath,
      quality: 20,
      minWidth: 1280,
      minHeight: 1280,
      keepExif: false,
      format: CompressFormat.jpeg,
    );
    if (out != null) return out;

    // Fallback to original bytes if compressor fails unexpectedly.
    return original;
  }

  Future<void> _handlePost() async {
    final text = _contentController.text.trim();
    final normalized = text.toLowerCase();
    final hasBlockedText =
        _blockedKeywords.any((k) => normalized.contains(k.toLowerCase()));
    if (text.isEmpty && _selectedImage == null) {
      _composeSnack(
        const SnackBar(
          content: Text('Add text or a photo'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }
    if (hasBlockedText) {
      _composeSnack(
        const SnackBar(
          content: Text('18+ or explicit text is not allowed.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isPosting = true;
    });

    try {
      String? imageUrl;

      if (_selectedImage != null) {
        final userId = ref.read(currentUserProvider)?.id;
        if (userId == null) {
          throw Exception('Not logged in');
        }
        final client = ref.read(supabaseClientProvider);
        final ext = _extensionFromXFile(_selectedImage!);
        // Same bucket + naming as profile avatars: `{uuid}-{suffix}.{ext}` matches
        // storage_avatars_policies.sql (`LIKE auth.uid()||'-%'`). Separate `posts`
        // bucket often has no RLS → upload fails for users who only set up avatars.
        final useJpeg = ext == 'jpg' || ext == 'jpeg' || ext == 'png' || ext == 'webp';
        final uploadExt = useJpeg ? 'jpg' : ext;
        final fileName =
            '$userId-${DateTime.now().millisecondsSinceEpoch}.$uploadExt';
        final bytes = useJpeg
            ? await _compressToUploadRange(_selectedImage!)
            : await _selectedImage!.readAsBytes();

        if (bytes.lengthInBytes > _maxUploadBytes) {
          throw Exception('Image is too large after compression (>500KB).');
        }

        await client.storage.from('avatars').uploadBinary(
              fileName,
              bytes,
              fileOptions: FileOptions(
                contentType: _contentTypeForExt(uploadExt),
                upsert: true,
              ),
            );

        final rawPublicUrl =
            client.storage.from('avatars').getPublicUrl(fileName);
        imageUrl = _publicUrlToString(rawPublicUrl);
        if (imageUrl.isEmpty) {
          throw Exception('Could not build image URL');
        }

        if (bytes.lengthInBytes < _minUploadBytes) {
          // Small images are valid; this keeps user-visible quality high for tiny assets.
          debugPrint('Upload image below 100KB: ${bytes.lengthInBytes} bytes');
        }
      }

      await ref.read(feedControllerProvider.notifier).createPost(
            content: text,
            imageUrl: imageUrl,
          );

      final uid = ref.read(currentUserProvider)?.id;
      if (uid != null) {
        ref.invalidate(profileStatsProvider(uid));
        ref.invalidate(profileTimelineProvider(uid));
      }

      if (!mounted) return;
      _composeSnack(
        const SnackBar(
          content: Text('Post created successfully!'),
          backgroundColor: AppTheme.successColor,
          duration: Duration(seconds: 2),
        ),
      );
      context.pop();
    } catch (e) {
      if (mounted) {
        _composeSnack(
          SnackBar(
            content: Text('Failed to create post: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider);
    final me = ref.watch(currentUserProvider)?.id;
    final myBadges = me != null
        ? ref.watch(profileLeaderboardBadgesProvider(me))
        : null;
    final canPost = (_contentController.text.trim().isNotEmpty ||
            _selectedImage != null) &&
        !_isPosting;

    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: _isPosting ? null : () => context.pop(),
          child: const Text('Cancel'),
        ),
        title: const Text('Create Post'),
        actions: [
          TextButton(
            onPressed: canPost ? _handlePost : null,
            child: _isPosting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Post',
                    style: TextStyle(
                      color: canPost ? AppTheme.primaryColor : AppTheme.textHint,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                  child: userProfile.when(
                    data: (profile) {
                      final b = myBadges?.valueOrNull;
                      return Row(
                        children: [
                          if (b != null && b.hasAnyBadge) ...[
                            LeaderboardBadgesRow(badges: b),
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: Text(
                              profile?.username ?? 'Unknown',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const SizedBox(),
                    error: (_, __) => const Text('Unknown'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.paddingL),
            TextField(
              controller: _contentController,
              maxLines: null,
              minLines: 5,
              decoration: const InputDecoration(
                hintText: "What's on your mind?",
                border: InputBorder.none,
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (_selectedImage != null) ...[
              const SizedBox(height: AppTheme.paddingL),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    child: Image.file(
                      File(_selectedImage!.path),
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: AppTheme.paddingS,
                    right: AppTheme.paddingS,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedImage = null;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppTheme.paddingL),
            OutlinedButton.icon(
              onPressed: _isPosting ? null : _pickImage,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Add Photo'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

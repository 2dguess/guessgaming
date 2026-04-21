import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/theme.dart';
import '../models/app_post.dart';
import '../models/post_gift.dart';
import '../state/auth/auth_controller.dart' show currentUserProvider, supabaseClientProvider;
import '../state/gift/gift_providers.dart';

/// Opens the owner-only list of who sent which gift on this post.
Future<void> openPostGiftSendersSheet(
  BuildContext context,
  WidgetRef ref,
  AppPost post,
) async {
  final client = ref.read(supabaseClientProvider);
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => _PostGiftSendersBody(
      postId: post.postId,
      load: () => fetchPostGiftSendersForOwner(client, post.postId),
    ),
  );
}

/// Compact `+15 🔥` aligned above the Gift button (this post’s gift popularity only).
class PostGiftFireHint extends ConsumerWidget {
  const PostGiftFireHint({super.key, required this.post});

  final AppPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!post.hasGiftActivity) return const SizedBox.shrink();

    final me = ref.watch(currentUserProvider)?.id;
    final isOwner = me != null && me == post.userId;

    final label = '+${post.giftPopularityOnPost} 🔥';
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.primaryColor,
          height: 1.1,
        );

    final child = Text(
      label,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Center(
        child: isOwner
            ? InkWell(
                onTap: () => openPostGiftSendersSheet(context, ref, post),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: child,
                ),
              )
            : child,
      ),
    );
  }
}

class _PostGiftSendersBody extends StatefulWidget {
  const _PostGiftSendersBody({
    required this.postId,
    required this.load,
  });

  final String postId;
  final Future<List<PostGiftSenderLine>> Function() load;

  @override
  State<_PostGiftSendersBody> createState() => _PostGiftSendersBodyState();
}

class _PostGiftSendersBodyState extends State<_PostGiftSendersBody> {
  late Future<List<PostGiftSenderLine>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.load();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<PostGiftSenderLine>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(AppTheme.paddingL),
              child: Text('Could not load: ${snapshot.error}'),
            );
          }
          final rows = snapshot.data ?? [];
          if (rows.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(AppTheme.paddingL),
              child: Text('No gifts on this post yet.'),
            );
          }
          return ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.all(AppTheme.paddingL),
            itemCount: rows.length + 1,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              if (i == 0) {
                return Text(
                  'Gifts on this post',
                  style: Theme.of(context).textTheme.titleMedium,
                );
              }
              final r = rows[i - 1];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  child: Text(
                    r.senderUsername.isNotEmpty
                        ? r.senderUsername[0].toUpperCase()
                        : '?',
                  ),
                ),
                title: Text(r.senderUsername),
                subtitle: Text(
                  '${r.giftTitle} · +${r.popularityPoints} pts',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  _formatTime(r.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime t) {
    final local = t.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

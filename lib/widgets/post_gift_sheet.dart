import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/theme.dart';
import '../models/gift_item.dart';
import '../state/gift/gift_providers.dart';
import '../state/feed/feed_controller.dart';
import '../state/social/profile_social.dart';
import '../state/auth/auth_controller.dart'
    show currentUserProvider, profileByIdProvider, userProfileProvider;

Future<void> showPostGiftPicker({
  required BuildContext context,
  required WidgetRef ref,
  required String postId,
  required String recipientUserId,
}) async {
  final me = ref.read(currentUserProvider)?.id;
  if (me == null) return;
  if (me == recipientUserId) return;

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => _PostGiftSheet(
      postId: postId,
      recipientUserId: recipientUserId,
    ),
  );
}

class _PostGiftSheet extends ConsumerWidget {
  const _PostGiftSheet({
    required this.postId,
    required this.recipientUserId,
  });

  final String postId;
  final String recipientUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final giftsAsync = ref.watch(giftItemsProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingL),
        child: giftsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Failed to load gifts: $e'),
          data: (items) {
            if (items.isEmpty) {
              return const Text('No gifts in shop yet.');
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Send a gift',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Recipient earns popularity points. Cost is deducted from your score.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.paddingL),
                ...items.map((g) => _GiftTile(
                      item: g,
                      onTap: () async {
                        final nav = Navigator.of(context);
                        final res = await sendPostGift(
                          ref,
                          postId: postId,
                          giftItemId: g.id,
                        );
                        if (!context.mounted) return;
                        if (res['ok'] == true) {
                          await ref
                              .read(feedControllerProvider.notifier)
                              .refreshPostGiftStats(postId);
                          ref.invalidate(profileByIdProvider(recipientUserId));
                          ref.invalidate(profileTimelineProvider(recipientUserId));
                          if (ref.read(currentUserProvider)?.id == recipientUserId) {
                            ref.invalidate(userProfileProvider);
                          }
                          nav.pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Sent ${g.title} · +${g.popularityPoints} popularity for them',
                              ),
                              backgroundColor: AppTheme.successColor,
                            ),
                          );
                        } else {
                          final err = '${res['error'] ?? 'failed'}';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                err == 'insufficient_balance'
                                    ? 'Not enough score (need ${g.priceScore})'
                                    : err,
                              ),
                              backgroundColor: AppTheme.errorColor,
                            ),
                          );
                        }
                      },
                    )),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GiftTile extends StatelessWidget {
  const _GiftTile({required this.item, required this.onTap});

  final GiftItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.paddingS),
      child: ListTile(
        leading: Text(
          GiftItem.emojiForKind(item.kind),
          style: const TextStyle(fontSize: 32),
        ),
        title: Text(item.title),
        subtitle: Text('+${item.popularityPoints} popularity for author'),
        trailing: Text(
          '${item.priceScore} score',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
        ),
        onTap: onTap,
      ),
    );
  }
}

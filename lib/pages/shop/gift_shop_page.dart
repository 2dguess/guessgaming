import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../models/gift_item.dart';
import '../../models/post_gift.dart';
import '../../state/gift/gift_providers.dart';

/// Browse gift catalog (prices / popularity). Sending happens from feed posts.
class GiftShopPage extends ConsumerWidget {
  const GiftShopPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(giftItemsProvider);
    final invAsync = ref.watch(userReceivedGiftInventoryProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Gift shop'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No gifts available yet.'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppTheme.paddingXL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.paddingL,
                    AppTheme.paddingL,
                    AppTheme.paddingL,
                    AppTheme.paddingM,
                  ),
                  child: Text(
                    'Use gifts on posts you like in the Feed. Cost is deducted from your score; the post author gains popularity on that post.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingL),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      mainAxisSpacing: AppTheme.paddingS,
                      crossAxisSpacing: AppTheme.paddingS,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) =>
                        _GiftGridCell(item: items[index]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.paddingL,
                    AppTheme.paddingXL,
                    AppTheme.paddingL,
                    AppTheme.paddingS,
                  ),
                  child: Text(
                    'Received on your posts',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                invAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(AppTheme.paddingL),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(AppTheme.paddingL),
                    child: Text('Could not load inventory: $e'),
                  ),
                  data: (lines) {
                    if (lines.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.paddingL,
                        ),
                        child: Text(
                          'No gifts received on your posts yet.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.paddingL,
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < lines.length; i++) ...[
                            if (i > 0) const SizedBox(height: 8),
                            _ReceivedGiftTile(line: lines[i]),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GiftGridCell extends StatelessWidget {
  const _GiftGridCell({required this.item});

  final GiftItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              GiftItem.emojiForKind(item.kind),
              style: const TextStyle(fontSize: 26),
            ),
            const SizedBox(height: 4),
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              '${item.priceScore}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              '+${item.popularityPoints} pop',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 9,
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceivedGiftTile extends StatelessWidget {
  const _ReceivedGiftTile({required this.line});

  final UserReceivedGiftLine line;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Text(
          GiftItem.emojiForKind(line.kind),
          style: const TextStyle(fontSize: 32),
        ),
        title: Text(line.title),
        subtitle: Text('+${line.totalPopularity} popularity from these gifts'),
        trailing: Text(
          '×${line.giftCount}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
        ),
      ),
    );
  }
}

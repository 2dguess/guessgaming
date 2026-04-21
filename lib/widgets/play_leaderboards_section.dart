import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/theme.dart';
import '../state/betting/play_leaderboards.dart';

/// Leaderboards: total score + best single match (see SQL).
/// When [forceSideBySide] is true, Top score and Best match are always in one row.
/// When [forceVertical] is true, the two leaderboard cards always stack.
class PlayLeaderboardsSection extends ConsumerWidget {
  const PlayLeaderboardsSection({
    super.key,
    this.forceVertical = false,
    this.forceSideBySide = false,
    this.denseBottomPadding = false,
  });

  final bool forceVertical;
  final bool forceSideBySide;
  final bool denseBottomPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(playLeaderboardsProvider);

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.only(bottom: AppTheme.paddingL),
        child: Center(child: LinearProgressIndicator(minHeight: 3)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) {
        final scoreCard = _LeaderboardCard(
          title: 'Top score',
          subtitle: 'Wallet score · All time · Top 10',
          icon: Icons.emoji_events,
          accent: const Color(0xFFC9A227),
          entries: data.byScore,
          valueLabel: 'score',
          emptyHint: 'No players yet',
        );
        final matchCard = _LeaderboardCard(
          title: 'Best match',
          subtitle: 'Largest single win (score) · All time · Top 10',
          icon: Icons.bolt,
          accent: const Color(0xFF5E35B1),
          entries: data.byBestMatch,
          valueLabel: 'score',
          emptyHint: 'No wins yet',
        );

        final inner = LayoutBuilder(
          builder: (context, constraints) {
            if (forceSideBySide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: scoreCard),
                  const SizedBox(width: AppTheme.paddingM),
                  Expanded(child: matchCard),
                ],
              );
            }
            if (forceVertical) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  scoreCard,
                  const SizedBox(height: AppTheme.paddingM),
                  matchCard,
                ],
              );
            }
            final wide = constraints.maxWidth >= 560;
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: scoreCard),
                  const SizedBox(width: AppTheme.paddingM),
                  Expanded(child: matchCard),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                scoreCard,
                const SizedBox(height: AppTheme.paddingM),
                matchCard,
              ],
            );
          },
        );

        return Padding(
          padding: EdgeInsets.only(
            bottom: denseBottomPadding ? AppTheme.paddingS : AppTheme.paddingL,
          ),
          child: inner,
        );
      },
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  const _LeaderboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.entries,
    required this.valueLabel,
    required this.emptyHint,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final List<PlayLeaderboardEntry> entries;
  final String valueLabel;
  final String emptyHint;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.cardColor,
              AppTheme.cardColor,
              accent.withValues(alpha: 0.06),
            ],
          ),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    ),
                    child: Icon(icon, color: accent, size: 22),
                  ),
                  const SizedBox(width: AppTheme.paddingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.paddingM),
              if (entries.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppTheme.paddingL),
                  child: Center(
                    child: Text(
                      emptyHint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textHint,
                          ),
                    ),
                  ),
                )
              else
                ...entries.map((e) => _LeaderboardRow(
                      entry: e,
                      accent: accent,
                      valueLabel: valueLabel,
                    )),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.entry,
    required this.accent,
    required this.valueLabel,
  });

  final PlayLeaderboardEntry entry;
  final Color accent;
  final String valueLabel;

  Color _medalColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final letter = entry.username.isNotEmpty
        ? entry.username[0].toUpperCase()
        : '?';

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
          onTap: () => context.push('/profile/${entry.userId}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '${entry.rank}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: _medalColor(entry.rank),
                    ),
                  ),
                ),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: accent.withValues(alpha: 0.2),
                  child: entry.avatarUrl != null && entry.avatarUrl!.isNotEmpty
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: entry.avatarUrl!,
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Text(
                              letter,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: accent,
                              ),
                            ),
                          ),
                        )
                      : Text(
                          letter,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: accent,
                          ),
                        ),
                ),
                const SizedBox(width: AppTheme.paddingS),
                Expanded(
                  child: Text(
                    entry.username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Text(
                  '${entry.value} $valueLabel',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

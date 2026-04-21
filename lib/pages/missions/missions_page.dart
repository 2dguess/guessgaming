import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../state/games/math_game_daily_play.dart';
import '../../state/betting/betting_controller.dart';
import '../../state/missions/missions_controller.dart';

class MissionsPage extends ConsumerStatefulWidget {
  const MissionsPage({super.key});

  @override
  ConsumerState<MissionsPage> createState() => _MissionsPageState();
}

class _MissionsPageState extends ConsumerState<MissionsPage> {
  final Set<String> _watchedAdMissionIds = <String>{};
  final Set<String> _goReadyMissionIds = <String>{};
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(missionsControllerProvider.notifier).loadData());
  }

  Future<void> _openMissionLink(String? link) async {
    if (link == null || link.isEmpty) return;
    final uri = Uri.tryParse(link);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _handleClaimMission({
    required String missionId,
    required String? missionKind,
    required String? proofUrl,
  }) async {
    if (missionKind == 'reward_ad' &&
        !_watchedAdMissionIds.contains(missionId)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Watch ads first'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
      }
      return;
    }

    final result = await ref.read(missionsControllerProvider.notifier).submitMissionClaim(
          missionId: missionId,
          proofText: missionKind == 'reward_ad' ? 'reward_ad_watched' : null,
          proofUrl: proofUrl,
          adWatched: missionKind == 'reward_ad',
        );
    final success = result['ok'] == true;

    if (mounted) {
      if (success) {
        await ref.read(bettingControllerProvider.notifier).loadData();
        if (!mounted) return;
        final status = '${result['status'] ?? ''}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'pending'
                  ? 'Mission claim submitted. Admin will review.'
                  : 'Mission completed! Score added to your balance.',
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else {
        final error =
            (result['error'] as String?) ?? ref.read(missionsControllerProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to claim mission'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Widget _buildMathGamePromo(AsyncValue<MathGameDailyPlay> dailyAsync) {
    final daily = dailyAsync.valueOrNull;
    final atLimit = daily != null && !daily.canStartNewGame;

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.paddingL),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (atLimit) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Daily limit reached (20 games). Please try again after 1:00 AM.'),
                backgroundColor: AppTheme.warningColor,
              ),
            );
            return;
          }
          context.push('/games/math-quiz');
        },
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingL),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.paddingM),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: const Icon(
                  Icons.calculate,
                  color: AppTheme.successColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppTheme.paddingL),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Number Quiz',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        dailyAsync.when(
                          data: (d) => Text(
                            d.label,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: atLimit ? AppTheme.warningColor : AppTheme.primaryColor,
                                ),
                          ),
                          loading: () => Text(
                            '…/$mathGameDailyMaxPlays',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                          ),
                          error: (_, __) => Text(
                            '0/$mathGameDailyMaxPlays',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add / Subtract / Multiply - complete with 3 correct answers',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppTheme.textSecondary.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeRemaining(DateTime nextClaimTime) {
    final now = DateTime.now();
    final difference = nextClaimTime.difference(now);

    if (difference.isNegative) {
      return 'Available now';
    }

    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;

    if (hours > 0) {
      return 'Available in ${hours}h ${minutes}m';
    } else {
      return 'Available in ${minutes}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    final missionsState = ref.watch(missionsControllerProvider);
    final mathDailyAsync = ref.watch(mathGameDailyPlayProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/picks');
            }
          },
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, color: AppTheme.warningColor),
            const SizedBox(width: AppTheme.paddingS),
            Text(
              '${missionsState.wallet?.availableScore ?? 0} score',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: const [
          SizedBox(width: 48),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(mathGameDailyPlayProvider);
          await ref.read(missionsControllerProvider.notifier).loadData();
        },
        child: missionsState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                    padding: const EdgeInsets.all(AppTheme.paddingL),
                    itemCount: missionsState.missions.isEmpty
                        ? 2
                        : 1 + missionsState.missions.length,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildMathGamePromo(mathDailyAsync);
                      }
                      if (missionsState.missions.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.only(top: AppTheme.paddingXL),
                          child: Center(
                            child: Text('No missions available'),
                          ),
                        );
                      }
                      final mission = missionsState.missions[index - 1];
                      final isRewardAd = mission.missionKind == 'reward_ad';
                      final watchedAd = _watchedAdMissionIds.contains(mission.missionId);
                      final isDaily = mission.missionType == 'daily_free_coin';
                      final canClaim = missionsState.canClaimMission(mission.missionId);
                      final claimedToday = missionsState.claimedOrSubmittedToday
                          .contains(mission.missionId);
                      final goReady = _goReadyMissionIds.contains(mission.missionId);
                      final nextClaimTime = missionsState.getNextClaimTime(mission.missionId);
                      if (claimedToday) {
                        return const SizedBox.shrink();
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: AppTheme.paddingL),
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.paddingL),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(AppTheme.paddingM),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryLight.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                    ),
                                    child: Icon(
                                      mission.title.toLowerCase().contains('login')
                                          ? Icons.login
                                          : mission.title.toLowerCase().contains('coin') ||
                                                  mission.title.toLowerCase().contains('score') ||
                                                  mission.title.toLowerCase().contains('free')
                                              ? Icons.monetization_on
                                              : Icons.task_alt,
                                      color: AppTheme.primaryColor,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.paddingL),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          mission.title,
                                          style: Theme.of(context).textTheme.displaySmall,
                                        ),
                                        const SizedBox(height: AppTheme.paddingS),
                                        Text(
                                          (mission.description ?? '')
                                                  .toLowerCase()
                                                  .contains('created from admin mobile app')
                                              ? ''
                                              : (mission.description ?? ''),
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.paddingL),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppTheme.paddingM,
                                      vertical: AppTheme.paddingS,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.warningColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.monetization_on,
                                          color: AppTheme.warningColor,
                                          size: 18,
                                        ),
                                        const SizedBox(width: AppTheme.paddingS),
                                        Text(
                                          '${mission.rewardAmount} score',
                                          style: const TextStyle(
                                            color: AppTheme.warningColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  if ((mission.actionLink ?? '').isNotEmpty)
                                    TextButton(
                                      onPressed: () => _openMissionLink(mission.actionLink),
                                      child: const Text('Open Link'),
                                    ),
                                  if (!isDaily && (isRewardAd && !watchedAd))
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _watchedAdMissionIds.add(mission.missionId);
                                          _goReadyMissionIds.add(mission.missionId);
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Ads watched. Claim is now enabled.'),
                                            backgroundColor: AppTheme.successColor,
                                          ),
                                        );
                                      },
                                      child: const Text('Watch Ads'),
                                    ),
                                  if (!isDaily && !isRewardAd && !goReady)
                                    TextButton(
                                      onPressed: () async {
                                        await _openMissionLink(mission.actionLink);
                                        if (!mounted) return;
                                        setState(() {
                                          _goReadyMissionIds.add(mission.missionId);
                                        });
                                      },
                                      child: const Text('Go'),
                                    ),
                                  const SizedBox(width: AppTheme.paddingS),
                                  if (!canClaim && nextClaimTime != null)
                                    Text(
                                      _formatTimeRemaining(nextClaimTime),
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: AppTheme.textSecondary,
                                          ),
                                    ),
                                  const SizedBox(width: AppTheme.paddingM),
                                  ElevatedButton(
                                    onPressed: (isDaily
                                                ? canClaim
                                                : (goReady &&
                                                    canClaim &&
                                                    (!isRewardAd || watchedAd)))
                                        ? () => _handleClaimMission(
                                              missionId: mission.missionId,
                                              missionKind: mission.missionKind,
                                              proofUrl: mission.actionLink,
                                            )
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: canClaim
                                          ? AppTheme.successColor
                                          : AppTheme.textHint,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppTheme.paddingL,
                                        vertical: AppTheme.paddingM,
                                      ),
                                    ),
                                    child: Text(
                                      !isDaily && isRewardAd && !watchedAd
                                          ? 'Watch Ads'
                                          : (!isDaily && !goReady)
                                              ? 'Go'
                                              : (canClaim ? 'Claim' : 'Claimed'),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

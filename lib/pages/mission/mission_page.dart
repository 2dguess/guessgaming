import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../state/betting/betting_controller.dart';
import '../../state/mission/mission_controller.dart';

class MissionPage extends ConsumerStatefulWidget {
  const MissionPage({super.key});

  @override
  ConsumerState<MissionPage> createState() => _MissionPageState();
}

class _MissionPageState extends ConsumerState<MissionPage> {
  final Set<String> _watchedAdMissionIds = <String>{};

  Future<void> _openMissionLink(String? link) async {
    if (link == null || link.isEmpty) return;
    final uri = Uri.tryParse(link);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(missionControllerProvider.notifier).loadData());
  }

  Future<void> _handleClaimMission({
    required String missionId,
    required int reward,
    required String? missionKind,
    required String? proofUrl,
  }) async {
    if (missionKind == 'reward_ad') {
      if (!_watchedAdMissionIds.contains(missionId)) {
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
    }

    final response = await ref.read(missionControllerProvider.notifier).submitMissionClaim(
          missionId: missionId,
          proofText: missionKind == 'reward_ad' ? 'reward_ad_watched' : null,
          proofUrl: proofUrl,
          adWatched: missionKind == 'reward_ad',
        );
    final success = response['ok'] == true;

    if (mounted) {
      if (success) {
        await ref.read(bettingControllerProvider.notifier).loadData();
        if (!mounted) return;
        final status = '${response['status'] ?? ''}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'pending'
                  ? 'Claim submitted. Admin will review.'
                  : 'Claimed $reward score successfully!',
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else {
        final error = (response['error'] as String?) ??
            ref.read(missionControllerProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to claim mission'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final missionState = ref.watch(missionControllerProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Missions'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(missionControllerProvider.notifier).loadData(),
        child: missionState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.paddingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      color: AppTheme.primaryColor,
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.paddingXL),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.emoji_events,
                              size: 48,
                              color: Colors.white,
                            ),
                            const SizedBox(height: AppTheme.paddingM),
                            const Text(
                              'Your Balance',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: AppTheme.paddingS),
                            Text(
                              '${missionState.wallet?.availableScore ?? 0} score',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.paddingXL),
                    Text(
                      'Available Missions',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const SizedBox(height: AppTheme.paddingL),
                    if (missionState.missions.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppTheme.paddingXL),
                          child: Text('No missions available'),
                        ),
                      )
                    else
                      ...missionState.missions.map((mission) {
                        final canClaim = ref
                            .read(missionControllerProvider.notifier)
                            .canClaimMission(mission.missionId);
                        final timeUntilNext = ref
                            .read(missionControllerProvider.notifier)
                            .timeUntilNextClaim(mission.missionId);

                        return _buildMissionCard(
                          mission: mission,
                          canClaim: canClaim,
                          timeUntilNext: timeUntilNext,
                        );
                      }),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildMissionCard({
    required mission,
    required bool canClaim,
    Duration? timeUntilNext,
  }) {
    final isRewardAd = mission.missionKind == 'reward_ad';
    final watchedAd = _watchedAdMissionIds.contains(mission.missionId);
    final claimEnabled = isRewardAd ? watchedAd && canClaim : canClaim;
    final hasLink = (mission.actionLink ?? '').isNotEmpty;

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
                  child: const Icon(
                    Icons.calendar_today,
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
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (mission.description != null) ...[
                        if (!(mission.description!
                            .toLowerCase()
                            .contains('created from admin mobile app'))) ...[
                        const SizedBox(height: AppTheme.paddingXS),
                        Text(
                          mission.description!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                        ],
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.paddingL),
            Row(
              children: [
                const Icon(
                  Icons.monetization_on,
                  color: AppTheme.warningColor,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.paddingS),
                Text(
                  '${mission.rewardAmount} score',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.warningColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.paddingL),
            SizedBox(
              width: double.infinity,
              child: Row(
                children: [
                  if (hasLink) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openMissionLink(mission.actionLink),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Open Link'),
                      ),
                    ),
                    const SizedBox(width: AppTheme.paddingS),
                  ],
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: claimEnabled
                          ? () => _handleClaimMission(
                                missionId: mission.missionId,
                                reward: mission.rewardAmount,
                                missionKind: mission.missionKind,
                                proofUrl: mission.actionLink,
                              )
                          : null,
                      icon: Icon(
                        claimEnabled ? Icons.card_giftcard : Icons.check_circle,
                      ),
                      label: Text(
                        isRewardAd && !watchedAd
                            ? 'Watch Ads'
                            : canClaim
                                ? 'Claim Now'
                                : timeUntilNext != null
                                    ? 'Available in ${_formatDuration(timeUntilNext)}'
                                    : 'Claimed Today',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            claimEnabled ? AppTheme.successColor : AppTheme.textHint,
                        padding: const EdgeInsets.all(AppTheme.paddingM),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isRewardAd && !watchedAd) ...[
              const SizedBox(height: AppTheme.paddingS),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _watchedAdMissionIds.add(mission.missionId);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ads watched. You can claim now.'),
                        backgroundColor: AppTheme.successColor,
                      ),
                    );
                  },
                  child: const Text('Simulate Watch Ads'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }
}

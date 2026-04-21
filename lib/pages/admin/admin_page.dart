import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../models/gift_item.dart';
import '../../state/admin/admin_controller.dart';
import '../../state/gift/gift_providers.dart';
import '../../widgets/live_proto_metrics_card.dart';

class AdminPage extends ConsumerStatefulWidget {
  const AdminPage({super.key});

  @override
  ConsumerState<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends ConsumerState<AdminPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _userIdController = TextEditingController();
  final _deltaController = TextEditingController();
  final _reasonController = TextEditingController();
  final _missionTitleController = TextEditingController();
  final _missionRewardController = TextEditingController(text: '5000');
  final _missionLinkController = TextEditingController();
  final _postIdController = TextEditingController();
  final _fundAmountController = TextEditingController();
  final _fundReasonController = TextEditingController(text: 'Manual score grant');
  String _adminMissionType = 'daily';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _userIdController.dispose();
    _deltaController.dispose();
    _reasonController.dispose();
    _missionTitleController.dispose();
    _missionRewardController.dispose();
    _missionLinkController.dispose();
    _postIdController.dispose();
    _fundAmountController.dispose();
    _fundReasonController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.errorColor : AppTheme.successColor,
      ),
    );
  }

  Future<void> _refreshAll() async {
    ref.invalidate(adminWalletBalanceProvider);
    ref.invalidate(adminTopUsersProvider);
    ref.invalidate(adminRecentAuditProvider);
    ref.invalidate(adminReportedPostsProvider);
    ref.invalidate(adminPendingPostModerationProvider);
    ref.invalidate(adminBetKpisProvider);
    ref.invalidate(adminLatestPayoutRunProvider);
    ref.invalidate(adminLatestPayoutRunStatsProvider);
    ref.invalidate(adminGiftItemsProvider);
    ref.invalidate(giftItemsProvider);
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }

  @override
  Widget build(BuildContext context) {
    final adminCheck = ref.watch(isAdminProvider);

    return adminCheck.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Admin')),
        body: Center(child: Text('Failed to check admin permission: $e')),
      ),
      data: (isAdmin) {
        if (!isAdmin) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Admin'),
              leading: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back),
              ),
            ),
            body: const Center(
              child: Text('You do not have admin permission yet.'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Admin Console'),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: const [
                Tab(text: 'Dashboard'),
                Tab(text: 'Mission'),
                Tab(text: 'Moderation'),
                Tab(text: 'Ledger'),
                Tab(text: 'Gifts'),
              ],
            ),
            actions: [
              IconButton(
                onPressed: _refreshAll,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildDashboardTab(),
              _buildMissionTab(),
              _buildModerationTab(),
              _buildLedgerTab(),
              _buildGiftsTab(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDashboardTab() {
    final wallet = ref.watch(adminWalletBalanceProvider);
    final topUsers = ref.watch(adminTopUsersProvider);
    final totalUserBalance = ref.watch(adminTotalUserBalanceProvider);
    final audits = ref.watch(adminRecentAuditProvider);
    final stats = ref.watch(adminDashboardStatsProvider);
    final preset = ref.watch(adminStatsPresetProvider);
    final latestRun = ref.watch(adminLatestPayoutRunProvider);
    final latestRunStats = ref.watch(adminLatestPayoutRunStatsProvider);

    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: ListView(
        padding: const EdgeInsets.all(AppTheme.paddingL),
        children: [
          if (kDebugMode) ...[
            Text('Realtime (Debug)',
                style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: AppTheme.paddingS),
            const LiveProtoMetricsCard(),
            const SizedBox(height: AppTheme.paddingL),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  wallet.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('House pool error: $e'),
                    data: (balance) => Text(
                      'House score pool (virtual): $balance',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                  ),
                  const SizedBox(height: AppTheme.paddingM),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _fundAmountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Add score (amount)',
                            hintText: '100000',
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.paddingS),
                      Expanded(
                        child: TextField(
                          controller: _fundReasonController,
                          decoration: const InputDecoration(
                            labelText: 'Reason',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.paddingS),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () async {
                        final amount =
                            int.tryParse(_fundAmountController.text.trim());
                        final reason = _fundReasonController.text.trim();
                        if (amount == null || amount <= 0) {
                          _showMessage('Enter valid amount', isError: true);
                          return;
                        }
                        try {
                          await ref.read(adminActionsProvider).fundAdminWallet(
                                amount: amount,
                                reason: reason.isEmpty ? 'Manual score grant' : reason,
                              );
                          _showMessage('House pool updated');
                          _fundAmountController.clear();
                          ref.invalidate(adminWalletBalanceProvider);
                          ref.invalidate(adminRecentAuditProvider);
                        } catch (e) {
                          _showMessage('Add score failed: $e', isError: true);
                        }
                      },
                      child: const Text('Add virtual score'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.paddingL),
          Text('Latest reward batch',
              style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: AppTheme.paddingS),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.paddingL),
              child: latestRun.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Reward batch error: $e'),
                data: (run) {
                  if (run == null) {
                    return const Text('No reward batch yet');
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Run: ${run['run_id']}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppTheme.paddingS),
                      Text(
                        'Result digit: ${run['winning_digit']} | Matched users: ${run['total_winners']} | Score sent: ${run['total_payout']}',
                      ),
                      const SizedBox(height: AppTheme.paddingS),
                      Text(
                        'Status: ${run['status']} | Batch: ${run['batch_count']} in ${run['window_minutes']} min',
                      ),
                      const SizedBox(height: AppTheme.paddingM),
                      latestRunStats.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => Text('Run stats error: $e'),
                        data: (s) => Row(
                          children: [
                            Expanded(
                                child: _kpiTile('Queued', '${s['queued'] ?? 0}')),
                            Expanded(
                                child: _kpiTile(
                                    'Processing', '${s['processing'] ?? 0}')),
                            Expanded(
                                child: _kpiTile('Paid', '${s['paid'] ?? 0}')),
                            Expanded(
                                child: _kpiTile('Failed', '${s['failed'] ?? 0}')),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: AppTheme.paddingL),
          Text('Play stats (score)',
              style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: AppTheme.paddingS),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _presetChip('3:30h', AdminStatsPreset.session330, preset),
              _presetChip('1D', AdminStatsPreset.day, preset),
              _presetChip('1W', AdminStatsPreset.week, preset),
              _presetChip('1M', AdminStatsPreset.month, preset),
              _presetChip('Custom', AdminStatsPreset.custom, preset),
            ],
          ),
          const SizedBox(height: AppTheme.paddingS),
          if (preset == AdminStatsPreset.custom) _buildCustomRangePicker(),
          const SizedBox(height: AppTheme.paddingS),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.paddingL),
              child: stats.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Stats error: $e'),
                data: (k) => Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _kpiTile('Players (entries)', '${k['total_bet_user'] ?? 0}')),
                        Expanded(child: _kpiTile('Matched users', '${k['total_win_user'] ?? 0}')),
                        Expanded(child: _kpiTile('Not matched users', '${k['total_lose_user'] ?? 0}')),
                      ],
                    ),
                    const SizedBox(height: AppTheme.paddingM),
                    Row(
                      children: [
                        Expanded(child: _kpiTile('Total entry (score)', '${k['total_bet_amount'] ?? 0}')),
                        Expanded(child: _kpiTile('Matched payout (score)', '${k['total_win_bet_amount'] ?? 0}')),
                        Expanded(child: _kpiTile('Not matched (score)', '${k['total_bet_lose_amount'] ?? 0}')),
                      ],
                    ),
                    const SizedBox(height: AppTheme.paddingM),
                    Row(
                      children: [
                        Expanded(child: _kpiTile('House score paid out', '${k['admin_payout_amount'] ?? 0}')),
                        Expanded(child: _kpiTile('House net (virtual)', '${k['admin_profit_amount'] ?? 0}')),
                        const Expanded(child: SizedBox()),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.paddingL),
          totalUserBalance.when(
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
            data: (v) => Text(
              'Total User Balance (non-admin): $v',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: AppTheme.paddingS),
          Text('Top 10 User Balances',
              style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: AppTheme.paddingS),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.paddingM),
              child: topUsers.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Top users error: $e'),
                data: (rows) => Column(
                  children: rows
                      .map(
                        (r) => ListTile(
                          dense: true,
                          title: Text('${r['username'] ?? 'unknown'}'),
                          subtitle: Text(
                            'Inflow: ${r['inflow']} | Outflow: ${r['outflow']} | Round wins: ${r['bet_win_inflow']}',
                          ),
                          trailing: Text('${r['balance']}'),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.paddingL),
          Text('Recent Admin Actions',
              style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: AppTheme.paddingS),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.paddingM),
              child: audits.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Audit logs error: $e'),
                data: (rows) => Column(
                  children: rows
                      .map(
                        (r) => ListTile(
                          dense: true,
                          title: Text('${r['action']} (${r['target_type']})'),
                          subtitle: Text(
                            '${r['reason'] ?? '-'}\n${r['created_at'] ?? ''}',
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionTab() {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.paddingL),
      children: [
        Text('Create Mission', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: AppTheme.paddingS),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.paddingL),
            child: Column(
              children: [
                TextField(
                  controller: _missionTitleController,
                  decoration: const InputDecoration(
                    labelText: 'Mission title',
                    hintText: 'Daily bonus / Watch sponsor clip',
                  ),
                ),
                const SizedBox(height: AppTheme.paddingS),
                DropdownButtonFormField<String>(
                  initialValue: _adminMissionType,
                  decoration: const InputDecoration(labelText: 'Mission type'),
                  items: const [
                    DropdownMenuItem(
                      value: 'daily',
                      child: Text('Daily free score mission'),
                    ),
                    DropdownMenuItem(
                      value: 'ads',
                      child: Text('Ads mission'),
                    ),
                  ],
                  onChanged: (v) =>
                      setState(() => _adminMissionType = v ?? 'daily'),
                ),
                const SizedBox(height: AppTheme.paddingS),
                TextField(
                  controller: _missionRewardController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Reward score',
                    hintText: '5000',
                  ),
                ),
                if (_adminMissionType == 'ads') ...[
                  const SizedBox(height: AppTheme.paddingS),
                  TextField(
                    controller: _missionLinkController,
                    decoration: const InputDecoration(
                      labelText: 'Ad / landing page link (optional)',
                      hintText: 'https://...',
                    ),
                  ),
                ],
                const SizedBox(height: AppTheme.paddingM),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final title = _missionTitleController.text.trim();
                      final reward =
                          int.tryParse(_missionRewardController.text.trim());
                      if (title.isEmpty || reward == null || reward <= 0) {
                        _showMessage(
                          'Enter valid mission title and reward',
                          isError: true,
                        );
                        return;
                      }
                      try {
                        final missionType = _adminMissionType == 'daily'
                            ? 'daily_free_coin'
                            : 'ads_mission';
                        final missionKind = _adminMissionType == 'ads'
                            ? 'reward_ad'
                            : 'custom';
                        await ref.read(adminActionsProvider).upsertMission(
                              title: title,
                              missionType: missionType,
                              rewardCoin: reward,
                              description: null,
                              actionLink: _missionLinkController.text.trim().isEmpty
                                  ? null
                                  : _missionLinkController.text.trim(),
                              platform: 'custom',
                              missionKind: missionKind,
                              missionAction: 'custom',
                            );
                        _showMessage('Mission created');
                        _missionTitleController.clear();
                        _missionLinkController.clear();
                      } catch (e) {
                        _showMessage('Create mission failed: $e', isError: true);
                      }
                    },
                    child: const Text('Create Mission'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModerationTab() {
    final reported = ref.watch(adminReportedPostsProvider);
    final pendingPosts = ref.watch(adminPendingPostModerationProvider);
    return ListView(
      padding: const EdgeInsets.all(AppTheme.paddingL),
      children: [
        Text('Ban / Unban User', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: AppTheme.paddingS),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.paddingL),
            child: Column(
              children: [
                TextField(
                  controller: _userIdController,
                  decoration: const InputDecoration(labelText: 'User UUID'),
                ),
                const SizedBox(height: AppTheme.paddingS),
                TextField(
                  controller: _reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Reason',
                    hintText: 'Spam posts',
                  ),
                ),
                const SizedBox(height: AppTheme.paddingM),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final userId = _userIdController.text.trim();
                          if (userId.isEmpty) return;
                          try {
                            await ref.read(adminActionsProvider).banUser(
                                  userId: userId,
                                  isBanned: true,
                                  reason: _reasonController.text.trim(),
                                );
                            _showMessage('User banned');
                          } catch (e) {
                            _showMessage('Ban failed: $e', isError: true);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.errorColor,
                        ),
                        child: const Text('Ban'),
                      ),
                    ),
                    const SizedBox(width: AppTheme.paddingS),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final userId = _userIdController.text.trim();
                          if (userId.isEmpty) return;
                          try {
                            await ref.read(adminActionsProvider).banUser(
                                  userId: userId,
                                  isBanned: false,
                                );
                            _showMessage('User unbanned');
                          } catch (e) {
                            _showMessage('Unban failed: $e', isError: true);
                          }
                        },
                        child: const Text('Unban'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTheme.paddingL),
        Text('Soft Delete Post', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: AppTheme.paddingS),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.paddingL),
            child: Column(
              children: [
                TextField(
                  controller: _postIdController,
                  decoration: const InputDecoration(labelText: 'Post UUID'),
                ),
                const SizedBox(height: AppTheme.paddingM),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final postId = _postIdController.text.trim();
                      if (postId.isEmpty) return;
                      try {
                        await ref.read(adminActionsProvider).softDeletePost(
                              postId: postId,
                              reason: 'Spam',
                            );
                        _showMessage('Post soft-deleted');
                      } catch (e) {
                        _showMessage('Delete failed: $e', isError: true);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.warningColor,
                    ),
                    child: const Text('Soft Delete Post'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTheme.paddingL),
        Text('Reported Posts Queue',
            style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: AppTheme.paddingS),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.paddingM),
            child: reported.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Reported posts error: $e'),
              data: (rows) => rows.isEmpty
                  ? const Text('No pending reports')
                  : Column(
                      children: rows
                          .map(
                            (r) => ListTile(
                              dense: true,
                              title: Text('Post: ${r['post_id']}'),
                              subtitle: Text(
                                'Reason: ${r['reason']}\nReporter: ${r['reporter_user_id']}',
                              ),
                              trailing: Wrap(
                                spacing: 8,
                                children: [
                                  TextButton(
                                    onPressed: () async {
                                      try {
                                        await ref
                                            .read(adminActionsProvider)
                                            .softDeletePost(
                                              postId: '${r['post_id']}',
                                              reason: 'Reported spam',
                                            );
                                        await ref
                                            .read(adminActionsProvider)
                                            .reviewReportedPost(
                                              reportId: '${r['report_id']}',
                                              status: 'action_taken',
                                            );
                                        _showMessage('Post deleted and report closed');
                                        ref.invalidate(adminReportedPostsProvider);
                                        ref.invalidate(adminRecentAuditProvider);
                                      } catch (e) {
                                        _showMessage(
                                          'Action failed: $e',
                                          isError: true,
                                        );
                                      }
                                    },
                                    child: const Text('Delete'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      try {
                                        await ref
                                            .read(adminActionsProvider)
                                            .reviewReportedPost(
                                              reportId: '${r['report_id']}',
                                              status: 'dismissed',
                                            );
                                        _showMessage('Report dismissed');
                                        ref.invalidate(adminReportedPostsProvider);
                                        ref.invalidate(adminRecentAuditProvider);
                                      } catch (e) {
                                        _showMessage(
                                          'Dismiss failed: $e',
                                          isError: true,
                                        );
                                      }
                                    },
                                    child: const Text('Dismiss'),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.paddingL),
        Text('Pending/Blocked Posts (18+ guard)',
            style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: AppTheme.paddingS),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.paddingM),
            child: pendingPosts.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Pending posts error: $e'),
              data: (rows) => rows.isEmpty
                  ? const Text('No pending/blocked posts')
                  : Column(
                      children: rows
                          .map(
                            (r) => ListTile(
                              dense: true,
                              title: Text('Post: ${r['post_id']}'),
                              subtitle: Text(
                                'Status: ${r['moderation_status']}\nReason: ${r['moderation_reason'] ?? '-'}',
                              ),
                              trailing: Wrap(
                                spacing: 8,
                                children: [
                                  TextButton(
                                    onPressed: () async {
                                      try {
                                        await ref
                                            .read(adminActionsProvider)
                                            .setPostModeration(
                                              postId: '${r['post_id']}',
                                              status: 'approved',
                                              reason: 'Approved by admin',
                                            );
                                        _showMessage('Post approved');
                                        ref.invalidate(adminPendingPostModerationProvider);
                                      } catch (e) {
                                        _showMessage('Approve failed: $e',
                                            isError: true);
                                      }
                                    },
                                    child: const Text('Approve'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      try {
                                        await ref
                                            .read(adminActionsProvider)
                                            .setPostModeration(
                                              postId: '${r['post_id']}',
                                              status: 'rejected',
                                              reason: 'Rejected for safety',
                                            );
                                        _showMessage('Post rejected');
                                        ref.invalidate(adminPendingPostModerationProvider);
                                      } catch (e) {
                                        _showMessage('Reject failed: $e',
                                            isError: true);
                                      }
                                    },
                                    child: const Text('Reject'),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _kpiTile(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLedgerTab() {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.paddingL),
      children: [
        Text('Manual score adjustment',
            style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: AppTheme.paddingS),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.paddingL),
            child: Column(
              children: [
                TextField(
                  controller: _userIdController,
                  decoration: const InputDecoration(labelText: 'User UUID'),
                ),
                const SizedBox(height: AppTheme.paddingS),
                TextField(
                  controller: _deltaController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Delta (example: +5000 or -3000)',
                  ),
                ),
                const SizedBox(height: AppTheme.paddingS),
                TextField(
                  controller: _reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Reason',
                    hintText: 'Mission manual reward',
                  ),
                ),
                const SizedBox(height: AppTheme.paddingM),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final userId = _userIdController.text.trim();
                      final delta = int.tryParse(_deltaController.text.trim());
                      final reason = _reasonController.text.trim();
                      if (userId.isEmpty || delta == null || reason.isEmpty) {
                        _showMessage(
                          'Enter user UUID, delta and reason',
                          isError: true,
                        );
                        return;
                      }
                      try {
                        await ref.read(adminActionsProvider).adjustUserCoin(
                              userId: userId,
                              delta: delta,
                              reason: reason,
                            );
                        _showMessage('Score updated');
                        _deltaController.clear();
                        ref.invalidate(adminTopUsersProvider);
                        ref.invalidate(adminWalletBalanceProvider);
                        ref.invalidate(adminRecentAuditProvider);
                      } catch (e) {
                        _showMessage('Adjust failed: $e', isError: true);
                      }
                    },
                    child: const Text('Apply Adjustment'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _presetChip(
    String label,
    AdminStatsPreset value,
    AdminStatsPreset current,
  ) {
    final selected = value == current;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        ref.read(adminStatsPresetProvider.notifier).state = value;
        if (value != AdminStatsPreset.custom) {
          ref.read(adminStatsFromProvider.notifier).state = null;
          ref.read(adminStatsToProvider.notifier).state = null;
        }
        ref.invalidate(adminDashboardStatsProvider);
      },
    );
  }

  Widget _buildGiftsTab() {
    final items = ref.watch(adminGiftItemsProvider);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminGiftItemsProvider);
        ref.invalidate(giftItemsProvider);
        await Future<void>.delayed(const Duration(milliseconds: 150));
      },
      child: items.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) => ListView(
          padding: const EdgeInsets.all(AppTheme.paddingL),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Gift catalog',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kinds: flower, rabbit, cat. Price deducts sender score; popularity goes to the post author.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppTheme.paddingM),
                    FilledButton.icon(
                      onPressed: () => _showGiftEditor(context, null),
                      icon: const Icon(Icons.add),
                      label: const Text('Add gift'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.paddingM),
            ...list.map(
              (g) => Card(
                child: ListTile(
                  leading: Text(
                    GiftItem.emojiForKind(g.kind),
                    style: const TextStyle(fontSize: 28),
                  ),
                  title: Text(g.title),
                  subtitle: Text(
                    '${g.kind} · ${g.priceScore} score · +${g.popularityPoints} popularity · sort ${g.sortOrder}',
                  ),
                  trailing: Switch(
                    value: g.isActive,
                    onChanged: (v) async {
                      try {
                        await ref.read(adminActionsProvider).upsertGiftItem({
                          ...g.toJson(),
                          'is_active': v,
                          'updated_at': DateTime.now().toIso8601String(),
                        });
                        ref.invalidate(adminGiftItemsProvider);
                        ref.invalidate(giftItemsProvider);
                      } catch (e) {
                        _showMessage('Failed: $e', isError: true);
                      }
                    },
                  ),
                  onTap: () => _showGiftEditor(context, g),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showGiftEditor(BuildContext context, GiftItem? existing) async {
    final titleCt = TextEditingController(text: existing?.title ?? '');
    final priceCt = TextEditingController(
      text: existing != null ? '${existing.priceScore}' : '100',
    );
    final popCt = TextEditingController(
      text: existing != null ? '${existing.popularityPoints}' : '5',
    );
    final sortCt = TextEditingController(
      text: existing != null ? '${existing.sortOrder}' : '0',
    );
    var kind = existing?.kind ?? 'flower';
    var active = existing?.isActive ?? true;

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setSt) {
            return AlertDialog(
              title: Text(existing == null ? 'Add gift' : 'Edit gift'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: kind,
                      decoration: const InputDecoration(labelText: 'Kind'),
                      items: const [
                        DropdownMenuItem(value: 'flower', child: Text('flower')),
                        DropdownMenuItem(value: 'rabbit', child: Text('rabbit')),
                        DropdownMenuItem(value: 'cat', child: Text('cat')),
                      ],
                      onChanged: (v) {
                        if (v != null) setSt(() => kind = v);
                      },
                    ),
                    TextField(
                      controller: titleCt,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    TextField(
                      controller: priceCt,
                      decoration: const InputDecoration(labelText: 'Price (score)'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: popCt,
                      decoration: const InputDecoration(
                        labelText: 'Popularity points (recipient)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: sortCt,
                      decoration: const InputDecoration(labelText: 'Sort order'),
                      keyboardType: TextInputType.number,
                    ),
                    SwitchListTile(
                      title: const Text('Active'),
                      value: active,
                      onChanged: (v) => setSt(() => active = v),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final price = int.tryParse(priceCt.text.trim());
                    final pop = int.tryParse(popCt.text.trim());
                    final sort = int.tryParse(sortCt.text.trim());
                    final title = titleCt.text.trim();
                    if (title.isEmpty || price == null || pop == null || sort == null) {
                      _showMessage('Fill all fields with valid numbers.', isError: true);
                      return;
                    }
                    try {
                      final now = DateTime.now().toIso8601String();
                      final actions = ref.read(adminActionsProvider);
                      if (existing == null) {
                        await actions.insertGiftItem({
                          'kind': kind,
                          'title': title,
                          'price_score': price,
                          'popularity_points': pop,
                          'sort_order': sort,
                          'is_active': active,
                          'updated_at': now,
                        });
                      } else {
                        await actions.upsertGiftItem({
                          ...existing.toJson(),
                          'kind': kind,
                          'title': title,
                          'price_score': price,
                          'popularity_points': pop,
                          'sort_order': sort,
                          'is_active': active,
                          'updated_at': now,
                        });
                      }
                      ref.invalidate(adminGiftItemsProvider);
                      ref.invalidate(giftItemsProvider);
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                      _showMessage('Saved');
                    } catch (e) {
                      _showMessage('Failed: $e', isError: true);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    titleCt.dispose();
    priceCt.dispose();
    popCt.dispose();
    sortCt.dispose();
  }

  Widget _buildCustomRangePicker() {
    final from = ref.watch(adminStatsFromProvider);
    final to = ref.watch(adminStatsToProvider);
    final fmt = DateFormat('yyyy-MM-dd HH:mm');
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                firstDate: DateTime(2024),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                initialDate: from ?? DateTime.now(),
              );
              if (d == null) return;
              if (!mounted) return;
              final t = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(from ?? DateTime.now()),
              );
              if (t == null) return;
              if (!mounted) return;
              ref.read(adminStatsFromProvider.notifier).state =
                  DateTime(d.year, d.month, d.day, t.hour, t.minute);
              ref.invalidate(adminDashboardStatsProvider);
            },
            child: Text(from == null ? 'From' : fmt.format(from)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                firstDate: DateTime(2024),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                initialDate: to ?? DateTime.now(),
              );
              if (d == null) return;
              if (!mounted) return;
              final t = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(to ?? DateTime.now()),
              );
              if (t == null) return;
              if (!mounted) return;
              ref.read(adminStatsToProvider.notifier).state =
                  DateTime(d.year, d.month, d.day, t.hour, t.minute);
              ref.invalidate(adminDashboardStatsProvider);
            },
            child: Text(to == null ? 'To' : fmt.format(to)),
          ),
        ),
      ],
    );
  }
}


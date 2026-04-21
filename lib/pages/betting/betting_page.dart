import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../config/theme.dart';
import '../../widgets/legal_footer_links.dart';
import '../../widgets/play_leaderboards_section.dart';
import '../../state/auth/auth_controller.dart';
import '../../state/betting/betting_controller.dart';
import '../../state/betting/play_leaderboards.dart';
import '../../utils/pick_window_myanmar.dart';
import '../../utils/time_ago.dart';
import '../../widgets/bet_win_congrats_dialog.dart';

class BettingPage extends ConsumerStatefulWidget {
  const BettingPage({super.key});

  @override
  ConsumerState<BettingPage> createState() => _BettingPageState();
}

class _BettingPageState extends ConsumerState<BettingPage> {
  bool _showHistory = false;

  late final PageController _picksPageController;
  late final tz.Location _yangonLoc;
  Set<String> _thaiHolidayYmd = {};
  int _picksPageIndex = 0;

  /// 1 … 60 seconds per cycle; at 60 refresh Top 10 when Popular tab visible.
  int _popularTick = 1;
  Timer? _popularMinuteTimer;

  @override
  void initState() {
    super.initState();
    _yangonLoc = tz.getLocation('Asia/Yangon');
    _picksPageController = PageController();
    Future.microtask(() async {
      await ref.read(bettingControllerProvider.notifier).loadData();
      await _loadThaiHolidays();
    });
    _popularMinuteTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_popularTick >= 60) {
          if (_picksPageIndex == 0 && !_showHistory) {
            ref.read(bettingControllerProvider.notifier).refreshTrendingDigits();
          }
          _popularTick = 1;
        } else {
          _popularTick++;
        }
      });
    });
  }

  @override
  void dispose() {
    _popularMinuteTimer?.cancel();
    _picksPageController.dispose();
    super.dispose();
  }

  Future<void> _loadThaiHolidays() async {
    try {
      final rows = await ref.read(supabaseClientProvider).from('thai_set_holidays').select('hdate');
      if (!mounted) return;
      final next = <String>{};
      for (final e in rows as List<dynamic>) {
        final m = Map<String, dynamic>.from(e as Map);
        final d = m['hdate'];
        if (d is String && d.length >= 10) {
          next.add(d.substring(0, 10));
        }
      }
      setState(() => _thaiHolidayYmd = next);
    } catch (_) {}
  }

  bool _pickWindowOpen() {
    return isPickWindowOpenYangon(
      _yangonLoc,
      thaiHolidayDatesYyyyMmDd: _thaiHolidayYmd,
    );
  }

  void _showPickClosedSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Pick window is closed. Open Mon-Fri, 06:00-11:40 and 13:00-16:10 (Myanmar time), excluding weekends and exchange holidays.',
        ),
        backgroundColor: AppTheme.warningColor,
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _showBetDialog() {
    if (!_pickWindowOpen()) {
      _showPickClosedSnack();
      return;
    }
    showDialog(
      context: context,
      builder: (context) => _MultipleBetDialog(),
    );
  }

  void _goToPicksPage(int index) {
    if (_picksPageController.hasClients) {
      _picksPageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_picksPageController.hasClients) return;
      _picksPageController.jumpToPage(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bettingState = ref.watch(bettingControllerProvider);
    final pickOpen = _pickWindowOpen();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => context.push('/missions'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emoji_events, color: AppTheme.warningColor),
                  const SizedBox(width: AppTheme.paddingS),
                  Text(
                    '${bettingState.wallet?.availableScore ?? 0} score',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              icon: const Icon(Icons.add_circle_outline, size: 26),
              tooltip: 'Missions',
              onPressed: () => context.push('/missions'),
            ),
          ],
        ),
        actions: [
          if (kDebugMode)
            IconButton(
              tooltip: 'Preview win card (debug only)',
              icon: const Icon(Icons.card_giftcard_outlined),
              onPressed: () {
                final name =
                    ref.read(userProfileProvider).valueOrNull?.username ??
                        'Player';
                showBetWinCongratsDialog(
                  context: context,
                  displayName: name,
                  totalRewardScore: 8800,
                  matchCount: 1,
                );
              },
            ),
        ],
      ),
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.paddingL,
                  AppTheme.paddingS,
                  AppTheme.paddingL,
                  AppTheme.paddingS,
                ),
                child: Text(
                  'Entertainment only. Score is virtual and has no cash value.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: AppTheme.paddingS),
                child: LegalFooterLinks(compact: true),
              ),
              Expanded(
                child: _showHistory
                    ? _buildHistoryTab(bettingState)
                    : _buildBetTab(bettingState, pickOpen: pickOpen),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              minimum: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FloatingActionButton.extended(
                      heroTag: 'betting_fab_log',
                      onPressed: () => setState(() => _showHistory = true),
                      icon: const Icon(Icons.history, size: 22),
                      label: const Text(
                        'HISTORY',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: _showHistory
                          ? AppTheme.primaryColor
                          : AppTheme.cardColor,
                      foregroundColor: _showHistory
                          ? Colors.white
                          : AppTheme.textSecondary,
                      elevation: _showHistory ? 4 : 1,
                    ),
                    FloatingActionButton.extended(
                      heroTag: 'betting_fab_pick',
                      onPressed: () {
                        if (_showHistory) {
                          setState(() => _showHistory = false);
                        } else if (pickOpen) {
                          _showBetDialog();
                        } else {
                          _showPickClosedSnack();
                        }
                      },
                      icon: Icon(
                        _showHistory ? Icons.sports_esports : Icons.add,
                        size: 22,
                      ),
                      label: const Text(
                        'PICK',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: !_showHistory
                          ? (pickOpen
                              ? AppTheme.successColor
                              : AppTheme.textHint.withValues(alpha: 0.35))
                          : AppTheme.cardColor,
                      foregroundColor: !_showHistory
                          ? (pickOpen
                              ? Colors.white
                              : AppTheme.textSecondary.withValues(alpha: 0.7))
                          : AppTheme.textSecondary,
                      elevation: !_showHistory && pickOpen ? 4 : 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBetTab(BettingState state, {required bool pickOpen}) {
    Future<void> onRefresh() async {
      ref.invalidate(playLeaderboardsProvider);
      ref.read(bettingControllerProvider.notifier).resetPopularDigest();
      await ref.read(bettingControllerProvider.notifier).loadData();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.paddingL,
            AppTheme.paddingS,
            AppTheme.paddingL,
            AppTheme.paddingM,
          ),
          child: _buildPicksPagerTabs(context),
        ),
        Expanded(
          child: PageView(
            controller: _picksPageController,
            onPageChanged: (i) => setState(() => _picksPageIndex = i),
            children: [
              RefreshIndicator(
                onRefresh: onRefresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.paddingL,
                    0,
                    AppTheme.paddingL,
                    88,
                  ),
                  children: [
                    _buildPopularDigitsListContent(
                      context,
                      state,
                      onDigitRowTap: pickOpen ? _showBetDialog : _showPickClosedSnack,
                      sessionActive: state.popularSessionActive,
                    ),
                  ],
                ),
              ),
              RefreshIndicator(
                onRefresh: onRefresh,
                child: const SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    AppTheme.paddingL,
                    0,
                    AppTheme.paddingL,
                    88,
                  ),
                  child: PlayLeaderboardsSection(
                    forceSideBySide: true,
                    denseBottomPadding: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPicksPagerTabs(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(
          color: AppTheme.textHint.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _picksPagerSegment(
                    selected: _picksPageIndex == 0,
                    icon: Icons.trending_up,
                    iconColor: AppTheme.warningColor,
                    label: 'Top 10 Popular Digits',
                    onTap: () => _goToPicksPage(0),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _picksPagerSegment(
                    selected: _picksPageIndex == 1,
                    icon: Icons.leaderboard,
                    iconColor: AppTheme.primaryColor,
                    label: 'Leaderboard',
                    onTap: () => _goToPicksPage(1),
                  ),
                ),
              ],
            ),
            if (_picksPageIndex == 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _popularTick / 60,
                        minHeight: 6,
                        backgroundColor: AppTheme.textHint.withValues(alpha: 0.15),
                        color: AppTheme.warningColor.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$_popularTick / 60',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Updates every 1 minute (1-60s)',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _picksPagerSegment({
    required bool selected,
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.radiusM),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? iconColor.withValues(alpha: 0.14) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Popular digits list for the PICKS pager (page 0).
  Widget _buildPopularDigitsListContent(
    BuildContext context,
    BettingState state, {
    required VoidCallback onDigitRowTap,
    bool? sessionActive,
  }) {
    if (state.trendingDigits.isEmpty) {
      final offSession = sessionActive == false;
      return Padding(
        padding: const EdgeInsets.all(AppTheme.paddingXL),
        child: Center(
          child: Text(
            offSession
                ? 'Popular ranking is paused right now.\n'
                    'Picks are excluded on weekends, exchange holidays, and outside active market windows (Myanmar time).'
                : 'No picks from other users yet.\n'
                    'Your pick will appear here.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.35,
                ),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: state.trendingDigits.asMap().entries.map((entry) {
        final index = entry.key;
        final trending = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.paddingM),
          child: InkWell(
            onTap: onDigitRowTap,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            child: Container(
              padding: const EdgeInsets.all(AppTheme.paddingL),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: index < 3
                      ? [
                          AppTheme.warningColor.withValues(alpha: 0.1),
                          AppTheme.warningColor.withValues(alpha: 0.05),
                        ]
                      : [
                          AppTheme.primaryLight.withValues(alpha: 0.1),
                          AppTheme.primaryLight.withValues(alpha: 0.05),
                        ],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                border: Border.all(
                  color: index < 3
                      ? AppTheme.warningColor.withValues(alpha: 0.3)
                      : AppTheme.primaryLight.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: index < 3
                          ? AppTheme.warningColor
                          : AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.paddingL),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.paddingL,
                      vertical: AppTheme.paddingS,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      trending.digit.toString().padLeft(2, '0'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${trending.peopleCount}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: index < 3
                              ? AppTheme.warningColor
                              : AppTheme.primaryColor,
                        ),
                      ),
                      Text(
                        trending.peopleCount == 1 ? 'pick' : 'picks',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHistoryTab(BettingState state) {
    return RefreshIndicator(
      onRefresh: () => ref.read(bettingControllerProvider.notifier).loadData(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (state.isLoading && state.bets.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.all(AppTheme.paddingXL),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (state.bets.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.paddingL,
                  AppTheme.paddingXL,
                  AppTheme.paddingL,
                  88,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.history,
                      size: 64,
                      color: AppTheme.textHint,
                    ),
                    const SizedBox(height: AppTheme.paddingL),
                    Text(
                      'No play log yet',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.paddingL,
                0,
                AppTheme.paddingL,
                88,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final bet = state.bets[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppTheme.paddingM),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryLight,
                          child: Text(
                            bet.digit.toString().padLeft(2, '0'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          '${bet.amount} score',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(formatTimeAgo(bet.createdAt)),
                        trailing: Chip(
                          label: Text(
                            bet.isPending
                                ? 'Pending'
                                : bet.isWin
                                    ? 'Match'
                                    : 'Miss',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          backgroundColor: bet.isPending
                              ? AppTheme.warningColor
                              : bet.isWin
                                  ? AppTheme.successColor
                                  : AppTheme.errorColor,
                        ),
                      ),
                    );
                  },
                  childCount: state.bets.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Multiple Bet Dialog Widget
class _MultipleBetDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_MultipleBetDialog> createState() => _MultipleBetDialogState();
}

class _MultipleBetDialogState extends ConsumerState<_MultipleBetDialog> {
  final List<_BetEntry> _betEntries = List.generate(10, (index) => _BetEntry());
  final _formKey = GlobalKey<FormState>();
  bool _isChecked = false;
  List<String> _errors = [];

  void _checkBets() {
    setState(() {
      _errors = [];
      _isChecked = false;
    });

    final bettingState = ref.read(bettingControllerProvider);
    final currentBalance = bettingState.wallet?.availableScore ?? 0;

    // Collect valid bets
    final List<Map<String, dynamic>> validBets = [];
    
    for (int i = 0; i < _betEntries.length; i++) {
      final entry = _betEntries[i];
      final digitText = entry.digitController.text.trim();
      final amountText = entry.amountController.text.trim();

      // Skip empty rows
      if (digitText.isEmpty && amountText.isEmpty) {
        continue;
      }

      // Check if digit is provided but amount is missing
      if (digitText.isNotEmpty && amountText.isEmpty) {
        _errors.add('Row ${i + 1}: Score is required');
        continue;
      }

      // Check if amount is provided but digit is missing
      if (digitText.isEmpty && amountText.isNotEmpty) {
        _errors.add('Row ${i + 1}: 2D digit is required');
        continue;
      }

      // Validate digit format (must be exactly 2 digits)
      if (digitText.length != 2) {
        _errors.add('Row ${i + 1}: Digit must be exactly 2 digits (e.g., 01, 23, 99)');
        continue;
      }

      final digit = int.tryParse(digitText);
      if (digit == null || digit < 0 || digit > 99) {
        _errors.add('Row ${i + 1}: Invalid digit (must be 00-99)');
        continue;
      }

      final amount = int.tryParse(amountText);
      if (amount == null || amount < 100) {
        _errors.add('Row ${i + 1}: Minimum entry is 100 score');
        continue;
      }

      validBets.add({'digit': digit, 'amount': amount});
    }

    // Check if at least one pick is provided
    if (validBets.isEmpty) {
      _errors.add('Please enter at least one pick');
    }

    // Check total amount against balance
    if (validBets.isNotEmpty) {
      final totalAmount = validBets.fold<int>(0, (sum, bet) => sum + (bet['amount'] as int));
      if (totalAmount > currentBalance) {
        _errors.add('Total entry ($totalAmount score) exceeds your balance ($currentBalance score)');
      }
    }

    setState(() {
      if (_errors.isEmpty) {
        _isChecked = true;
      }
    });

    if (_errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errors.join('\n')),
          backgroundColor: AppTheme.errorColor,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _sendBets() async {
    // Collect valid bets
    final List<Map<String, int>> betsToPlace = [];
    
    for (final entry in _betEntries) {
      final digitText = entry.digitController.text.trim();
      final amountText = entry.amountController.text.trim();

      if (digitText.isNotEmpty && amountText.isNotEmpty) {
        final digit = int.parse(digitText);
        final amount = int.parse(amountText);
        betsToPlace.add({'digit': digit, 'amount': amount});
      }
    }

    if (betsToPlace.isEmpty) return;

    // Place bets one by one
    int successCount = 0;
    String? failMessage;
    for (final bet in betsToPlace) {
      final success = await ref
          .read(bettingControllerProvider.notifier)
          .placeBet(bet['digit']!, bet['amount']!);

      if (success) {
        successCount++;
      } else {
        failMessage = ref.read(bettingControllerProvider).error;
        break;
      }
    }

    if (mounted) {
      Navigator.pop(context);

      if (failMessage != null && failMessage.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              successCount > 0
                  ? '$successCount picks saved, then failed: $failMessage'
                  : failMessage,
            ),
            backgroundColor: AppTheme.warningColor,
            duration: const Duration(seconds: 6),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved $successCount pick(s)!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    for (final entry in _betEntries) {
      entry.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bettingState = ref.watch(bettingControllerProvider);

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(AppTheme.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Entertainment only. Score is virtual and has no cash value. '
              'No real money or prizes can be won.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
            const SizedBox(height: AppTheme.paddingM),
            Row(
              children: [
                Text(
                  'Add multiple picks',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.paddingM),
            Container(
              padding: const EdgeInsets.all(AppTheme.paddingM),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events, color: AppTheme.warningColor, size: 20),
                  const SizedBox(width: AppTheme.paddingS),
                  Expanded(
                    child: Text(
                      'Score balance: ${bettingState.wallet?.availableScore ?? 0}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.warningColor,
                      ),
                    ),
                  ),
                  Text(
                    'In play: ${bettingState.wallet?.lockedBalance ?? 0}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.paddingL),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView.builder(
                  itemCount: _betEntries.length,
                  itemBuilder: (context, index) {
                    final entry = _betEntries[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppTheme.paddingM),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: entry.digitController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(2),
                              ],
                              decoration: InputDecoration(
                                hintText: '2D',
                                hintStyle: TextStyle(
                                  color: AppTheme.textHint.withValues(alpha: 0.5),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.paddingM,
                                  vertical: AppTheme.paddingM,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTheme.paddingM),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: entry.amountController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                hintText: 'score',
                                hintStyle: TextStyle(
                                  color: AppTheme.textHint.withValues(alpha: 0.5),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.paddingM,
                                  vertical: AppTheme.paddingM,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: AppTheme.paddingL),
            if (!_isChecked)
              ElevatedButton(
                onPressed: bettingState.isLoading ? null : _checkBets,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.all(AppTheme.paddingL),
                ),
                child: const Text(
                  'Review',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              ElevatedButton(
                onPressed: bettingState.isLoading ? null : _sendBets,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                  padding: const EdgeInsets.all(AppTheme.paddingL),
                ),
                child: bettingState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Submit',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BetEntry {
  final TextEditingController digitController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  void dispose() {
    digitController.dispose();
    amountController.dispose();
  }
}

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../config/theme.dart' show AppTheme, rootScaffoldMessengerKey;
import '../../utils/rewarded_ad_helper.dart';
import '../../state/auth/auth_controller.dart';
import '../../state/betting/betting_controller.dart';
import '../../state/games/math_game_daily_play.dart';
import '../../state/games/math_game_reward.dart';
import '../../state/missions/missions_controller.dart';

/// Quick math quiz: +, −, ×. Win one game after 3 correct answers in a row.
class MathQuizGamePage extends ConsumerStatefulWidget {
  const MathQuizGamePage({super.key});

  static const int roundsToWin = 3;
  static const int baseRewardScore = 500;
  static const int adBonusScore = 1000;

  @override
  ConsumerState<MathQuizGamePage> createState() => _MathQuizGamePageState();
}

enum _MathOp { add, sub, mul }

class _MathQuizGamePageState extends ConsumerState<MathQuizGamePage> {
  final Random _rand = Random();
  final _uuid = const Uuid();

  int _correctCount = 0;
  bool _locked = false;

  late _MathOp _op;
  late int _a;
  late int _b;
  late int _answer;
  late List<int> _choices;

  @override
  void initState() {
    super.initState();
    _rollQuestion();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userId = ref.read(currentUserProvider)?.id;
      final daily = await MathGameDailyPlay.load(userId: userId);
      if (!mounted) return;
      if (!daily.canStartNewGame) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Daily limit reached (20 games). Please try again after 1:00 AM.',
            ),
            backgroundColor: AppTheme.warningColor,
          ),
        );
        if (context.mounted) context.go('/missions');
      }
    });
  }

  void _rollQuestion() {
    _op = _MathOp.values[_rand.nextInt(3)];
    switch (_op) {
      case _MathOp.add:
        _a = 1 + _rand.nextInt(9);
        _b = 1 + _rand.nextInt(9);
        _answer = _a + _b;
        break;
      case _MathOp.sub:
        _a = 6 + _rand.nextInt(14);
        _b = 1 + _rand.nextInt(_a - 2);
        _answer = _a - _b;
        break;
      case _MathOp.mul:
        _a = 2 + _rand.nextInt(8);
        _b = 2 + _rand.nextInt(8);
        _answer = _a * _b;
        break;
    }
    _choices = _makeChoices(_answer);
    _locked = false;
  }

  List<int> _makeChoices(int correct) {
    final set = <int>{correct};
    var guard = 0;
    while (set.length < 3 && guard < 50) {
      guard++;
      var delta = _rand.nextInt(9) - 4;
      if (delta == 0) {
        delta = _rand.nextBool() ? 3 : -3;
      }
      var w = correct + delta;
      if (w < 0) {
        w = correct + 2 + _rand.nextInt(6);
      }
      if (w != correct) {
        set.add(w);
      }
    }
    while (set.length < 3) {
      set.add(correct + set.length * 7 + 1);
    }
    final list = set.toList()..shuffle(_rand);
    return list;
  }

  String get _questionLabel {
    switch (_op) {
      case _MathOp.add:
        return '$_a + $_b = ?';
      case _MathOp.sub:
        return '$_a − $_b = ?';
      case _MathOp.mul:
        return '$_a × $_b = ?';
    }
  }

  Future<void> _refreshWallets() async {
    await Future.wait([
      ref.read(bettingControllerProvider.notifier).loadData(),
      ref.read(missionsControllerProvider.notifier).loadData(),
    ]);
  }

  Future<void> _openRewardsDialog() async {
    final sessionId = _uuid.v4();
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => _RewardsDialog(
        onClaimBase: () => claimMathGameReward(
          ref.read(supabaseClientProvider),
          sessionId: sessionId,
          kind: 'base',
        ),
        onClaimAdBonus: () => claimMathGameReward(
          ref.read(supabaseClientProvider),
          sessionId: sessionId,
          kind: 'ad_bonus',
        ),
        onWatchAd: RewardedAdHelper.showRewardedForBonus,
        onAfterCredit: _refreshWallets,
        onGoToMissions: () {
          Navigator.of(dialogCtx).pop();
          if (context.mounted) context.go('/missions');
        },
      ),
    );

    if (!mounted) return;
    setState(() {
      _correctCount = 0;
      _rollQuestion();
    });
  }

  Future<void> _onPick(int value) async {
    if (_locked) return;
    _locked = true;

    if (value != _answer) {
      HapticFeedback.lightImpact();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wrong'),
          backgroundColor: AppTheme.errorColor,
          duration: Duration(seconds: 2),
        ),
      );
      setState(_rollQuestion);
      return;
    }

    HapticFeedback.mediumImpact();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Correct'),
        backgroundColor: AppTheme.successColor,
        duration: Duration(seconds: 1),
      ),
    );

    final next = _correctCount + 1;
    if (next >= MathQuizGamePage.roundsToWin) {
      setState(() {
        _correctCount = next;
      });
      final userId = ref.read(currentUserProvider)?.id;
      final recorded = await MathGameDailyPlay.recordCompletedGame(userId: userId);
      if (!mounted) return;
      if (!recorded) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Daily limit reached (20 games). Please try again after 1:00 AM.',
            ),
            backgroundColor: AppTheme.warningColor,
          ),
        );
        context.go('/missions');
        return;
      }
      ref.invalidate(mathGameDailyPlayProvider);
      await _openRewardsDialog();
      return;
    }

    setState(() {
      _correctCount = next;
      _rollQuestion();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Number Quiz'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Get ${MathQuizGamePage.roundsToWin} correct answers to complete one game. Wrong answers do not increase progress.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: AppTheme.paddingM),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  MathQuizGamePage.roundsToWin,
                  (i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      Icons.star,
                      size: 28,
                      color: i < _correctCount
                          ? AppTheme.warningColor
                          : AppTheme.textHint.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.paddingXL),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.paddingXL),
                  child: Text(
                    _questionLabel,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.paddingXL),
              Row(
                children: [
                  for (var i = 0; i < _choices.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppTheme.paddingM),
                    Expanded(
                      child: FilledButton(
                        onPressed: _locked ? null : () => _onPick(_choices[i]),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          backgroundColor: AppTheme.primaryColor,
                        ),
                        child: Text(
                          '${_choices[i]}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _locked
                    ? null
                    : () {
                        setState(_rollQuestion);
                      },
                icon: const Icon(Icons.refresh),
                label: const Text('New Question'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardsDialog extends StatefulWidget {
  const _RewardsDialog({
    required this.onClaimBase,
    required this.onClaimAdBonus,
    required this.onWatchAd,
    required this.onAfterCredit,
    required this.onGoToMissions,
  });

  final Future<Map<String, dynamic>> Function() onClaimBase;
  final Future<Map<String, dynamic>> Function() onClaimAdBonus;
  final Future<bool> Function() onWatchAd;
  final Future<void> Function() onAfterCredit;
  final VoidCallback onGoToMissions;

  @override
  State<_RewardsDialog> createState() => _RewardsDialogState();
}

class _RewardsDialogState extends State<_RewardsDialog> {
  bool _baseCredited = false;
  bool _busy = false;

  Future<void> _run(Future<void> Function() fn) async {
    setState(() => _busy = true);
    try {
      await fn();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _claimOnlyAndExit() async {
    await _run(() async {
      final map = await widget.onClaimBase();
      if (!mounted) return;
      if (map['ok'] == true) {
        setState(() => _baseCredited = true);
        await widget.onAfterCredit();
        if (!mounted) return;
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('You get +500 Score'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        widget.onGoToMissions();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${map['error'] ?? 'Claim failed'}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    });
  }

  Future<void> _watchAdsAndExit() async {
    await _run(() async {
      if (!_baseCredited) {
        final baseMap = await widget.onClaimBase();
        if (!mounted) return;
        if (baseMap['ok'] != true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${baseMap['error'] ?? 'Claim failed'}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
          return;
        }
        setState(() => _baseCredited = true);
        await widget.onAfterCredit();
        if (!mounted) return;
      }

      final watched = await widget.onWatchAd();
      if (!mounted) return;
      if (!watched) {
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('Ad did not complete. You get +500 Score.'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
        widget.onGoToMissions();
        return;
      }

      final bonusMap = await widget.onClaimAdBonus();
      if (!mounted) return;
      if (bonusMap['ok'] == true) {
        await widget.onAfterCredit();
        if (!mounted) return;
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('You get 1000 Score'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        widget.onGoToMissions();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${bonusMap['error'] ?? 'Bonus failed'}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('You get +500 Score'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        widget.onGoToMissions();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Game Completed'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Your Rewards',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${MathQuizGamePage.baseRewardScore} Score',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.warningColor,
                  ),
            ),
            const SizedBox(height: AppTheme.paddingM),
            FilledButton.icon(
              onPressed: (_busy || _baseCredited) ? null : _claimOnlyAndExit,
              icon: const Icon(Icons.redeem),
              label: const Text('Claim'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: AppTheme.paddingS),
            OutlinedButton.icon(
              onPressed: _busy ? null : _watchAdsAndExit,
              icon: const Icon(Icons.play_circle_outline),
              label: const Text(
                'Watch ads to get +500×2 = 1000',
                textAlign: TextAlign.center,
              ),
            ),
            if (!RewardedAdHelper.supported)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Desktop: ad is skipped in demo mode; you still get the bonus if the flow completes.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

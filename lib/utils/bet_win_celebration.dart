import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/router.dart';
import '../models/bet.dart';
import '../state/auth/auth_controller.dart';
import '../widgets/bet_win_congrats_dialog.dart';
import 'bet_win_celebration_prefs.dart';

/// Serializes celebration so prefs + dialog are not raced by parallel [ref.listen] fires.
Future<void> _celebrationTail = Future<void>.value();

int _sumWinRewards(Iterable<Bet> wins) {
  var t = 0;
  for (final b in wins) {
    t += b.winRewardScore;
  }
  return t;
}

/// Shows the congrats card for new winning picks (not shown for historical wins on first seed).
Future<void> maybeCelebrateBetWins(
  WidgetRef ref,
  List<Bet> bets,
) {
  final done = _celebrationTail.then((_) => _celebrateImpl(ref, bets));
  _celebrationTail = done.catchError((Object _, StackTrace __) {});
  return done;
}

bool _overlayMounted() {
  final c = rootNavigatorKey.currentContext;
  return c != null && c.mounted;
}

Future<void> _celebrateImpl(
  WidgetRef ref,
  List<Bet> bets,
) async {
  final user = ref.read(currentUserProvider);
  if (user == null) return;

  final wins = bets.where((b) => b.isWin).toList();
  if (wins.isEmpty) return;

  final seeded = await BetWinCelebrationPrefs.isSeeded(user.id);
  if (!_overlayMounted()) return;
  final ids = wins.map((b) => b.betId).toList();

  if (!seeded) {
    await BetWinCelebrationPrefs.seedInitialWins(user.id, ids);
    return;
  }

  final celebrated = await BetWinCelebrationPrefs.loadIds(user.id);
  if (!_overlayMounted()) return;
  final fresh = wins.where((w) => !celebrated.contains(w.betId)).toList();
  if (fresh.isEmpty) return;

  final total = _sumWinRewards(fresh);
  await BetWinCelebrationPrefs.markCelebrated(user.id, fresh.map((b) => b.betId));
  if (!_overlayMounted()) return;

  final uname = ref.read(userProfileProvider).valueOrNull?.username;

  final ctx = rootNavigatorKey.currentContext;
  if (ctx == null || !ctx.mounted) return;

  await showBetWinCongratsDialog(
    context: ctx,
    displayName: uname ?? 'Player',
    totalRewardScore: total,
    matchCount: fresh.length,
  );
}


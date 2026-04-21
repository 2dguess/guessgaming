import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../state/auth/auth_controller.dart';
import '../state/betting/betting_controller.dart';
import '../utils/bet_win_celebration.dart';

/// Loads bet history when signed in and shows a one-time congrats card for new wins.
class BetWinCelebrationHost extends ConsumerStatefulWidget {
  const BetWinCelebrationHost({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<BetWinCelebrationHost> createState() =>
      _BetWinCelebrationHostState();
}

class _BetWinCelebrationHostState extends ConsumerState<BetWinCelebrationHost> {
  String? _sessionUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  void _bootstrap() {
    final uid = ref.read(currentUserProvider)?.id;
    if (uid == null) return;
    _sessionUserId = uid;
    ref.read(bettingControllerProvider.notifier).loadData();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<User?>(currentUserProvider, (prev, next) {
      final id = next?.id;
      if (id == null) {
        _sessionUserId = null;
        return;
      }
      if (id != _sessionUserId) {
        _sessionUserId = id;
        ref.read(bettingControllerProvider.notifier).loadData();
      }
    });

    ref.listen<BettingState>(bettingControllerProvider, (prev, next) {
      if (next.isLoading) return;
      final uid = ref.read(currentUserProvider)?.id;
      if (uid == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        maybeCelebrateBetWins(ref, next.bets);
      });
    });

    return widget.child;
  }
}

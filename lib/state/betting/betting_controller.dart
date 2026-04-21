import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../models/bet.dart';
import '../../models/wallet.dart';
import '../../config/supabase_config.dart';
import '../auth/auth_controller.dart';

class BettingState {
  final List<Bet> bets;
  final List<TrendingDigit> trendingDigits;
  /// From [get_popular_digits]: false when outside SET session window (weekend / off-hours).
  final bool? popularSessionActive;
  final Wallet? wallet;
  final bool isLoading;
  final String? error;

  BettingState({
    this.bets = const [],
    this.trendingDigits = const [],
    this.popularSessionActive,
    this.wallet,
    this.isLoading = false,
    this.error,
  });

  BettingState copyWith({
    List<Bet>? bets,
    List<TrendingDigit>? trendingDigits,
    bool? popularSessionActive,
    Wallet? wallet,
    bool? isLoading,
    String? error,
  }) {
    return BettingState(
      bets: bets ?? this.bets,
      trendingDigits: trendingDigits ?? this.trendingDigits,
      popularSessionActive: popularSessionActive ?? this.popularSessionActive,
      wallet: wallet ?? this.wallet,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class BettingController extends StateNotifier<BettingState> {
  final SupabaseClient _client;
  final String? _userId;
  final Uuid _uuid = const Uuid();

  BettingController(this._client, this._userId) : super(BettingState());

  /// Server fingerprint for Top 10; when unchanged, keep showing the last list (no flicker).
  String? _popularDigest;

  /// Call before pull-to-refresh to force a full popular-digits fetch.
  void resetPopularDigest() {
    _popularDigest = null;
  }

  static void _logPopularDiag(String message) {
    debugPrint('[Popular Top10] $message');
  }

  static void _logPopularError(String context, Object e, [StackTrace? st]) {
    debugPrint('[Popular Top10] ERROR: $context');
    debugPrint('[Popular Top10] $e');
    if (st != null && kDebugMode) {
      debugPrint('$st');
    }
  }

  static void _logBetDiag(String message) {
    debugPrint('[Bet Place] $message');
  }

  static void _logBetError(String context, Object e, [StackTrace? st]) {
    debugPrint('[Bet Place] ERROR: $context');
    debugPrint('[Bet Place] $e');
    if (st != null && kDebugMode) {
      debugPrint('$st');
    }
  }

  /// `true` if popular Top 10 data changed (notify other clients via broadcast).
  Future<bool> loadData() async {
    if (_userId == null) return false;
    if (!mounted) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      await Future.wait([
        _loadWallet(),
        _loadBets(),
      ]);
      if (!mounted) return false;
      final popularChanged = await _syncPopularDigits();
      if (!mounted) return false;

      state = state.copyWith(isLoading: false);
      return popularChanged;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<void> _loadWallet() async {
    if (_userId == null) return;
    if (!mounted) return;

    final response = await _client
        .from('wallets')
        .select()
        .eq('user_id', _userId!)
        .maybeSingle();

    if (!mounted) return;
    if (response != null) {
      state = state.copyWith(wallet: Wallet.fromJson(response));
    } else {
      await _client.from('wallets').insert({
        'user_id': _userId,
        'balance': 10000,
        'available_balance': 10000,
        'locked_balance': 0,
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      if (!mounted) return;
      state = state.copyWith(
        wallet: Wallet(
          userId: _userId!,
          balance: 10000,
          availableBalance: 10000,
          lockedBalance: 0,
          updatedAt: DateTime.now(),
        ),
      );
    }
  }

  Future<void> _loadBets() async {
    if (_userId == null) return;
    if (!mounted) return;

    final response = await _client
        .from('bets')
        .select()
        .eq('user_id', _userId!)
        .order('created_at', ascending: false)
        .limit(SupabaseConfig.betsHistoryPageSize);

    final bets = (response as List)
        .map((json) => Bet.fromJson(json))
        .toList();

    if (!mounted) return;
    state = state.copyWith(bets: bets);
  }

  Future<bool> _syncPopularDigits() async {
    final params = <String, dynamic>{};
    if (_popularDigest != null) {
      params['p_digest'] = _popularDigest;
    }

    try {
      final response = await _client.rpc('get_popular_digits', params: params);
      return _applyPopularDigitsResponse(response);
    } catch (e, st) {
      _logPopularError('get_popular_digits RPC failed (trying get_trending_digits)', e, st);
      try {
        // Old DB without get_popular_digits: fall back to table RPC.
        final legacy = await _client.rpc('get_trending_digits');
        final raw = legacy as List<dynamic>;
        final trending = raw
            .map((e) => TrendingDigit.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        _logPopularDiag('Fallback get_trending_digits OK: ${trending.length} rows');
        state = state.copyWith(
          trendingDigits: trending,
          popularSessionActive: true,
        );
        return true;
      } catch (e2, st2) {
        _logPopularError('get_trending_digits fallback also failed — Top 10 unavailable', e2, st2);
        state = state.copyWith(
          trendingDigits: const [],
          popularSessionActive: false,
        );
        return false;
      }
    }
  }

  /// Handles JSONB quirks (List vs encoded String) and bad rows.
  List<TrendingDigit> _trendingDigitsFromPayload(Map<String, dynamic> map) {
    final d = map['digits'];
    List<dynamic> rawList;
    if (d == null) {
      rawList = const [];
    } else if (d is List) {
      rawList = d;
    } else if (d is String) {
      try {
        final decoded = jsonDecode(d);
        rawList = decoded is List ? decoded : const [];
      } catch (_) {
        rawList = const [];
      }
    } else {
      rawList = const [];
    }

    final out = <TrendingDigit>[];
    for (final e in rawList) {
      if (e is! Map) continue;
      try {
        final row = Map<String, dynamic>.from(e);
        out.add(TrendingDigit.fromJson(row));
      } catch (_) {
        continue;
      }
    }
    return out;
  }

  bool _applyPopularDigitsResponse(dynamic response) {
    if (response is! Map) {
      _logPopularDiag(
        'Invalid RPC response type: ${response.runtimeType} (expected Map).',
      );
      return false;
    }
    final map = Map<String, dynamic>.from(response as Map);
    final unchanged = map['unchanged'] == true;

    final digest = map['digest'] as String?;
    if (digest != null) {
      _popularDigest = digest;
    }

    // Same snapshot as last time — keep UI as-is (original digest behaviour).
    if (unchanged) {
      _logPopularDiag('unchanged=true (digest match) — keeping previous list on screen');
      return false;
    }

    final trending = _trendingDigitsFromPayload(map);

    final sessionActive = map['session_active'];
    final sess = sessionActive is bool
        ? sessionActive
        : (map['window_key'] != null);
    final wk = map['window_key'];

    _logPopularDiag(
      'response: session_active=$sess window_key=$wk digits_count=${trending.length} unchanged=$unchanged',
    );

    if (trending.isEmpty && sess == true) {
      _logPopularDiag(
        'LIST EMPTY but session is active — check Supabase: popular_digit_counts for this '
        'window_key, and that bets trigger popular_digit_record_first_pick runs (run fix_popular_digit_on_conflict_alias.sql).',
      );
    }
    if (trending.isEmpty && sess != true) {
      _logPopularDiag(
        'LIST EMPTY: outside popular-digit window (weekend/holiday/off-hours) or session_active=false.',
      );
    }

    state = state.copyWith(
      trendingDigits: trending,
      popularSessionActive: sess,
    );

    return true;
  }

  /// Every ~60s on Play: clear digest and call RPC again (full snapshot), even if data
  /// would have matched the previous digest.
  Future<void> refreshTrendingDigits() async {
    if (_userId == null) return;
    try {
      resetPopularDigest();
      await _syncPopularDigits();
    } catch (e, st) {
      _logPopularError('refreshTrendingDigits (60s poll)', e, st);
    }
  }

  Future<bool> placeBet(int digit, int amount) async {
    if (_userId == null) return false;

    try {
      final clientBetId = _uuid.v4();
      _logBetDiag(
        'Submitting place_bet_locked: user=$_userId digit=$digit amount=$amount client_bet_id=$clientBetId',
      );

      dynamic response;
      try {
        response = await _client.rpc('place_bet_locked', params: {
          'p_client_bet_id': clientBetId,
          'p_digit': digit,
          'p_amount': amount,
        });
      } catch (e, st) {
        _logBetError(
          'place_bet_locked failed, falling back to place_bet',
          e,
          st,
        );
        response = await _client.rpc('place_bet', params: {
          'p_digit': digit,
          'p_amount': amount,
        });
      }

      if (response is! Map) {
        _logBetDiag('Unexpected bet response type: ${response.runtimeType} value=$response');
        state = state.copyWith(error: 'Invalid bet response');
        return false;
      }
      _logBetDiag('bet response: $response');

      final success = response['success'] == true || response['ok'] == true;
      if (success) {
        _logBetDiag(
          'bet success: digit=$digit amount=$amount, refreshing wallet/bets/top10',
        );
        // Own pick must refresh Top 10; old digest can wrongly yield unchanged=true.
        resetPopularDigest();
        await loadData();
        return true;
      } else {
        final err = response['error'] as String?;
        final msg = err == 'betting_closed'
            ? ((response['message'] as String?) ??
                'Pick window is closed. Open Mon-Fri, 06:00-11:40 and 13:00-16:10 (Myanmar time), excluding weekends and exchange holidays.')
            : ((response['error'] as String?) ?? 'Prediction failed');
        _logBetDiag(
          'bet rejected: error=$err message=${response['message']} raw=$response',
        );
        state = state.copyWith(error: msg);
        return false;
      }
    } catch (e, st) {
      _logBetError(
        'place_bet RPC threw exception (digit=$digit amount=$amount user=$_userId)',
        e,
        st,
      );
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final bettingControllerProvider =
    StateNotifierProvider<BettingController, BettingState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final user = ref.watch(currentUserProvider);
  return BettingController(client, user?.id);
});

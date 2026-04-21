import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/market_timing.dart';
import '../../models/set_index.dart';
import '../../services/set_api_service.dart';
import '../../utils/bangkok_market.dart';
import '../../utils/myanmar_market.dart';
import '../auth/auth_controller.dart';

class SetIndexState {
  final SetIndexResult? latestResult;
  final List<SetIndexResult> todayResults;
  final bool isLoading;
  final String? error;
  final DateTime? lastFetchTime;

  /// 09:30–12:01 MMT poll → drives 12:01 PM card + morning green digit (frozen after session until midnight).
  final double? morningLiveSetValue;
  final double? morningLiveSetIndex;
  final int? morningLiveResultDigit;
  final DateTime? morningLiveUpdatedAt;
  final String? morningLiveError;

  /// 14:00–16:30 MMT poll → drives 4:30 PM card + afternoon green digit (frozen after session until midnight).
  final double? afternoonLiveSetValue;
  final double? afternoonLiveSetIndex;
  final int? afternoonLiveResultDigit;
  final DateTime? afternoonLiveUpdatedAt;
  final String? afternoonLiveError;

  SetIndexState({
    this.latestResult,
    this.todayResults = const [],
    this.isLoading = false,
    this.error,
    this.lastFetchTime,
    this.morningLiveSetValue,
    this.morningLiveSetIndex,
    this.morningLiveResultDigit,
    this.morningLiveUpdatedAt,
    this.morningLiveError,
    this.afternoonLiveSetValue,
    this.afternoonLiveSetIndex,
    this.afternoonLiveResultDigit,
    this.afternoonLiveUpdatedAt,
    this.afternoonLiveError,
  });

  SetIndexState copyWith({
    SetIndexResult? latestResult,
    List<SetIndexResult>? todayResults,
    bool? isLoading,
    String? error,
    bool clearError = false,
    DateTime? lastFetchTime,
    double? morningLiveSetValue,
    double? morningLiveSetIndex,
    int? morningLiveResultDigit,
    DateTime? morningLiveUpdatedAt,
    String? morningLiveError,
    bool clearMorningLiveError = false,
    double? afternoonLiveSetValue,
    double? afternoonLiveSetIndex,
    int? afternoonLiveResultDigit,
    DateTime? afternoonLiveUpdatedAt,
    String? afternoonLiveError,
    bool clearAfternoonLiveError = false,
  }) {
    return SetIndexState(
      latestResult: latestResult ?? this.latestResult,
      todayResults: todayResults ?? this.todayResults,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      lastFetchTime: lastFetchTime ?? this.lastFetchTime,
      morningLiveSetValue: morningLiveSetValue ?? this.morningLiveSetValue,
      morningLiveSetIndex: morningLiveSetIndex ?? this.morningLiveSetIndex,
      morningLiveResultDigit: morningLiveResultDigit ?? this.morningLiveResultDigit,
      morningLiveUpdatedAt: morningLiveUpdatedAt ?? this.morningLiveUpdatedAt,
      morningLiveError:
          clearMorningLiveError ? null : (morningLiveError ?? this.morningLiveError),
      afternoonLiveSetValue: afternoonLiveSetValue ?? this.afternoonLiveSetValue,
      afternoonLiveSetIndex: afternoonLiveSetIndex ?? this.afternoonLiveSetIndex,
      afternoonLiveResultDigit:
          afternoonLiveResultDigit ?? this.afternoonLiveResultDigit,
      afternoonLiveUpdatedAt: afternoonLiveUpdatedAt ?? this.afternoonLiveUpdatedAt,
      afternoonLiveError:
          clearAfternoonLiveError ? null : (afternoonLiveError ?? this.afternoonLiveError),
    );
  }
}

class SetIndexController extends StateNotifier<SetIndexState> {
  final SupabaseClient _client;
  final SETAPIService _apiService;

  Timer? _livePollTimer;
  bool _livePollInFlight = false;

  /// When false, skip [state] writes so async work finishing after Home disposes
  /// does not notify a defunct [Consumer] (Riverpod + deactivated element).
  bool _pushUiUpdates = true;

  /// Bangkok calendar day last time we checked — used for midnight reset (all `--` for new day).
  String? _bangkokDateCache;

  static const Duration livePollInterval = MarketTiming.liveQuotePollInterval;

  SetIndexController(this._client, this._apiService) : super(SetIndexState());

  /// Call from [_Live2DResultViewer] initState (true) / dispose (false).
  void setPushUiUpdates(bool allow) {
    _pushUiUpdates = allow;
  }

  /// Start frequent live quotes (call from Home 2D viewer; stops on [stopLivePolling]).
  void startLivePolling() {
    if (_livePollTimer != null) return;
    _livePollTimer = Timer.periodic(livePollInterval, (_) => _tickLiveQuote());
    _tickLiveQuote();
  }

  void stopLivePolling() {
    _livePollTimer?.cancel();
    _livePollTimer = null;
  }

  /// When Bangkok date rolls past midnight, clear session snapshots and reload DB rows for the new day.
  void checkBangkokDateRollover() {
    if (!_pushUiUpdates) return;
    final today = bangkokTodayDateString();
    if (_bangkokDateCache != null && _bangkokDateCache != today) {
      _bangkokDateCache = today;
      _clearDailySessionSnapshots();
      unawaited(loadTodayResults());
    } else {
      _bangkokDateCache ??= today;
    }
  }

  void _clearDailySessionSnapshots() {
    if (!_pushUiUpdates) return;
    state = SetIndexState(
      latestResult: null,
      todayResults: const [],
      isLoading: state.isLoading,
      error: null,
      lastFetchTime: null,
      morningLiveSetValue: null,
      morningLiveSetIndex: null,
      morningLiveResultDigit: null,
      morningLiveUpdatedAt: null,
      morningLiveError: null,
      afternoonLiveSetValue: null,
      afternoonLiveSetIndex: null,
      afternoonLiveResultDigit: null,
      afternoonLiveUpdatedAt: null,
      afternoonLiveError: null,
    );
  }

  Future<void> _tickLiveQuote() async {
    if (_livePollInFlight) return;
    if (!isMyanmarSetLiveFetchWindow()) {
      return;
    }

    final m = myanmarWallClockNow();
    final t = m.hour * 60 + m.minute;
    const morningStart = 9 * 60 + 30;
    const morningEndExclusive = 12 * 60 + 1;
    const afternoonStart = 14 * 60;
    const afternoonEndExclusive = 16 * 60 + 30;

    final inMorning = t >= morningStart && t < morningEndExclusive;
    final inAfternoon = t >= afternoonStart && t < afternoonEndExclusive;
    if (!inMorning && !inAfternoon) return;

    _livePollInFlight = true;
    try {
      final data =
          await _apiService.fetchLiveFromCdn() ?? await _apiService.fetchLiveSETData();
      if (!_pushUiUpdates) return;

      if (data != null) {
        final sv = data['set_value'] as double;
        final ix = data['set_index'] as double;
        final dg = data['result_digit'] as int;
        final now = DateTime.now();

        if (inMorning) {
          state = SetIndexState(
            latestResult: state.latestResult,
            todayResults: state.todayResults,
            isLoading: state.isLoading,
            error: state.error,
            lastFetchTime: state.lastFetchTime,
            morningLiveSetValue: sv,
            morningLiveSetIndex: ix,
            morningLiveResultDigit: dg,
            morningLiveUpdatedAt: now,
            morningLiveError: null,
            afternoonLiveSetValue: state.afternoonLiveSetValue,
            afternoonLiveSetIndex: state.afternoonLiveSetIndex,
            afternoonLiveResultDigit: state.afternoonLiveResultDigit,
            afternoonLiveUpdatedAt: state.afternoonLiveUpdatedAt,
            afternoonLiveError: state.afternoonLiveError,
          );
        } else {
          state = SetIndexState(
            latestResult: state.latestResult,
            todayResults: state.todayResults,
            isLoading: state.isLoading,
            error: state.error,
            lastFetchTime: state.lastFetchTime,
            morningLiveSetValue: state.morningLiveSetValue,
            morningLiveSetIndex: state.morningLiveSetIndex,
            morningLiveResultDigit: state.morningLiveResultDigit,
            morningLiveUpdatedAt: state.morningLiveUpdatedAt,
            morningLiveError: state.morningLiveError,
            afternoonLiveSetValue: sv,
            afternoonLiveSetIndex: ix,
            afternoonLiveResultDigit: dg,
            afternoonLiveUpdatedAt: now,
            afternoonLiveError: null,
          );
        }
      } else {
        _setLiveErrorForActiveSession(
          inMorning: inMorning,
          message: 'Live quote unavailable',
        );
      }
    } catch (e) {
      if (!_pushUiUpdates) return;
      _setLiveErrorForActiveSession(
        inMorning: inMorning,
        message: e.toString(),
      );
    } finally {
      _livePollInFlight = false;
    }
  }

  void _setLiveErrorForActiveSession({
    required bool inMorning,
    required String message,
  }) {
    if (inMorning) {
      if (state.morningLiveSetValue != null) return;
      state = SetIndexState(
        latestResult: state.latestResult,
        todayResults: state.todayResults,
        isLoading: state.isLoading,
        error: state.error,
        lastFetchTime: state.lastFetchTime,
        morningLiveSetValue: state.morningLiveSetValue,
        morningLiveSetIndex: state.morningLiveSetIndex,
        morningLiveResultDigit: state.morningLiveResultDigit,
        morningLiveUpdatedAt: state.morningLiveUpdatedAt,
        morningLiveError: message,
        afternoonLiveSetValue: state.afternoonLiveSetValue,
        afternoonLiveSetIndex: state.afternoonLiveSetIndex,
        afternoonLiveResultDigit: state.afternoonLiveResultDigit,
        afternoonLiveUpdatedAt: state.afternoonLiveUpdatedAt,
        afternoonLiveError: state.afternoonLiveError,
      );
    } else {
      if (state.afternoonLiveSetValue != null) return;
      state = SetIndexState(
        latestResult: state.latestResult,
        todayResults: state.todayResults,
        isLoading: state.isLoading,
        error: state.error,
        lastFetchTime: state.lastFetchTime,
        morningLiveSetValue: state.morningLiveSetValue,
        morningLiveSetIndex: state.morningLiveSetIndex,
        morningLiveResultDigit: state.morningLiveResultDigit,
        morningLiveUpdatedAt: state.morningLiveUpdatedAt,
        morningLiveError: state.morningLiveError,
        afternoonLiveSetValue: state.afternoonLiveSetValue,
        afternoonLiveSetIndex: state.afternoonLiveSetIndex,
        afternoonLiveResultDigit: state.afternoonLiveResultDigit,
        afternoonLiveUpdatedAt: state.afternoonLiveUpdatedAt,
        afternoonLiveError: message,
      );
    }
  }

  @override
  void dispose() {
    stopLivePolling();
    super.dispose();
  }

  /// Load today's results from database
  Future<void> loadTodayResults() async {
    if (!_pushUiUpdates) return;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      List<SetIndexResult> results = const [];
      final cdnRows = await _apiService.fetchTodayFromCdn();
      if (cdnRows != null) {
        try {
          results = cdnRows.map(SetIndexResult.fromJson).toList();
        } catch (_) {
          results = const [];
        }
      }

      if (results.isEmpty) {
        final todayStr = bangkokTodayDateString();
        final response = await _client
            .from('set_index_history')
            .select()
            .eq('draw_date', todayStr)
            .order('draw_time', ascending: false);
        results = (response as List)
            .map((json) => SetIndexResult.fromJson(json))
            .toList();
      }

      if (!_pushUiUpdates) return;
      state = state.copyWith(
        todayResults: results,
        latestResult: results.isNotEmpty ? results.first : null,
        isLoading: false,
        lastFetchTime: DateTime.now(),
        clearError: true,
      );
    } catch (e) {
      if (!_pushUiUpdates) return;
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      print('Error loading today results: $e');
    }
  }

  /// Fetch new SET data from API and save to database
  Future<bool> fetchAndSaveNewResult({
    required String drawTime,
  }) async {
    if (!isMyanmarSetLiveFetchWindow()) {
      return false;
    }
    try {
      final setData = await _apiService.fetchSETData();

      final todayStr = bangkokTodayDateString();

      await _client.from('set_index_history').insert({
        'draw_date': todayStr,
        'draw_time': drawTime,
        'set_value': setData['set_value'],
        'set_index': setData['set_index'],
        'result_digit': setData['result_digit'],
        'source': 'api',
      });

      await loadTodayResults();

      return true;
    } catch (e) {
      print('Error fetching and saving SET result: $e');
      if (_pushUiUpdates) {
        state = state.copyWith(error: e.toString());
      }
      return false;
    }
  }

  /// Auto-fetch at scheduled times (Bangkok wall clock, aligned with SET / 2D apps).
  Future<void> autoFetchIfScheduled() async {
    final now = bangkokWallClockNow();

    final drawTimes = ['09:30', '12:01', '14:00', '16:30'];

    for (final drawTime in drawTimes) {
      final parts = drawTime.split(':');
      final drawHour = int.parse(parts[0]);
      final drawMinute = int.parse(parts[1]);

      if (now.hour == drawHour && (now.minute - drawMinute).abs() <= 5) {
        final alreadyFetched = state.todayResults.any((result) {
          return result.drawTime == '$drawTime:00';
        });

        if (!alreadyFetched) {
          await fetchAndSaveNewResult(drawTime: '$drawTime:00');
        }
      }
    }
  }

  SetIndexResult? getLatestResult() => state.latestResult;

  List<SetIndexResult> getTodayResults() => state.todayResults;
}

final setIndexControllerProvider =
    StateNotifierProvider<SetIndexController, SetIndexState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final apiService = SETAPIService();
  return SetIndexController(client, apiService);
});

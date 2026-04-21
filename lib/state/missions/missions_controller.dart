import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/mission.dart';
import '../../models/wallet.dart';
import '../auth/auth_controller.dart';

class MissionsState {
  final List<Mission> missions;
  final Wallet? wallet;
  final bool isLoading;
  final String? error;
  final Map<String, DateTime?> lastClaimedTimes;
  final Set<String> claimedOrSubmittedToday;

  MissionsState({
    this.missions = const [],
    this.wallet,
    this.isLoading = false,
    this.error,
    this.lastClaimedTimes = const {},
    this.claimedOrSubmittedToday = const <String>{},
  });

  MissionsState copyWith({
    List<Mission>? missions,
    Wallet? wallet,
    bool? isLoading,
    String? error,
    Map<String, DateTime?>? lastClaimedTimes,
    Set<String>? claimedOrSubmittedToday,
  }) {
    return MissionsState(
      missions: missions ?? this.missions,
      wallet: wallet ?? this.wallet,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastClaimedTimes: lastClaimedTimes ?? this.lastClaimedTimes,
      claimedOrSubmittedToday:
          claimedOrSubmittedToday ?? this.claimedOrSubmittedToday,
    );
  }

  bool canClaimMission(String missionId) {
    final lastClaimed = lastClaimedTimes[missionId];
    if (lastClaimed == null) return true;
    
    // Check if last claim was on a different day
    final now = DateTime.now();
    final lastClaimedDate = DateTime(lastClaimed.year, lastClaimed.month, lastClaimed.day);
    final todayDate = DateTime(now.year, now.month, now.day);
    
    return lastClaimedDate.isBefore(todayDate);
  }

  DateTime? getNextClaimTime(String missionId) {
    final lastClaimed = lastClaimedTimes[missionId];
    if (lastClaimed == null) return null;
    
    // Next claim is tomorrow at 00:01
    final tomorrow = DateTime(
      lastClaimed.year,
      lastClaimed.month,
      lastClaimed.day + 1,
      0,
      1,
    );
    
    return tomorrow;
  }
}

class MissionsController extends StateNotifier<MissionsState> {
  final SupabaseClient _client;
  final String? _userId;

  MissionsController(this._client, this._userId) : super(MissionsState());

  Future<void> loadData() async {
    if (_userId == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      await Future.wait([
        _loadWallet(),
        _loadMissions(),
        _loadUserMissions(),
        _loadTodayMissionClaims(),
      ]);

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> _loadWallet() async {
    if (_userId == null) return;

    final response = await _client
        .from('wallets')
        .select()
        .eq('user_id', _userId!)
        .maybeSingle();

    if (response != null) {
      state = state.copyWith(wallet: Wallet.fromJson(response));
    } else {
      // Create wallet if it doesn't exist
      await _client.from('wallets').insert({
        'user_id': _userId,
        'balance': 10000,
        'available_balance': 10000,
        'locked_balance': 0,
        'updated_at': DateTime.now().toIso8601String(),
      });

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

  Future<void> _loadMissions() async {
    try {
      final response = await _client
          .from('missions')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: true);

      final allMissions = (response as List)
          .map((json) => Mission.fromJson(json))
          .toList();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final missions = allMissions.where((m) {
        if (m.missionType == 'daily_free_coin') return true;
        final d = DateTime(m.createdAt.year, m.createdAt.month, m.createdAt.day);
        return d == today;
      }).toList();

      state = state.copyWith(missions: missions);
    } catch (e) {
      state = state.copyWith(missions: []);
    }
  }

  Future<void> _loadTodayMissionClaims() async {
    if (_userId == null) return;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).toUtc();
    final end = start.add(const Duration(days: 1));
    final rows = await _client
        .from('mission_claims')
        .select('mission_id, status')
        .eq('user_id', _userId!)
        .gte('claimed_at', start.toIso8601String())
        .lt('claimed_at', end.toIso8601String());
    final set = <String>{};
    for (final r in rows as List) {
      final status = '${r['status'] ?? ''}';
      if (status == 'pending' ||
          status == 'approved' ||
          status == 'auto_approved') {
        set.add('${r['mission_id']}');
      }
    }
    state = state.copyWith(claimedOrSubmittedToday: set);
  }

  Future<void> _loadUserMissions() async {
    if (_userId == null) return;

    final response = await _client
        .from('user_missions')
        .select()
        .eq('user_id', _userId!);

    final Map<String, DateTime?> lastClaimedTimes = {};
    for (final item in response as List) {
      final missionId = item['mission_id'] as String;
      final lastClaimedStr = item['last_claimed_at'] as String?;
      lastClaimedTimes[missionId] = lastClaimedStr != null 
          ? DateTime.parse(lastClaimedStr) 
          : null;
    }

    state = state.copyWith(lastClaimedTimes: lastClaimedTimes);
  }

  Future<bool> claimMission(String missionId) async {
    if (_userId == null) return false;

    try {
      final response = await _client.rpc('complete_daily_mission', params: {
        'p_mission_id': missionId,
      });

      if (response['success'] == true) {
        // Reload data to get updated wallet balance and claim times
        await loadData();
        return true;
      } else {
        state = state.copyWith(error: response['error'] as String?);
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<Map<String, dynamic>> submitMissionClaim({
    required String missionId,
    String? proofText,
    String? proofUrl,
    bool adWatched = false,
  }) async {
    if (_userId == null) return {'ok': false, 'error': 'Not logged in'};

    try {
      final response = await _client.rpc('submit_mission_claim', params: {
        'p_mission_id': missionId,
        'p_proof_text': proofText,
        'p_proof_url': proofUrl,
        'p_ad_watched': adWatched,
      });
      final map = Map<String, dynamic>.from(response as Map);
      if (map['ok'] == true) {
        await loadData();
      } else {
        state = state.copyWith(error: map['error'] as String?);
      }
      return map;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return {'ok': false, 'error': e.toString()};
    }
  }
}

final missionsControllerProvider =
    StateNotifierProvider<MissionsController, MissionsState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final user = ref.watch(currentUserProvider);
  return MissionsController(client, user?.id);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/mission.dart';
import '../../models/wallet.dart';
import '../auth/auth_controller.dart';

class MissionState {
  final List<Mission> missions;
  final Map<String, UserMission> userMissions;
  final Wallet? wallet;
  final bool isLoading;
  final String? error;

  MissionState({
    this.missions = const [],
    this.userMissions = const {},
    this.wallet,
    this.isLoading = false,
    this.error,
  });

  MissionState copyWith({
    List<Mission>? missions,
    Map<String, UserMission>? userMissions,
    Wallet? wallet,
    bool? isLoading,
    String? error,
  }) {
    return MissionState(
      missions: missions ?? this.missions,
      userMissions: userMissions ?? this.userMissions,
      wallet: wallet ?? this.wallet,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class MissionController extends StateNotifier<MissionState> {
  final SupabaseClient _client;
  final String? _userId;

  MissionController(this._client, this._userId) : super(MissionState());

  Future<void> loadData() async {
    if (_userId == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      await Future.wait([
        _loadMissions(),
        _loadUserMissions(),
        _loadWallet(),
      ]);

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> _loadMissions() async {
    final response = await _client
        .from('missions')
        .select()
        .order('created_at', ascending: true);

    final missions = (response as List)
        .map((json) => Mission.fromJson(json))
        .toList();

    state = state.copyWith(missions: missions);
  }

  Future<void> _loadUserMissions() async {
    if (_userId == null) return;

    final response = await _client
        .from('user_missions')
        .select('*, missions(*)')
        .eq('user_id', _userId!);

    final userMissions = <String, UserMission>{};
    for (final json in response as List) {
      final userMission = UserMission.fromJson(json);
      userMissions[userMission.missionId] = userMission;
    }

    state = state.copyWith(userMissions: userMissions);
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
    }
  }

  Future<bool> claimMission(String missionId) async {
    if (_userId == null) return false;

    try {
      final response = await _client.rpc('complete_daily_mission', params: {
        'p_mission_id': missionId,
      });

      if (response['success'] == true) {
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
    if (_userId == null) {
      return {'ok': false, 'error': 'Not logged in'};
    }

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
      final err = e.toString();
      state = state.copyWith(error: err);
      return {'ok': false, 'error': err};
    }
  }

  bool canClaimMission(String missionId) {
    final userMission = state.userMissions[missionId];
    if (userMission == null) return true;
    return userMission.canClaim();
  }

  Duration? timeUntilNextClaim(String missionId) {
    final userMission = state.userMissions[missionId];
    if (userMission == null) return null;
    if (userMission.canClaim()) return null;
    return userMission.timeUntilNextClaim();
  }
}

final missionControllerProvider =
    StateNotifierProvider<MissionController, MissionState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final user = ref.watch(currentUserProvider);
  return MissionController(client, user?.id);
});

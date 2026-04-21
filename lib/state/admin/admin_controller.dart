import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AdminStatsPreset { session330, day, week, month, custom }

final adminClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final isAdminProvider = FutureProvider<bool>((ref) async {
  final client = ref.watch(adminClientProvider);
  final user = client.auth.currentUser;
  if (user == null) return false;

  final row = await client
      .from('profiles')
      .select('is_admin')
      .eq('id', user.id)
      .maybeSingle();
  return (row?['is_admin'] as bool?) ?? false;
});

final adminWalletBalanceProvider = FutureProvider<int>((ref) async {
  final client = ref.watch(adminClientProvider);
  try {
    final raw = await client.rpc('house_total_balance');
    if (raw is List && raw.isNotEmpty) {
      final row = Map<String, dynamic>.from(raw.first as Map);
      return (row['total'] as num?)?.toInt() ?? 0;
    }
  } catch (_) {
    // Fallback for older DBs where house_total_balance is unavailable.
  }
  final row = await client
      .from('admin_wallet')
      .select('balance')
      .order('updated_at', ascending: false)
      .limit(1)
      .maybeSingle();
  return (row?['balance'] as num?)?.toInt() ?? 0;
});

final adminTopUsersProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(adminClientProvider);
  final raw = await client.rpc('admin_top10_non_admin_balances');
  final list = (raw as List?) ?? const [];
  return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
});

final adminTotalUserBalanceProvider = FutureProvider<int>((ref) async {
  final client = ref.watch(adminClientProvider);
  final raw = await client.rpc('admin_total_non_admin_balance');
  return (raw as num?)?.toInt() ?? 0;
});

final adminRecentAuditProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(adminClientProvider);
  final rows = await client
      .from('audit_logs')
      .select('action, target_type, reason, created_at')
      .order('created_at', ascending: false)
      .limit(20);
  return (rows as List).map((e) => Map<String, dynamic>.from(e)).toList();
});

final adminReportedPostsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(adminClientProvider);
  final rows = await client
      .from('reported_posts')
      .select(
          'report_id, post_id, reporter_user_id, reason, details, status, created_at')
      .eq('status', 'pending')
      .order('created_at', ascending: false)
      .limit(30);
  return (rows as List).map((e) => Map<String, dynamic>.from(e)).toList();
});

final adminPendingPostModerationProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(adminClientProvider);
  final rows = await client
      .from('posts')
      .select(
          'post_id, user_id, content, image_url, moderation_status, moderation_reason, created_at')
      .inFilter('moderation_status', ['pending_image_review', 'blocked'])
      .order('created_at', ascending: false)
      .limit(30);
  return (rows as List).map((e) => Map<String, dynamic>.from(e)).toList();
});

final adminLatestPayoutRunProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  final client = ref.watch(adminClientProvider);
  final row = await client
      .from('payout_runs')
      .select(
          'run_id, winning_digit, total_winners, total_payout, batch_count, window_minutes, status, prepared_at, completed_at')
      .order('prepared_at', ascending: false)
      .limit(1)
      .maybeSingle();
  if (row == null) return null;
  return Map<String, dynamic>.from(row);
});

final adminLatestPayoutRunStatsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final client = ref.watch(adminClientProvider);
  final run = await ref.watch(adminLatestPayoutRunProvider.future);
  if (run == null) {
    return {
      'queued': 0,
      'processing': 0,
      'paid': 0,
      'failed': 0,
      'total': 0,
    };
  }
  final runId = '${run['run_id']}';
  final rows = await client
      .from('payout_jobs')
      .select('status')
      .eq('run_id', runId);

  int queued = 0, processing = 0, paid = 0, failed = 0;
  for (final r in rows as List) {
    switch ('${r['status'] ?? ''}') {
      case 'queued':
        queued++;
        break;
      case 'processing':
        processing++;
        break;
      case 'paid':
        paid++;
        break;
      case 'failed':
        failed++;
        break;
      default:
        break;
    }
  }
  return {
    'queued': queued,
    'processing': processing,
    'paid': paid,
    'failed': failed,
    'total': queued + processing + paid + failed,
  };
});

final adminBetKpisProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final stats = await ref.watch(adminDashboardStatsProvider.future);
  return {
    'bet_users': stats['total_bet_user'] ?? 0,
    'win_users': stats['total_win_user'] ?? 0,
    'lose_users': stats['total_lose_user'] ?? 0,
    'total_stake': stats['total_bet_amount'] ?? 0,
    'total_payout': stats['admin_payout_amount'] ?? 0,
    'admin_profit': stats['admin_profit_amount'] ?? 0,
  };
});

final adminStatsPresetProvider =
    StateProvider<AdminStatsPreset>((ref) => AdminStatsPreset.day);
final adminStatsFromProvider = StateProvider<DateTime?>((ref) => null);
final adminStatsToProvider = StateProvider<DateTime?>((ref) => null);

final adminDashboardStatsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final client = ref.watch(adminClientProvider);
  final preset = ref.watch(adminStatsPresetProvider);
  final from = ref.watch(adminStatsFromProvider);
  final to = ref.watch(adminStatsToProvider);
  final presetValue = switch (preset) {
    AdminStatsPreset.session330 => 'session_330',
    AdminStatsPreset.day => 'day',
    AdminStatsPreset.week => 'week',
    AdminStatsPreset.month => 'month',
    AdminStatsPreset.custom => 'custom',
  };
  final raw = await client.rpc('admin_dashboard_stats', params: {
    'p_preset': presetValue,
    'p_from': from?.toIso8601String(),
    'p_to': to?.toIso8601String(),
  });
  final list = (raw as List?) ?? const [];
  if (list.isEmpty) {
    return {
      'total_bet_user': 0,
      'total_bet_amount': 0,
      'total_win_user': 0,
      'total_win_bet_amount': 0,
      'total_lose_user': 0,
      'total_bet_lose_amount': 0,
      'admin_payout_amount': 0,
      'admin_profit_amount': 0,
    };
  }
  return Map<String, dynamic>.from(list.first as Map);
});

class AdminActions {
  AdminActions(this._client);
  final SupabaseClient _client;

  Future<void> adjustUserCoin({
    required String userId,
    required int delta,
    required String reason,
  }) async {
    await _client.rpc('admin_adjust_user_coin', params: {
      'p_user_id': userId,
      'p_delta': delta,
      'p_reason': reason,
    });
  }

  Future<void> banUser({
    required String userId,
    required bool isBanned,
    DateTime? bannedUntil,
    String? reason,
  }) async {
    await _client.rpc('admin_ban_user', params: {
      'p_user_id': userId,
      'p_is_banned': isBanned,
      'p_banned_until': bannedUntil?.toIso8601String(),
      'p_reason': reason,
    });
  }

  Future<void> softDeletePost({
    required String postId,
    String? reason,
  }) async {
    await _client.rpc('admin_soft_delete_post', params: {
      'p_post_id': postId,
      'p_reason': reason,
    });
  }

  Future<void> upsertMission({
    String? missionId,
    required String title,
    String? description,
    required String missionType,
    required int rewardCoin,
    String? actionLink,
    String platform = 'custom',
    String missionKind = 'external_link',
    String missionAction = 'custom',
  }) async {
    await _client.rpc('admin_create_or_update_mission', params: {
      'p_mission_id': missionId,
      'p_title': title,
      'p_description': description,
      'p_mission_type': missionType,
      'p_reward_coin': rewardCoin,
      'p_action_link': actionLink,
      'p_platform': platform,
      'p_mission_kind': missionKind,
      'p_mission_action': missionAction,
    });
  }

  Future<void> fundAdminWallet({
    required int amount,
    required String reason,
  }) async {
    await _client.rpc('admin_fund_admin_wallet', params: {
      'p_amount': amount,
      'p_reason': reason,
    });
  }

  Future<void> reviewReportedPost({
    required String reportId,
    required String status,
  }) async {
    await _client.rpc('admin_review_reported_post', params: {
      'p_report_id': reportId,
      'p_status': status,
    });
  }

  Future<void> setPostModeration({
    required String postId,
    required String status,
    String? reason,
  }) async {
    await _client.rpc('admin_set_post_moderation', params: {
      'p_post_id': postId,
      'p_status': status,
      'p_reason': reason,
    });
  }

  /// Insert or update a catalog row (`kind` must be flower | rabbit | cat).
  Future<void> upsertGiftItem(Map<String, dynamic> row) async {
    await _client.from('gift_items').upsert(row);
  }

  Future<void> insertGiftItem(Map<String, dynamic> row) async {
    await _client.from('gift_items').insert(row);
  }

}

final adminActionsProvider = Provider<AdminActions>((ref) {
  return AdminActions(ref.watch(adminClientProvider));
});


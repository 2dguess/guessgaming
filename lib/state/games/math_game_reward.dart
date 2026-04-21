import 'package:supabase_flutter/supabase_flutter.dart';

/// Server-side math game rewards (see `supabase/math_game_rewards.sql`).
Future<Map<String, dynamic>> claimMathGameReward(
  SupabaseClient client, {
  required String sessionId,
  required String kind,
}) async {
  final res = await client.rpc(
    'claim_math_game_reward',
    params: {
      'p_session_id': sessionId,
      'p_kind': kind,
    },
  );
  return Map<String, dynamic>.from(res as Map);
}

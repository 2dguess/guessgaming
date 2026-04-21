import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/gift_item.dart';
import '../../models/post_gift.dart';
import '../auth/auth_controller.dart';
import '../betting/betting_controller.dart';

/// Batch totals for feed/profile (only gifts on each post).
Future<Map<String, PostGiftTotals>> fetchPostGiftTotalsMap(
  SupabaseClient client,
  List<String> postIds,
) async {
  if (postIds.isEmpty) return {};
  final raw = await client.rpc(
    'post_gift_totals_for_posts',
    params: {'p_post_ids': postIds},
  );
  final map = <String, PostGiftTotals>{};
  for (final row in raw as List) {
    final m = Map<String, dynamic>.from(row as Map);
    final id = '${m['post_id']}';
    map[id] = PostGiftTotals(
      totalPopularity: (m['total_popularity'] as num?)?.toInt() ?? 0,
      giftCount: (m['gift_count'] as num?)?.toInt() ?? 0,
    );
  }
  return map;
}

Future<List<PostGiftSenderLine>> fetchPostGiftSendersForOwner(
  SupabaseClient client,
  String postId,
) async {
  final raw = await client.rpc(
    'list_post_gifts_for_owner',
    params: {'p_post_id': postId},
  );
  if (raw == null) return [];
  if (raw is! List) return [];
  return raw
      .map((e) => PostGiftSenderLine.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
}

final userReceivedGiftInventoryProvider =
    FutureProvider<List<UserReceivedGiftLine>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final raw = await client.rpc('user_received_gift_inventory');
  final rows = (raw as List?) ?? const [];
  return rows
      .map((e) => UserReceivedGiftLine.fromRow(Map<String, dynamic>.from(e as Map)))
      .toList();
});

final giftItemsProvider = FutureProvider<List<GiftItem>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final rows = await client
      .from('gift_items')
      .select()
      .eq('is_active', true)
      .order('sort_order', ascending: true);
  return (rows as List)
      .map((e) => GiftItem.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
});

final adminGiftItemsProvider = FutureProvider<List<GiftItem>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final rows = await client.from('gift_items').select().order('sort_order', ascending: true);
  return (rows as List)
      .map((e) => GiftItem.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
});

Future<Map<String, dynamic>> sendPostGift(
  WidgetRef ref, {
  required String postId,
  required String giftItemId,
}) async {
  final client = ref.read(supabaseClientProvider);
  final res = await client.rpc(
    'send_post_gift',
    params: {
      'p_post_id': postId,
      'p_gift_item_id': giftItemId,
    },
  );
  final map = Map<String, dynamic>.from(res as Map);
  if (map['ok'] == true) {
    ref.invalidate(bettingControllerProvider);
  }
  return map;
}

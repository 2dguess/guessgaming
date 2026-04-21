import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/in_app_notification.dart';
import '../auth/auth_controller.dart';

final notificationsProvider =
    FutureProvider.autoDispose<List<InAppNotificationItem>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final uid = ref.watch(currentUserProvider)?.id;
  if (uid == null) return [];

  try {
    final rows = await client
        .from('notifications')
        .select()
        .eq('recipient_id', uid)
        .order('created_at', ascending: false)
        .limit(50);

    final list = rows as List;
    if (list.isEmpty) return [];

    final actorIds =
        list.map((r) => r['actor_id'] as String).toSet().toList();
    final orFilter = actorIds.map((id) => 'id.eq.$id').join(',');
    final profiles =
        await client.from('profiles').select('id, username').or(orFilter);

    final nameMap = <String, String>{};
    for (final p in profiles as List) {
      nameMap[p['id'] as String] = p['username'] as String? ?? '?';
    }

    return list
        .map((r) => InAppNotificationItem.fromRow(
              Map<String, dynamic>.from(r as Map<dynamic, dynamic>),
              nameMap,
            ))
        .toList();
  } catch (e) {
    return [];
  }
});

final unreadNotificationsCountProvider =
    FutureProvider.autoDispose<int>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final uid = ref.watch(currentUserProvider)?.id;
  if (uid == null) return 0;

  try {
    final rows = await client
        .from('notifications')
        .select('read_at')
        .eq('recipient_id', uid);
    return (rows as List).where((r) => r['read_at'] == null).length;
  } catch (_) {
    return 0;
  }
});

/// Subscribes to `notifications` for the signed-in user; invalidates list + unread on change.
/// Requires Realtime enabled for table `notifications` (see supabase/notifications.sql footer).
final notificationsRealtimeBootstrapProvider = Provider<void>((ref) {
  final user = ref.watch(currentUserProvider);
  final client = ref.read(supabaseClientProvider);

  if (user == null) return;

  void bump() {
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadNotificationsCountProvider);
  }

  final channel = client.channel('inbox-${user.id}');

  channel
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'recipient_id',
          value: user.id,
        ),
        callback: (_) => bump(),
      )
      .subscribe();

  ref.onDispose(() {
    client.removeChannel(channel);
  });
});

Future<void> markAllNotificationsRead(WidgetRef ref) async {
  final client = ref.read(supabaseClientProvider);
  final uid = ref.read(currentUserProvider)?.id;
  if (uid == null) return;
  try {
    final now = DateTime.now().toUtc().toIso8601String();
    await client
        .from('notifications')
        .update({'read_at': now})
        .eq('recipient_id', uid)
        .isFilter('read_at', null);
    ref.invalidate(unreadNotificationsCountProvider);
    ref.invalidate(notificationsProvider);
  } catch (_) {}
}

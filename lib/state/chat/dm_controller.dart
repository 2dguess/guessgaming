import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/app_profile.dart';
import '../../models/dm_models.dart';
import '../auth/auth_controller.dart';

/// Canonical ordering for `dm_threads.user_a < user_b` (lexicographic UUID strings).
(String, String) dmOrderedPair(String id1, String id2) {
  if (id1.compareTo(id2) <= 0) return (id1, id2);
  return (id2, id1);
}

final dmRepositoryProvider = Provider<DmRepository>((ref) {
  return DmRepository(ref.watch(supabaseClientProvider));
});

class DmRepository {
  DmRepository(this._client);
  final SupabaseClient _client;

  static DateTime? _parseTs(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  static int _parseCount(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  Future<int> _countUnreadInbound(
    String threadId,
    String me,
    DateTime? myRead,
  ) async {
    try {
      var q = _client
          .from('dm_messages')
          .select('id')
          .eq('thread_id', threadId)
          .neq('sender_id', me);
      if (myRead != null) {
        q = q.gt('created_at', myRead.toUtc().toIso8601String());
      }
      final res = await q;
      return (res as List).length;
    } catch (_) {
      return 0;
    }
  }

  /// One row per thread that has unread inbound; used to show 2, 3, … on chat list.
  /// Returns null if the RPC is missing or failed (use per-thread fallback).
  Future<Map<String, int>?> _fetchUnreadInboundCountsFromRpc() async {
    try {
      final res = await _client.rpc('dm_unread_inbound_counts');
      if (res is! List) return {};
      final map = <String, int>{};
      for (final row in res) {
        final m = Map<String, dynamic>.from(row as Map);
        final tid = m['thread_id'] as String?;
        if (tid == null) continue;
        map[tid] = _parseCount(m['unread_count']);
      }
      return map;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, int>> _resolveUnreadInboundCounts(
    String me,
    Map<String, DateTime?> myReadByThread,
  ) async {
    final fromRpc = await _fetchUnreadInboundCountsFromRpc();
    if (fromRpc != null) {
      return fromRpc;
    }
    final out = <String, int>{};
    for (final e in myReadByThread.entries) {
      out[e.key] = await _countUnreadInbound(e.key, me, e.value);
    }
    return out;
  }

  Future<String> getOrCreateThread({
    required String me,
    required String otherUserId,
  }) async {
    if (me == otherUserId) {
      throw ArgumentError('Cannot DM yourself');
    }
    final (a, b) = dmOrderedPair(me, otherUserId);

    final existing = await _client
        .from('dm_threads')
        .select('id')
        .eq('user_a', a)
        .eq('user_b', b)
        .maybeSingle();

    if (existing != null) {
      return existing['id'] as String;
    }

    try {
      final inserted = await _client.from('dm_threads').insert({
        'user_a': a,
        'user_b': b,
      }).select('id').single();
      return inserted['id'] as String;
    } catch (_) {
      final again = await _client
          .from('dm_threads')
          .select('id')
          .eq('user_a', a)
          .eq('user_b', b)
          .maybeSingle();
      if (again != null) return again['id'] as String;
      rethrow;
    }
  }

  Future<List<DmThreadPreview>> fetchThreadPreviews(String me) async {
    dynamic rows;
    var hasReadColumns = true;
    try {
      rows = await _client
          .from('dm_threads')
          .select(
            'id, user_a, user_b, last_message_at, user_a_last_read_at, user_b_last_read_at',
          )
          .or('user_a.eq.$me,user_b.eq.$me')
          .order('last_message_at', ascending: false);
    } catch (_) {
      hasReadColumns = false;
      rows = await _client
          .from('dm_threads')
          .select('id, user_a, user_b, last_message_at')
          .or('user_a.eq.$me,user_b.eq.$me')
          .order('last_message_at', ascending: false);
    }

    final myReadByThread = <String, DateTime?>{};
    final list = <DmThreadPreview>[];
    for (final row in rows as List) {
      final map = row as Map<String, dynamic>;
      final threadId = map['id'] as String;
      final ua = map['user_a'] as String;
      final ub = map['user_b'] as String;
      final other = ua == me ? ub : ua;
      final DateTime? myRead = hasReadColumns
          ? (ua == me
              ? _parseTs(map['user_a_last_read_at'])
              : _parseTs(map['user_b_last_read_at']))
          : null;
      myReadByThread[threadId] = myRead;

      final profileRow = await _client
          .from('profiles')
          .select()
          .eq('id', other)
          .maybeSingle();
      AppProfile? profile;
      if (profileRow != null) {
        profile = AppProfile.fromJson(Map<String, dynamic>.from(profileRow));
      }

      final lastMsg = await _client
          .from('dm_messages')
          .select('body, created_at, sender_id')
          .eq('thread_id', threadId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      String? preview;
      DateTime? lastAt;
      if (lastMsg != null) {
        preview = lastMsg['body'] as String?;
        if (preview != null && preview.length > 80) {
          preview = '${preview.substring(0, 80)}…';
        }
        if (lastMsg['created_at'] != null) {
          lastAt = DateTime.parse(lastMsg['created_at'] as String);
        }
      }

      list.add(DmThreadPreview(
        threadId: threadId,
        otherUserId: other,
        otherProfile: profile,
        lastMessagePreview: preview,
        lastMessageAt: lastAt ??
            (map['last_message_at'] != null
                ? DateTime.tryParse(map['last_message_at'].toString())
                : null),
        unreadInboundCount: 0,
      ));
    }

    final counts = await _resolveUnreadInboundCounts(me, myReadByThread);
    final merged = list
        .map(
          (p) => p.copyWith(
            unreadInboundCount: counts[p.threadId] ?? 0,
          ),
        )
        .toList();

    merged.sort((x, y) {
      final ax = x.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final ay = y.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return ay.compareTo(ax);
    });

    return merged;
  }

  Future<List<DmMessage>> fetchMessages(String threadId, String? me) async {
    final res = await _client
        .from('dm_messages')
        .select()
        .eq('thread_id', threadId)
        .order('created_at', ascending: true);

    var messages = (res as List)
        .map((e) => DmMessage.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    if (me == null || messages.isEmpty) return messages;

    final ids = messages.map((m) => m.id).toList();
    try {
      final likeRows = await _client
          .from('dm_message_likes')
          .select('message_id, user_id')
          .inFilter('message_id', ids);

      final counts = <String, int>{};
      final likedIds = <String>{};
      for (final row in likeRows as List) {
        final m = Map<String, dynamic>.from(row as Map);
        final mid = m['message_id'] as String?;
        if (mid == null) continue;
        counts[mid] = (counts[mid] ?? 0) + 1;
        if (m['user_id'] == me) likedIds.add(mid);
      }

      messages = messages
          .map(
            (msg) => msg.copyWith(
              likesCount: counts[msg.id] ?? 0,
              likedByMe: likedIds.contains(msg.id),
            ),
          )
          .toList();
    } catch (_) {
      // Table or policy missing until migration is applied.
    }

    return messages;
  }

  Future<void> toggleDmMessageLike({
    required String messageId,
    required String userId,
  }) async {
    final existing = await _client
        .from('dm_message_likes')
        .select('message_id')
        .eq('message_id', messageId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) {
      await _client
          .from('dm_message_likes')
          .delete()
          .eq('message_id', messageId)
          .eq('user_id', userId);
    } else {
      await _client.from('dm_message_likes').insert({
        'message_id': messageId,
        'user_id': userId,
      });
    }
  }

  Future<DmThreadReadState?> fetchThreadReadState(String threadId) async {
    try {
      final row = await _client
          .from('dm_threads')
          .select('id, user_a, user_b, user_a_last_read_at, user_b_last_read_at')
          .eq('id', threadId)
          .maybeSingle();
      if (row == null) return null;
      final m = Map<String, dynamic>.from(row);
      return DmThreadReadState(
        threadId: m['id'] as String,
        userA: m['user_a'] as String,
        userB: m['user_b'] as String,
        userALastReadAt: _parseTs(m['user_a_last_read_at']),
        userBLastReadAt: _parseTs(m['user_b_last_read_at']),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> markThreadRead(String threadId) async {
    try {
      await _client.rpc('dm_mark_thread_read', params: {'p_thread_id': threadId});
    } catch (_) {
      // Migration not applied or RPC missing — ignore.
    }
  }

  /// Distinct conversations with at least one unread inbound message (matches feed badge).
  Future<int> fetchUnreadConversationCount(String me) async {
    try {
      final res = await _client.rpc('dm_unread_conversation_count');
      if (res is int) return res;
      if (res is num) return res.toInt();
      return int.tryParse('$res') ?? 0;
    } catch (_) {
      final previews = await fetchThreadPreviews(me);
      return previews.where((p) => p.hasUnreadFromOther).length;
    }
  }

  Future<void> sendMessage({
    required String threadId,
    required String senderId,
    required String body,
  }) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return;
    await _client.from('dm_messages').insert({
      'thread_id': threadId,
      'sender_id': senderId,
      'body': trimmed,
    });
  }
}

final dmThreadListProvider =
    FutureProvider.autoDispose<List<DmThreadPreview>>((ref) async {
  final me = ref.watch(currentUserProvider)?.id;
  if (me == null) return [];
  return ref.watch(dmRepositoryProvider).fetchThreadPreviews(me);
});

final dmMessagesProvider =
    FutureProvider.autoDispose.family<List<DmMessage>, String>((ref, threadId) async {
  final me = ref.watch(currentUserProvider)?.id;
  return ref.watch(dmRepositoryProvider).fetchMessages(threadId, me);
});

final dmThreadReadStateProvider =
    FutureProvider.autoDispose.family<DmThreadReadState?, String>((ref, threadId) async {
  return ref.watch(dmRepositoryProvider).fetchThreadReadState(threadId);
});

final dmUnreadConversationsCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final me = ref.watch(currentUserProvider)?.id;
  if (me == null) return 0;
  return ref.watch(dmRepositoryProvider).fetchUnreadConversationCount(me);
});

/// Invalidates DM lists/counts when messages or thread read state change (enable Realtime on `dm_messages` + `dm_threads`).
final dmInboxRealtimeBootstrapProvider = Provider<void>((ref) {
  final user = ref.watch(currentUserProvider);
  final client = ref.read(supabaseClientProvider);
  if (user == null) return;

  void bump() {
    ref.invalidate(dmUnreadConversationsCountProvider);
    ref.invalidate(dmThreadListProvider);
  }

  void bumpThread(PostgresChangePayload payload) {
    bump();
    final id = payload.newRecord['id'];
    if (id is String) {
      ref.invalidate(dmThreadReadStateProvider(id));
    }
  }

  final ch1 = client.channel('dm-inbox-msgs-${user.id}');
  ch1
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'dm_messages',
        callback: (_) => bump(),
      )
      .subscribe();

  final ch2 = client.channel('dm-inbox-threads-${user.id}');
  ch2
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'dm_threads',
        callback: bumpThread,
      )
      .subscribe();

  ref.onDispose(() {
    client.removeChannel(ch1);
    client.removeChannel(ch2);
  });
});

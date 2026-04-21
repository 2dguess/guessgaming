import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/app_post.dart';

class FeedCacheSnapshot {
  final DateTime cachedAt;
  final List<AppPost> posts;

  const FeedCacheSnapshot({
    required this.cachedAt,
    required this.posts,
  });
}

class FeedCacheStore {
  static const Duration ttl = Duration(hours: 48);
  static const String _indexKey = 'feed_cache_keys_v1';
  static const int maxTotalCacheBytes = 500 * 1024 * 1024; // 500MB

  static String _cacheKey(String userId) => 'feed_cache_v1_$userId';

  static Future<FeedCacheSnapshot?> read(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await _cleanupExpired(prefs);

    final raw = prefs.getString(_cacheKey(userId));
    if (raw == null || raw.isEmpty) return null;

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(map['cached_at'] as String);
      if (DateTime.now().toUtc().difference(cachedAt) > ttl) {
        await prefs.remove(_cacheKey(userId));
        return null;
      }

      final rows = (map['posts'] as List? ?? const [])
          .cast<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final posts = rows.map(AppPost.fromJson).toList();
      return FeedCacheSnapshot(cachedAt: cachedAt, posts: posts);
    } catch (_) {
      await prefs.remove(_cacheKey(userId));
      return null;
    }
  }

  static Future<void> write(String userId, List<AppPost> posts) async {
    final prefs = await SharedPreferences.getInstance();
    await _cleanupExpired(prefs);

    final compact = posts.map((p) => p.toJson()).toList();
    final payload = jsonEncode({
      'cached_at': DateTime.now().toUtc().toIso8601String(),
      'posts': compact,
    });

    await prefs.setString(_cacheKey(userId), payload);
    await _addToIndex(prefs, _cacheKey(userId));
    await _enforceSizeLimit(prefs);
  }

  static Future<void> _addToIndex(SharedPreferences prefs, String key) async {
    final existing = prefs.getStringList(_indexKey) ?? const <String>[];
    if (existing.contains(key)) return;
    await prefs.setStringList(_indexKey, [...existing, key]);
  }

  static Future<void> _cleanupExpired(SharedPreferences prefs) async {
    final keys = prefs.getStringList(_indexKey) ?? const <String>[];
    if (keys.isEmpty) return;

    final keep = <String>[];
    final now = DateTime.now().toUtc();

    for (final key in keys) {
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) continue;
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final cachedAt = DateTime.parse(map['cached_at'] as String);
        if (now.difference(cachedAt) > ttl) {
          await prefs.remove(key);
        } else {
          keep.add(key);
        }
      } catch (_) {
        await prefs.remove(key);
      }
    }

    await prefs.setStringList(_indexKey, keep);
  }

  static Future<void> _enforceSizeLimit(SharedPreferences prefs) async {
    final keys = prefs.getStringList(_indexKey) ?? const <String>[];
    if (keys.isEmpty) return;

    final entries = <({String key, DateTime cachedAt, int sizeBytes})>[];
    int total = 0;

    for (final key in keys) {
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) continue;
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final cachedAt = DateTime.parse(map['cached_at'] as String);
        final sizeBytes = utf8.encode(raw).length;
        entries.add((key: key, cachedAt: cachedAt, sizeBytes: sizeBytes));
        total += sizeBytes;
      } catch (_) {
        await prefs.remove(key);
      }
    }

    if (total <= maxTotalCacheBytes) {
      await prefs.setStringList(_indexKey, entries.map((e) => e.key).toList());
      return;
    }

    // Remove oldest cache entries first until total size <= 500MB.
    entries.sort((a, b) => a.cachedAt.compareTo(b.cachedAt));
    final keep = <String>[];
    var rolling = total;
    for (final e in entries) {
      if (rolling > maxTotalCacheBytes) {
        await prefs.remove(e.key);
        rolling -= e.sizeBytes;
      } else {
        keep.add(e.key);
      }
    }

    await prefs.setStringList(_indexKey, keep);
  }
}


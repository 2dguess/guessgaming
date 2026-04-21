import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists which winning bet rows we already showed a celebration for (per user).
class BetWinCelebrationPrefs {
  BetWinCelebrationPrefs._();

  static String _seededKey(String userId) => 'bet_win_celeb_seeded_$userId';
  static String _idsKey(String userId) => 'bet_win_celeb_ids_$userId';

  static Future<bool> isSeeded(String userId) async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_seededKey(userId)) ?? false;
  }

  static Future<Set<String>> loadIds(String userId) async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_idsKey(userId));
    if (s == null || s.isEmpty) return {};
    try {
      final list = jsonDecode(s) as List<dynamic>;
      return list.map((e) => e.toString()).toSet();
    } catch (_) {
      return {};
    }
  }

  /// First sync: remember all current wins without UI (avoids spamming old wins).
  static Future<void> seedInitialWins(String userId, Iterable<String> winBetIds) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_seededKey(userId), true);
    final existing = await loadIds(userId);
    existing.addAll(winBetIds);
    await p.setString(_idsKey(userId), jsonEncode(existing.toList()));
  }

  static Future<void> markCelebrated(String userId, Iterable<String> betIds) async {
    final p = await SharedPreferences.getInstance();
    final existing = await loadIds(userId);
    existing.addAll(betIds);
    await p.setString(_idsKey(userId), jsonEncode(existing.toList()));
  }
}

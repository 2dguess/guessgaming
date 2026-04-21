import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../auth/auth_controller.dart';
import '../../utils/myanmar_math_game_day.dart';

const _kDayKey = 'math_game_myanmar_day';
const _kCountKey = 'math_game_play_count';
const mathGameDailyMaxPlays = 20;

/// Loads current play count for today's Myanmar game window (01:00–next 01:00).
final mathGameDailyPlayProvider =
    FutureProvider.autoDispose<MathGameDailyPlay>((ref) async {
  final userId = ref.watch(currentUserProvider)?.id;
  return MathGameDailyPlay.load(userId: userId);
});

class MathGameDailyPlay {
  MathGameDailyPlay._({
    required this.playsCompleted,
    required this.maxPlays,
  });

  final int playsCompleted;
  final int maxPlays;

  bool get canStartNewGame => playsCompleted < maxPlays;

  /// e.g. `3/20`
  String get label => '$playsCompleted/$maxPlays';

  static String _dayKey(String userId) => '$_kDayKey:$userId';
  static String _countKey(String userId) => '$_kCountKey:$userId';

  static Future<MathGameDailyPlay> load({required String? userId}) async {
    if (userId == null) {
      return MathGameDailyPlay._(
        playsCompleted: 0,
        maxPlays: mathGameDailyMaxPlays,
      );
    }
    final prefs = await SharedPreferences.getInstance();
    final yangon = tz.getLocation('Asia/Yangon');
    final day = myanmarMathGameDayKey(yangon);
    final dayKey = _dayKey(userId);
    final countKey = _countKey(userId);
    final stored = prefs.getString(dayKey);
    if (stored != day) {
      await prefs.setString(dayKey, day);
      await prefs.setInt(countKey, 0);
    }
    final n = prefs.getInt(countKey) ?? 0;
    return MathGameDailyPlay._(
      playsCompleted: n.clamp(0, mathGameDailyMaxPlays),
      maxPlays: mathGameDailyMaxPlays,
    );
  }

  /// Call when the user **finishes one full game** (wins 3 rounds). Returns false if cap reached.
  static Future<bool> recordCompletedGame({required String? userId}) async {
    if (userId == null) return false;
    final prefs = await SharedPreferences.getInstance();
    final yangon = tz.getLocation('Asia/Yangon');
    final day = myanmarMathGameDayKey(yangon);
    final dayKey = _dayKey(userId);
    final countKey = _countKey(userId);
    final stored = prefs.getString(dayKey);
    if (stored != day) {
      await prefs.setString(dayKey, day);
      await prefs.setInt(countKey, 0);
    }
    final c = prefs.getInt(countKey) ?? 0;
    if (c >= mathGameDailyMaxPlays) {
      return false;
    }
    await prefs.setInt(countKey, c + 1);
    return true;
  }
}

// Myanmar Standard Time (MMT = UTC+6:30, no DST) for SET live-fetch windows.

import 'bangkok_market.dart';

/// Wall-clock as in Myanmar (Yangon), independent of device timezone.
DateTime myanmarWallClockNow() {
  final utc = DateTime.now().toUtc();
  const offsetMs = (6 * 60 + 30) * 60 * 1000;
  return DateTime.fromMillisecondsSinceEpoch(
    utc.millisecondsSinceEpoch + offsetMs,
    isUtc: true,
  );
}

/// Thai SET trades **Mon–Fri on Bangkok’s calendar** (holiday-free approximation).
bool _isThaiSetTradingDayNow() {
  return isBangkokTradingWeekday(bangkokWallClockNow());
}

/// Exposed for Home UI (e.g. show `--` on 12:01 card before 09:30).
bool isThaiSetTradingDayToday() => _isThaiSetTradingDayNow();

int _mmtMinutesSinceMidnight(DateTime mWall) {
  return mWall.hour * 60 + mWall.minute;
}

/// Thai SET cash-style sessions, wall times in **Myanmar (MMT)**:
/// - Morning: **09:30–12:01** inclusive.
/// - Afternoon: **14:00 ≤ t < 16:30** (start at 2:00 PM, stop when 4:30 starts).
///
/// Only when Bangkok weekday is Mon–Fri (SET open days).
bool isMyanmarSetLiveFetchWindow([DateTime? myanmarWall]) {
  if (!_isThaiSetTradingDayNow()) return false;

  final m = myanmarWall ?? myanmarWallClockNow();
  final t = _mmtMinutesSinceMidnight(m);
  const morningStart = 9 * 60 + 30;
  /// Stop morning poll/animation when the clock reaches **12:01** (exclude 12:01 minute).
  const morningEndExclusive = 12 * 60 + 1;
  const afternoonStart = 14 * 60;
  const afternoonEndExclusive = 16 * 60 + 30;

  final morning = t >= morningStart && t < morningEndExclusive;
  final afternoon = t >= afternoonStart && t < afternoonEndExclusive;
  return morning || afternoon;
}

/// 12:01 card + green hero: show `--` from midnight until **09:30** (SET weekday only).
bool myanmarShowDash121UntilMorningOpen([DateTime? myanmarWall]) {
  if (!_isThaiSetTradingDayNow()) return false;
  final m = myanmarWall ?? myanmarWallClockNow();
  final t = _mmtMinutesSinceMidnight(m);
  return t < 9 * 60 + 30;
}

/// SET/Value/2D **animation** on 12:01 card: **09:30 ≤ t < 12:01** (stops when 12:01 starts).
bool myanmarMorning121QuoteAnimationWindow([DateTime? myanmarWall]) {
  if (!_isThaiSetTradingDayNow()) return false;
  final m = myanmarWall ?? myanmarWallClockNow();
  final t = _mmtMinutesSinceMidnight(m);
  const start = 9 * 60 + 30;
  const endExclusive = 12 * 60 + 1;
  return t >= start && t < endExclusive;
}

/// @deprecated Use [myanmarMorning121QuoteAnimationWindow] (same semantics).
bool myanmarMorning121BlinkWindow([DateTime? myanmarWall]) =>
    myanmarMorning121QuoteAnimationWindow(myanmarWall);

/// 4:30 card SET/Value: show `--` until **14:00** (SET weekdays only).
bool myanmarShowDash430UntilAfternoonOpen([DateTime? myanmarWall]) {
  if (!_isThaiSetTradingDayNow()) return false;
  final m = myanmarWall ?? myanmarWallClockNow();
  final t = _mmtMinutesSinceMidnight(m);
  return t < 14 * 60;
}

/// Home UI: highlight/animate 4:30 card during **14:00 ≤ t < 16:30 MMT**.
bool myanmarAfternoon430BlinkWindow([DateTime? myanmarWall]) {
  if (!_isThaiSetTradingDayNow()) return false;
  final m = myanmarWall ?? myanmarWallClockNow();
  final t = _mmtMinutesSinceMidnight(m);
  const start = 14 * 60;
  const endExclusive = 16 * 60 + 30;
  return t >= start && t < endExclusive;
}

/// 4:30 card SET/Value animation window (same semantics as blink window).
bool myanmarAfternoon430QuoteAnimationWindow([DateTime? myanmarWall]) =>
    myanmarAfternoon430BlinkWindow(myanmarWall);

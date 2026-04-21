// Bangkok wall clock for SET / 2D scheduling (ICT = UTC+7, no DST).

/// Wall-clock components as if in Bangkok (for hour/minute/weekday rules).
DateTime bangkokWallClockNow() {
  final utc = DateTime.now().toUtc();
  return DateTime.fromMillisecondsSinceEpoch(
    utc.millisecondsSinceEpoch + 7 * 60 * 60 * 1000,
    isUtc: true,
  );
}

/// `YYYY-MM-DD` in Bangkok calendar (for `draw_date` in DB).
String bangkokTodayDateString() {
  final b = bangkokWallClockNow();
  return '${b.year}-${b.month.toString().padLeft(2, '0')}-${b.day.toString().padLeft(2, '0')}';
}

bool isBangkokTradingWeekday(DateTime bangkokWall) {
  final w = bangkokWall.weekday;
  return w >= DateTime.monday && w <= DateTime.friday;
}

/// Green number + 12:01 card blink: **09:30 ≤ t < 12:01** (Mon–Fri). Still at 12:01+.
bool bangkokMorning121BlinkWindow([DateTime? bangkokWall]) {
  final b = bangkokWall ?? bangkokWallClockNow();
  if (!isBangkokTradingWeekday(b)) return false;
  final m = b.hour * 60 + b.minute;
  return m >= 9 * 60 + 30 && m < 12 * 60 + 1;
}

/// Green number + 4:30 card blink: **14:00 ≤ t < 16:30** (Mon–Fri). Still at 16:30+.
bool bangkokAfternoon430BlinkWindow([DateTime? bangkokWall]) {
  final b = bangkokWall ?? bangkokWallClockNow();
  if (!isBangkokTradingWeekday(b)) return false;
  final m = b.hour * 60 + b.minute;
  return m >= 14 * 60 && m < 16 * 60 + 30;
}

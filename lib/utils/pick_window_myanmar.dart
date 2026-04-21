import 'package:timezone/timezone.dart' as tz;

/// Thai SET-style weekdays + optional holiday dates; Myanmar wall clock (Asia/Yangon).
///
/// Pick UI open:
/// - Mon–Fri, not in [thaiHolidayDatesYyyyMmDd]
/// - Morning: 06:00 ≤ t < 11:40 (closes 20 min before 12:01 draw)
/// - Afternoon: 13:00 ≤ t < 16:10 (closes 20 min before 16:30 draw)
bool isPickWindowOpenYangon(
  tz.Location yangon, {
  Set<String> thaiHolidayDatesYyyyMmDd = const {},
  DateTime? nowUtc,
}) {
  final t = nowUtc != null
      ? tz.TZDateTime.from(nowUtc.toUtc(), yangon)
      : tz.TZDateTime.now(yangon);

  final ymd =
      '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
  if (thaiHolidayDatesYyyyMmDd.contains(ymd)) {
    return false;
  }
  if (t.weekday == DateTime.saturday || t.weekday == DateTime.sunday) {
    return false;
  }

  final hm = t.hour * 60 + t.minute;
  final morning = hm >= 6 * 60 && hm < 11 * 60 + 40;
  final afternoon = hm >= 13 * 60 && hm < 16 * 60 + 10;
  return morning || afternoon;
}

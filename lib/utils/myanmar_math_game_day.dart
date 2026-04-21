import 'package:timezone/timezone.dart' as tz;

/// Myanmar (Asia/Yangon) "game day" for daily limits: **[01:00, next day 01:00)**.
/// Example: 00:30 Mon → still Sun's game day; 01:00 Mon → Mon's game day.
String myanmarMathGameDayKey(tz.Location yangon) {
  final now = tz.TZDateTime.now(yangon);
  final tz.TZDateTime anchor;
  if (now.hour < 1) {
    anchor = now.subtract(const Duration(days: 1));
  } else {
    anchor = now;
  }
  final y = anchor.year.toString().padLeft(4, '0');
  final m = anchor.month.toString().padLeft(2, '0');
  final d = anchor.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

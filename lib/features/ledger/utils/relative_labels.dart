import 'package:intl/intl.dart';

/// Returns "Today", "Yesterday", weekday name for recent days, or a formatted date.
///
/// Assumes [day] is a date-only value (year/month/day) OR at least in local time.
String relativeDayLabel(DateTime day, {DateTime? now}) {
  final n = (now ?? DateTime.now()).toLocal();
  final today = DateTime(n.year, n.month, n.day);

  final d = day.toLocal();
  final dateOnly = DateTime(d.year, d.month, d.day);

  final diffDays = dateOnly.difference(today).inDays;

  if (diffDays == 0) return 'Today';
  if (diffDays == -1) return 'Yesterday';
  if (diffDays == 1) {
    return 'Tomorrow'; // harmless if you ever allow future-dated
  }

  // Within the last 7 days (but not today/yesterday): show weekday
  if (diffDays < 0 && diffDays >= -6) {
    return DateFormat.EEEE().format(dateOnly); // Monday, Tuesday...
  }

  // Otherwise show a normal date
  return DateFormat.yMMMMd().format(dateOnly);
}

String relativeDateTimeLabel(DateTime dt, {DateTime? now}) {
  final d = dt.toLocal();
  final n = (now ?? DateTime.now()).toLocal();

  final day = DateTime(d.year, d.month, d.day);
  final rel = relativeDayLabel(day, now: n);

  final time = DateFormat.jm().format(d); // 3:42 PM
  return '$rel • $time';
}

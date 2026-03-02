class SubGroup {
  final List<dynamic> overdue;
  final List<dynamic> dueSoon;
  final List<dynamic> later;
  final List<dynamic> paused;

  SubGroup({
    required this.overdue,
    required this.dueSoon,
    required this.later,
    required this.paused,
  });
}

SubGroup groupSubs(List subs) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final soonCutoff = today.add(const Duration(days: 7));

  final overdue = <dynamic>[];
  final dueSoon = <dynamic>[];
  final later = <dynamic>[];
  final paused = <dynamic>[];

  for (final s in subs) {
    if (s.isActive != true) {
      paused.add(s);
      continue;
    }

    final dueDay = DateTime(s.nextDue.year, s.nextDue.month, s.nextDue.day);

    if (dueDay.isBefore(today)) {
      overdue.add(s);
    } else if (!dueDay.isAfter(soonCutoff)) {
      dueSoon.add(s);
    } else {
      later.add(s);
    }
  }

  int byDue(a, b) => a.nextDue.compareTo(b.nextDue);
  overdue.sort(byDue);
  dueSoon.sort(byDue);
  later.sort(byDue);
  paused.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  return SubGroup(
    overdue: overdue,
    dueSoon: dueSoon,
    later: later,
    paused: paused,
  );
}

double sumAmount(List subs) {
  return subs.fold<double>(0.0, (sum, s) => sum + (s.amount as double));
}

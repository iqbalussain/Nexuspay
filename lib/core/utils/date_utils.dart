/// Date helpers used across the domain layer. All dates in this codebase
/// are treated as calendar days (no time-of-day component) unless stated
/// otherwise; callers should normalize with [dateOnly] at the boundary
/// (repository/mapper layer) so domain logic never has to think about
/// time zones or time-of-day.
DateTime dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// True if [date] falls within [start]..[end] inclusive. A null [end]
/// means the range is open-ended (still effective).
bool isWithinInclusive(DateTime date, DateTime start, DateTime? end) {
  final d = dateOnly(date);
  final s = dateOnly(start);
  if (d.isBefore(s)) return false;
  if (end == null) return true;
  final e = dateOnly(end);
  return !d.isAfter(e);
}

/// True if two date ranges (each inclusive, [end] nullable = open-ended)
/// overlap on at least one day.
bool rangesOverlap(
  DateTime aStart,
  DateTime? aEnd,
  DateTime bStart,
  DateTime? bEnd,
) {
  final s1 = dateOnly(aStart);
  final e1 = aEnd == null ? null : dateOnly(aEnd);
  final s2 = dateOnly(bStart);
  final e2 = bEnd == null ? null : dateOnly(bEnd);

  final startsBeforeOtherEnds = e2 == null || !s1.isAfter(e2);
  final endsAfterOtherStarts = e1 == null || !e1.isBefore(s2);
  return startsBeforeOtherEnds && endsAfterOtherStarts;
}

int inclusiveDayCount(DateTime start, DateTime end) {
  final s = dateOnly(start);
  final e = dateOnly(end);
  return e.difference(s).inDays + 1;
}

bool isWeekend(DateTime date, Set<int> weekendWeekdays) =>
    weekendWeekdays.contains(date.weekday);

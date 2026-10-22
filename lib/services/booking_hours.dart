class ArrivalPreview {
  const ArrivalPreview({
    required this.ahead,
    required this.waitMinutes,
    required this.arriveBy,
    required this.finishBy,
    required this.finishMinutes,
  });

  final int ahead;
  final int waitMinutes;
  final String arriveBy;
  final String finishBy;
  final int finishMinutes;
}

class QueueBooking {
  const QueueBooking({required this.time, required this.duration, this.serviceName = ''});

  final String time;
  final int duration;
  final String serviceName;
}

int parseClock(String value) {
  final compact = value.toUpperCase().replaceAll('.', '').replaceAll(' ', '');
  final match = RegExp(r'^(\d{1,2})(?::(\d{2}))?(AM|PM)?$').firstMatch(compact);
  if (match == null) {
    throw FormatException('Time must look like 2:30 PM.');
  }
  var hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2) ?? '0');
  final period = match.group(3);
  if (period != null) {
    if (hour == 12) {
      hour = 0;
    }
    if (period == 'PM') {
      hour += 12;
    }
  }
  if (hour > 23 || minute > 59) {
    throw FormatException('Time must look like 2:30 PM.');
  }
  return hour * 60 + minute;
}

String formatClock(int minutes) {
  final wrapped = minutes % (24 * 60);
  final hour = wrapped ~/ 60;
  final minute = wrapped % 60;
  final period = hour < 12 ? 'AM' : 'PM';
  final display = hour % 12 == 0 ? 12 : hour % 12;
  return '$display:${minute.toString().padLeft(2, '0')} $period';
}

ArrivalPreview previewArrival({
  required List<QueueBooking> queue,
  required String requested,
  required int duration,
}) {
  final items = [
    for (final item in queue) (requested: parseClock(item.time), duration: item.duration),
  ]..sort((a, b) => a.requested.compareTo(b.requested));
  final occupied = <({int requested, int start, int end})>[];
  int? chair;
  for (final item in items) {
    final start = chair == null ? item.requested : (item.requested > chair ? item.requested : chair);
    final end = start + item.duration;
    occupied.add((requested: item.requested, start: start, end: end));
    chair = end;
  }
  final want = parseClock(requested);
  final ahead = occupied.where((item) => item.requested <= want).toList();
  var arrive = want;
  if (ahead.isNotEmpty) {
    final lastEnd = ahead.last.end;
    if (lastEnd > arrive) {
      arrive = lastEnd;
    }
  }
  return ArrivalPreview(
    ahead: ahead.length,
    waitMinutes: arrive - want < 0 ? 0 : arrive - want,
    arriveBy: formatClock(arrive),
    finishBy: formatClock(arrive + duration),
    finishMinutes: arrive + duration,
  );
}

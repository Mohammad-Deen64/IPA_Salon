import 'package:dr_salon_app/services/booking_hours.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses shop times and queue wait', () {
    expect(parseClock('2:30 PM'), 14 * 60 + 30);
    expect(formatClock(9 * 60), '9:00 AM');
    final preview = previewArrival(
      queue: const [QueueBooking(time: '2:00 PM', duration: 45)],
      requested: '2:15 PM',
      duration: 30,
    );
    expect(preview.ahead, 1);
    expect(preview.waitMinutes, 30);
    expect(preview.arriveBy, '2:45 PM');
  });
}

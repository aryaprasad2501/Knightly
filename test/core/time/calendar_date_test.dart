import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/time/calendar_date.dart';

void main() {
  group('CalendarDate', () {
    test('round-trips through storage text', () {
      final date = CalendarDate(2026, 3, 9);
      expect(date.toStorage(), '2026-03-09');
      expect(CalendarDate.parse('2026-03-09'), date);
    });

    test('rejects malformed or impossible dates', () {
      expect(() => CalendarDate.parse('2026-3-9'), throwsFormatException);
      expect(() => CalendarDate.parse('2026-02-30'), throwsFormatException);
      expect(() => CalendarDate.parse('tomorrow'), throwsFormatException);
    });

    test('day arithmetic crosses months, years and DST boundaries', () {
      expect(CalendarDate(2026, 12, 31).addDays(1), CalendarDate(2027, 1, 1));
      expect(CalendarDate(2026, 3, 1).addDays(-1), CalendarDate(2026, 2, 28));
      // 29 March 2026 is a European DST change; day maths must not drift.
      expect(CalendarDate(2026, 3, 28).addDays(2), CalendarDate(2026, 3, 30));
      expect(CalendarDate(2026, 11, 25).daysUntil(CalendarDate(2026, 12, 2)), 7);
    });

    test('weekday, ordering and month lengths', () {
      expect(CalendarDate(2026, 11, 25).weekday, DateTime.wednesday);
      expect(CalendarDate(2026, 1, 1).isBefore(CalendarDate(2026, 1, 2)), isTrue);
      expect(CalendarDate.daysInMonth(2028, 2), 29);
      expect(CalendarDate.daysInMonth(2026, 2), 28);
      expect(CalendarDate.of(DateTime(2026, 11, 25, 23, 59)), CalendarDate(2026, 11, 25));
    });
  });

  test('ClockTime formats and converts minutes', () {
    expect(const ClockTime(7, 5).format(), '07:05');
    expect(ClockTime.fromMinutes(18 * 60 + 30), const ClockTime(18, 30));
    expect(const ClockTime(9, 0).compareTo(const ClockTime(8, 59)), greaterThan(0));
  });
}

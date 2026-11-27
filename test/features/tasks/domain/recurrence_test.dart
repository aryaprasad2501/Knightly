import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/time/calendar_date.dart';
import 'package:knightly/features/tasks/domain/recurrence.dart';

CalendarDate d(int y, int m, int day) => CalendarDate(y, m, day);

void main() {
  group('nextAfter', () {
    test('daily with interval', () {
      expect(DailyRecurrence().nextAfter(d(2026, 11, 30)), d(2026, 12, 1));
      expect(DailyRecurrence(3).nextAfter(d(2026, 11, 30)), d(2026, 12, 3));
    });

    test('weekly picks the next listed weekday', () {
      final mwf = WeeklyRecurrence({1, 3, 5});
      expect(mwf.nextAfter(d(2026, 11, 25)), d(2026, 11, 27)); // Wed -> Fri
      expect(mwf.nextAfter(d(2026, 11, 27)), d(2026, 11, 30)); // Fri -> Mon
      expect(WeeklyRecurrence.weekdays().nextAfter(d(2026, 11, 28)), d(2026, 11, 30)); // Sat -> Mon
      expect(WeeklyRecurrence({3}).nextAfter(d(2026, 11, 25)), d(2026, 12, 2)); // a full week
    });

    test('monthly clamps to short months and keeps its day afterwards', () {
      final on31 = MonthlyRecurrence(31);
      expect(on31.nextAfter(d(2026, 1, 31)), d(2026, 2, 28));
      expect(on31.nextAfter(d(2026, 2, 28)), d(2026, 3, 31));
      expect(MonthlyRecurrence(15).nextAfter(d(2026, 1, 10)), d(2026, 1, 15));
      expect(MonthlyRecurrence(15).nextAfter(d(2026, 12, 15)), d(2027, 1, 15));
    });
  });

  group('nextOccurrence', () {
    test('completing on time schedules the next one', () {
      expect(DailyRecurrence().nextOccurrence(due: d(2026, 11, 25), today: d(2026, 11, 25)), d(2026, 11, 26));
    });

    test('completing late never schedules into the past', () {
      expect(DailyRecurrence().nextOccurrence(due: d(2026, 11, 20), today: d(2026, 11, 25)), d(2026, 11, 26));
      expect(
        WeeklyRecurrence({1}).nextOccurrence(due: d(2026, 11, 16), today: d(2026, 11, 25)),
        d(2026, 11, 30),
      );
    });

    test('completing early keeps the cadence from the due date', () {
      expect(
        WeeklyRecurrence({5}).nextOccurrence(due: d(2026, 11, 27), today: d(2026, 11, 25)),
        d(2026, 12, 4),
      );
    });
  });

  group('encoding', () {
    test('round-trips every kind', () {
      for (final r in [
        DailyRecurrence(2),
        WeeklyRecurrence({5, 1, 3}),
        MonthlyRecurrence(31),
      ]) {
        expect(Recurrence.decode(r.encode()), r);
      }
      expect(WeeklyRecurrence({5, 1, 3}).encode(), 'weekly:1,3,5');
    });

    test('empty is no recurrence; junk is an error', () {
      expect(Recurrence.decode(null), isNull);
      expect(Recurrence.decode(''), isNull);
      expect(() => Recurrence.decode('yearly:1'), throwsFormatException);
      expect(() => Recurrence.decode('daily'), throwsFormatException);
    });

    test('invalid rules are rejected at construction', () {
      expect(() => DailyRecurrence(0), throwsArgumentError);
      expect(() => WeeklyRecurrence({}), throwsArgumentError);
      expect(() => WeeklyRecurrence({8}), throwsArgumentError);
      expect(() => MonthlyRecurrence(32), throwsArgumentError);
    });
  });

  test('describe', () {
    expect(DailyRecurrence().describe(), 'Every day');
    expect(WeeklyRecurrence.weekdays().describe(), 'Every weekday');
    expect(WeeklyRecurrence({2}).describe(), 'Every Tue');
    expect(WeeklyRecurrence({1, 4}).describe(), 'Mon, Thu');
    expect(MonthlyRecurrence(22).describe(), 'Monthly on the 22nd');
    expect(MonthlyRecurrence(11).describe(), 'Monthly on the 11th');
  });

  group('yearly', () {
    test('comes back on the same day each year, and round-trips', () {
      final r = YearlyRecurrence(3, 14);
      expect(r.nextAfter(CalendarDate(2026, 1, 1)), CalendarDate(2026, 3, 14));
      expect(r.nextAfter(CalendarDate(2026, 3, 14)), CalendarDate(2027, 3, 14));
      expect(Recurrence.decode(r.encode()), r);
      expect(r.encode(), 'yearly:03-14');
      expect(r.describe(), 'Every year on 14 Mar');
    });

    test('29 February falls on the 28th in other years and back on the 29th in leap years', () {
      final r = YearlyRecurrence(2, 29);
      expect(r.nextAfter(CalendarDate(2028, 2, 29)), CalendarDate(2029, 2, 28));
      expect(r.nextAfter(CalendarDate(2031, 3, 1)), CalendarDate(2032, 2, 29));
    });

    test('impossible dates are refused', () {
      expect(() => YearlyRecurrence(2, 30), throwsArgumentError);
      expect(() => YearlyRecurrence(13, 1), throwsArgumentError);
    });
  });
}

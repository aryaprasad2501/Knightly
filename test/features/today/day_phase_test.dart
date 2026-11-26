import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/features/today/domain/day_phase.dart';

void main() {
  group('DayPhase.fromHour', () {
    test('maps boundary hours', () {
      expect(DayPhase.fromHour(4), DayPhase.night);
      expect(DayPhase.fromHour(5), DayPhase.morning);
      expect(DayPhase.fromHour(11), DayPhase.morning);
      expect(DayPhase.fromHour(12), DayPhase.afternoon);
      expect(DayPhase.fromHour(17), DayPhase.evening);
      expect(DayPhase.fromHour(21), DayPhase.evening);
      expect(DayPhase.fromHour(22), DayPhase.night);
      expect(DayPhase.fromHour(0), DayPhase.night);
    });
  });

  test('formatLongDate', () {
    expect(formatLongDate(DateTime(2026, 11, 25)), 'Wednesday, 25 November');
  });
}

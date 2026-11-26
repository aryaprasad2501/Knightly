import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/database/app_database.dart';
import 'package:knightly/core/time/calendar_date.dart';
import 'package:knightly/features/water/data/water_repository.dart';
import 'package:knightly/features/water/domain/water.dart';

void main() {
  final today = CalendarDate(2026, 11, 26);

  test('amounts read naturally', () {
    expect(
      [formatMl(250), formatMl(1000), formatMl(1250), formatMl(1500), formatMl(2000), formatMl(1330)],
      ['250 ml', '1 L', '1.25 L', '1.5 L', '2 L', '1.33 L'],
    );
  });

  test('a week of days totals each day against the goal, today last', () {
    WaterLog log(CalendarDate d, int ml) =>
        WaterLog(id: 0, uuid: '', date: d, loggedAt: d.startOfDay, amountMl: ml);
    final days = WaterDay.range(
      [log(today, 500), log(today, 1000), log(today.addDays(-2), 2500), log(today.addDays(-9), 900)],
      today,
      7,
      2000,
    );
    expect(days, hasLength(7));
    expect(days.last.date, today);
    expect((days.last.totalMl, days.last.progress, days.last.reachedGoal), (1500, 0.75, false));
    expect((days[4].totalMl, days[4].progress, days[4].reachedGoal), (2500, 1.0, true));
    expect(days.first.totalMl, 0);
  });

  group('repository', () {
    late AppDatabase db;
    late WaterRepository repo;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = WaterRepository(db, clock: () => DateTime(2026, 11, 26, 9, 15));
    });
    tearDown(() => db.close());

    test('logs, removes and puts back an entry exactly', () async {
      final id = await repo.add(250);
      await repo.add(500);
      var logs = await repo.watchLogs(since: today).first;
      expect([for (final l in logs) (l.amountMl, l.date)], [(250, today), (500, today)]);

      final removed = (await repo.remove(id))!;
      logs = await repo.watchLogs(since: today).first;
      expect(logs.single.amountMl, 500);

      await repo.putBack(removed);
      logs = await repo.watchLogs(since: today).first;
      expect(
        [for (final l in logs) (l.id, l.uuid, l.amountMl)],
        [(id, removed.uuid, 250), (logs.last.id, logs.last.uuid, 500)],
      );
    });

    test('impossible amounts are refused', () {
      expect(() => repo.add(0), throwsArgumentError);
      expect(() => repo.add(6000), throwsArgumentError);
    });
  });
}

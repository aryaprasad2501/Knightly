import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/app/home_widget_sync.dart';
import 'package:knightly/core/database/database_provider.dart';
import 'package:knightly/core/time/calendar_date.dart';
import 'package:knightly/core/time/clock.dart';
import 'package:knightly/features/calendar/data/event_repository.dart';
import 'package:knightly/features/calendar/domain/calendar_event.dart';
import 'package:knightly/features/tasks/data/task_repository.dart';
import 'package:knightly/features/tasks/domain/task.dart';
import 'package:knightly/features/settings/application/display_controllers.dart';
import 'package:knightly/features/water/data/water_repository.dart';

import '../helpers/pump_app.dart';

void main() {
  final now = DateTime(2026, 11, 28, 9);
  final today = CalendarDate.of(now);

  test('each module widget gets its own lines from real data', () async {
    final db = testDatabase();
    addTearDown(db.close);
    await TaskRepository(db, clock: () => now).create(TaskDraft(title: 'Pay rent', dueDate: today));
    await WaterRepository(db, clock: () => now).add(500);
    await EventRepository(db, clock: () => now).create(
      EventDraft(title: 'Dentist', startDate: today, startTime: const ClockTime(15, 30), durationMinutes: 30),
    );

    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db), clockProvider.overrideWithValue(() => now)],
    );
    addTearDown(container.dispose);
    container.listen(todayWidgetDataProvider, (_, _) {});
    TodayWidgetData data() => container.read(todayWidgetDataProvider);
    for (
      var i = 0;
      i < 50 && (data().modules['mission']?.value == '—' || data().modules['water']?.value == '—');
      i++
    ) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }

    final m = data().modules;
    expect(m['mission'], (title: 'MISSIONS', value: '0/1', detail: 'Pay rent'));
    expect(m['water']!.value, contains('500'));
    expect(m['event'], (title: 'NEXT EVENT', value: '15:30', detail: 'Dentist'));
    expect(m['habits']!.title, 'HABITS');

    // The Today widget's lower lines: water and next mission by default …
    expect(data().water, contains('500'));
    expect(data().next, 'Next: Pay rent');
    // … or what the person picks.
    await container
        .read(widgetLinesProvider.notifier)
        .set(first: WidgetLine.nextEvent, second: WidgetLine.none);
    expect(data().water, '15:30 Dentist');
    expect(data().next, '');
    container.invalidate(widgetLinesProvider);
    await container.read(widgetLinesProvider.future);
    expect(container.read(widgetLinesProvider).value, (WidgetLine.nextEvent, WidgetLine.none));
  });
}

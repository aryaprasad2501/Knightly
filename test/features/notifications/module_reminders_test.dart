import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/time/calendar_date.dart';
import 'package:knightly/features/notifications/domain/module_reminders.dart';
import 'package:knightly/features/notifications/domain/reminder_plan.dart';
import 'package:knightly/features/tasks/domain/task.dart';

final now = DateTime(2026, 11, 28, 10); // 10:00
final today = CalendarDate.of(now);

void main() {
  test('settings round-trip; missions on by default; bad values ignored', () {
    expect(ModuleReminders.parse(null).missionLead, 0);
    const r = ModuleReminders(
      missionLead: 10,
      water: WaterNudge(everyMinutes: 120, from: ClockTime(9, 0), to: ClockTime(21, 0)),
      windDown: ClockTime(22, 30),
      habitsAt: ClockTime(20, 0),
    );
    expect(ModuleReminders.parse(r.encode()), r);
    final off = ModuleReminders.parse('m=off;w=10,900,100;s=x;h=off');
    expect((off.missionLead, off.water, off.windDown, off.habitsAt), (null, null, null, null));
    expect(r.water!.times.length, 7);
  });

  List<PlannedReminder> plan(ModuleReminders m, {int water = 0, int habitsLeft = 0}) => planReminders(
    now: now,
    formatTime: (t) => t.format(),
    modules: m,
    missions: [
      Task(id: 1, title: 'Call mum', createdAt: now, dueDate: today, dueTime: const ClockTime(18, 0)),
      Task(id: 2, title: 'Earlier', createdAt: now, dueDate: today, dueTime: const ClockTime(8, 0)),
      Task(id: 3, title: 'No time', createdAt: now, dueDate: today),
    ],
    waterTodayMl: water,
    waterGoalMl: 2000,
    habitsLeftToday: habitsLeft,
  );

  test('timed missions remind at or before their time, only ahead', () {
    final p = plan(const ModuleReminders(missionLead: 30));
    final m = p.where((r) => r.payload.startsWith('mission:')).toList();
    expect(m.length, 1);
    expect(m.single.title, 'Call mum');
    expect((m.single.at.hour, m.single.at.minute), (17, 30));
  });

  test('water nudges stop once today\'s goal is met', () {
    const w = ModuleReminders(
      missionLead: null,
      water: WaterNudge(everyMinutes: 180, from: ClockTime(9, 0), to: ClockTime(21, 0)),
    );
    final short = plan(w, water: 500).where((r) => r.payload == 'water' && r.at.day == now.day).toList();
    expect([for (final r in short) r.at.hour], [12, 15, 18, 21]);
    expect(short.first.body, '500 ml of 2 L so far');
    final met = plan(w, water: 2100).where((r) => r.payload == 'water' && r.at.day == now.day);
    expect(met, isEmpty);
  });

  test('wind-down every evening; habits only while some are left', () {
    const s = ModuleReminders(missionLead: null, windDown: ClockTime(22, 30), habitsAt: ClockTime(20, 0));
    expect(plan(s).where((r) => r.payload == 'sleep').length, 7);
    expect(plan(s).where((r) => r.payload == 'habits'), isEmpty);
    final h = plan(s, habitsLeft: 2).where((r) => r.payload == 'habits').toList();
    expect(h.single.title, '2 habits left today');
  });
}

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'calendar_date.dart';

typedef Clock = DateTime Function();

/// The current time. Override in tests to freeze or move time.
final clockProvider = Provider<Clock>((ref) => DateTime.now);

/// Today's local date. Rolls over by itself at midnight so screens left open
/// overnight move to the new day.
class TodayNotifier extends Notifier<CalendarDate> {
  Timer? _timer;

  @override
  CalendarDate build() {
    final now = ref.watch(clockProvider)();
    _timer?.cancel();
    final untilMidnight = CalendarDate.of(now).addDays(1).startOfDay.difference(now);
    _timer = Timer(untilMidnight + const Duration(seconds: 1), ref.invalidateSelf);
    ref.onDispose(() => _timer?.cancel());
    return CalendarDate.of(now);
  }
}

final todayProvider = NotifierProvider<TodayNotifier, CalendarDate>(TodayNotifier.new);

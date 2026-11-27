import '../../../core/time/calendar_date.dart';

/// Where a job belongs.
enum CareArea {
  home('Home'),
  garden('Garden'),
  pets('Pets');

  const CareArea(this.label);

  final String label;

  int get storageValue => index;

  static CareArea fromStorage(int value) => values[value.clamp(0, values.length - 1)];
}

/// Units for [EveryInterval].
enum CareUnit {
  days('day', 'days'),
  weeks('week', 'weeks'),
  months('month', 'months');

  const CareUnit(this.singular, this.plural);

  final String singular;
  final String plural;
}

const _weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// [date] moved by [months] calendar months, keeping the day where the month
/// allows it (31 Jan + 1 month = 28 or 29 Feb).
CalendarDate addMonths(CalendarDate date, int months) {
  final index = date.year * 12 + (date.month - 1) + months;
  final year = index ~/ 12;
  final month = index % 12 + 1;
  final day = date.day.clamp(1, CalendarDate.daysInMonth(year, month));
  return CalendarDate(year, month, day);
}

/// How often a job comes round. Stored as compact text via [encode] /
/// [CareSchedule.decode].
sealed class CareSchedule {
  const CareSchedule();

  /// The first due day on or after [date].
  CalendarDate firstOnOrAfter(CalendarDate date);

  /// When the job is due next after it was done (or skipped) on [done],
  /// for the turn that was due on [due].
  CalendarDate nextAfter({required CalendarDate done, required CalendarDate due});

  String encode();

  /// "Every 3 days", "Sat", "Monthly on the 1st".
  String describe();

  static CareSchedule decode(String value) {
    final parts = value.split(':');
    if (parts.length == 3 && parts[0] == 'every') {
      final unit = CareUnit.values.where((u) => u.name == parts[2]).firstOrNull;
      final n = int.tryParse(parts[1]);
      if (unit != null && n != null) return EveryInterval(n, unit);
    }
    if (parts.length == 2 && parts[0] == 'days') {
      return OnWeekdays(parts[1].split(',').map(int.parse).toSet());
    }
    if (parts.length == 2 && parts[0] == 'monthday') return MonthlyOn(int.parse(parts[1]));
    throw FormatException('Unknown care schedule', value);
  }
}

/// Every [count] [unit]s, counted from when it was last done: watering every
/// 3 days stays 3 days apart even when one turn was late.
final class EveryInterval extends CareSchedule {
  EveryInterval(this.count, this.unit) {
    if (count < 1 || count > maxCount) throw ArgumentError.value(count, 'count', 'must be 1..$maxCount');
  }

  static const maxCount = 365;

  final int count;
  final CareUnit unit;

  CalendarDate after(CalendarDate date) => switch (unit) {
    CareUnit.days => date.addDays(count),
    CareUnit.weeks => date.addDays(count * 7),
    CareUnit.months => addMonths(date, count),
  };

  @override
  CalendarDate firstOnOrAfter(CalendarDate date) => date;

  @override
  CalendarDate nextAfter({required CalendarDate done, required CalendarDate due}) => after(done);

  @override
  String encode() => 'every:$count:${unit.name}';

  @override
  String describe() {
    if (count == 1) {
      return switch (unit) {
        CareUnit.days => 'Every day',
        CareUnit.weeks => 'Every week',
        CareUnit.months => 'Every month',
      };
    }
    return 'Every $count ${unit.plural}';
  }

  @override
  bool operator ==(Object other) => other is EveryInterval && other.encode() == encode();

  @override
  int get hashCode => encode().hashCode;
}

/// On fixed weekdays (1 = Monday … 7 = Sunday), e.g. bins out on Thursday.
final class OnWeekdays extends CareSchedule {
  OnWeekdays(Set<int> weekdays) : weekdays = Set.unmodifiable(weekdays) {
    if (weekdays.isEmpty || weekdays.any((d) => d < 1 || d > 7)) {
      throw ArgumentError.value(weekdays, 'weekdays', 'must be a non-empty subset of 1..7');
    }
  }

  final Set<int> weekdays;

  @override
  CalendarDate firstOnOrAfter(CalendarDate date) {
    var d = date;
    while (!weekdays.contains(d.weekday)) {
      d = d.addDays(1);
    }
    return d;
  }

  /// The next turn after the one just covered: done early on Friday for
  /// Sunday's turn moves on to the Sunday after.
  @override
  CalendarDate nextAfter({required CalendarDate done, required CalendarDate due}) =>
      firstOnOrAfter((done.isAfter(due) ? done : due).addDays(1));

  @override
  String encode() => 'days:${(weekdays.toList()..sort()).join(',')}';

  @override
  String describe() {
    final sorted = weekdays.toList()..sort();
    if (sorted.length == 7) return 'Every day';
    if (sorted.join() == '12345') return 'Weekdays';
    if (sorted.join() == '67') return 'Weekends';
    final names = sorted.map((d) => _weekdayNames[d - 1]).join(', ');
    return sorted.length == 1 ? 'Every $names' : names;
  }

  @override
  bool operator ==(Object other) => other is OnWeekdays && other.encode() == encode();

  @override
  int get hashCode => encode().hashCode;
}

/// Once a month on [day] (the last day in shorter months).
final class MonthlyOn extends CareSchedule {
  MonthlyOn(this.day) {
    if (day < 1 || day > 31) throw ArgumentError.value(day, 'day', 'must be 1..31');
  }

  final int day;

  CalendarDate _in(int year, int month) =>
      CalendarDate(year, month, day.clamp(1, CalendarDate.daysInMonth(year, month)));

  @override
  CalendarDate firstOnOrAfter(CalendarDate date) {
    final here = _in(date.year, date.month);
    if (!here.isBefore(date)) return here;
    final next = addMonths(CalendarDate(date.year, date.month, 1), 1);
    return _in(next.year, next.month);
  }

  @override
  CalendarDate nextAfter({required CalendarDate done, required CalendarDate due}) =>
      firstOnOrAfter((done.isAfter(due) ? done : due).addDays(1));

  @override
  String encode() => 'monthday:$day';

  @override
  String describe() => 'Monthly on the ${ordinal(day)}';

  @override
  bool operator ==(Object other) => other is MonthlyOn && other.day == day;

  @override
  int get hashCode => Object.hash('monthday', day);
}

/// 1st, 2nd, 3rd, 4th … 21st, 22nd …
String ordinal(int n) {
  final suffix = n % 100 >= 11 && n % 100 <= 13
      ? 'th'
      : switch (n % 10) {
          1 => 'st',
          2 => 'nd',
          3 => 'rd',
          _ => 'th',
        };
  return '$n$suffix';
}

/// One turn of a job: done (or skipped) on [date], for the turn due on [due].
class CareLog {
  const CareLog({
    required this.id,
    required this.uuid,
    required this.jobId,
    required this.date,
    required this.due,
    required this.loggedAt,
    this.skipped = false,
    this.note,
  });

  final int id;
  final String uuid;
  final int jobId;
  final CalendarDate date;
  final CalendarDate due;
  final DateTime loggedAt;
  final bool skipped;
  final String? note;

  /// Days late (positive), early (negative) or 0.
  int get daysLate => due.daysUntil(date);
}

/// A recurring job: water the plants, change the aquarium water, deworm the dog.
class CareJob {
  const CareJob({
    required this.id,
    required this.uuid,
    required this.name,
    required this.area,
    required this.schedule,
    required this.startDate,
    required this.createdAt,
    this.subject,
    this.notes,
    this.deletedAt,
  });

  final int id;
  final String uuid;
  final String name;
  final CareArea area;

  /// Which plant, pet, room or appliance, e.g. "Money plant", "Bruno", "Fish tank".
  final String? subject;
  final CareSchedule schedule;

  /// When the first turn is due (on or after it, for fixed days).
  final CalendarDate startDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  /// "Water · Money plant" or just the name.
  String get title => subject == null ? name : '$name · $subject';
}

/// A job with its history and where it stands today.
class CareJobState {
  CareJobState(this.job, Iterable<CareLog> logs, {required this.today})
    : logs = List.unmodifiable(
        logs.toList()..sort((a, b) {
          final byDate = b.date.compareTo(a.date);
          return byDate != 0 ? byDate : b.loggedAt.compareTo(a.loggedAt);
        }),
      );

  final CareJob job;

  /// Newest first.
  final List<CareLog> logs;
  final CalendarDate today;

  CareLog? get last => logs.firstOrNull;

  /// The last turn actually done (not skipped).
  CareLog? get lastDone => logs.where((l) => !l.skipped).firstOrNull;

  CalendarDate get nextDue {
    final l = last;
    if (l == null) return job.schedule.firstOnOrAfter(job.startDate);
    return job.schedule.nextAfter(done: l.date, due: l.due);
  }

  /// Days until due: negative when overdue.
  int get daysUntilDue => today.daysUntil(nextDue);

  CareStatus get status {
    final d = daysUntilDue;
    if (d < 0) return CareStatus.overdue;
    if (d == 0) return CareStatus.today;
    if (d <= 7) return CareStatus.thisWeek;
    return CareStatus.later;
  }

  /// Whether the job needs doing today (due or overdue).
  bool get isDue => daysUntilDue <= 0;

  int get timesDone => logs.where((l) => !l.skipped).length;
  int get timesSkipped => logs.where((l) => l.skipped).length;

  /// Share of done turns finished on or before their due day; null before any.
  double? get onTimeRate {
    final done = logs.where((l) => !l.skipped).toList();
    if (done.isEmpty) return null;
    return done.where((l) => l.daysLate <= 0).length / done.length;
  }
}

/// Where a job stands today.
enum CareStatus {
  overdue('Overdue'),
  today('Due today'),
  thisWeek('This week'),
  later('Later');

  const CareStatus(this.label);

  final String label;
}

/// "Due today", "Due tomorrow", "3 days overdue", "In 5 days".
String describeDue(int daysUntil) => switch (daysUntil) {
  0 => 'Due today',
  1 => 'Due tomorrow',
  -1 => '1 day overdue',
  < -1 => '${-daysUntil} days overdue',
  _ => 'In $daysUntil days',
};

/// Jobs that need doing on [date], assuming nothing more is done before it
/// (overdue jobs stay due). Sorted most overdue first.
List<CareJobState> dueOn(Iterable<CareJobState> jobs, CalendarDate date) =>
    [
      for (final j in jobs)
        if (!j.nextDue.isAfter(date)) j,
    ]..sort((a, b) {
      final byDue = a.nextDue.compareTo(b.nextDue);
      return byDue != 0 ? byDue : a.job.name.toLowerCase().compareTo(b.job.name.toLowerCase());
    });

/// Today's overview of all jobs.
class CareSummary {
  const CareSummary({
    required this.overdue,
    required this.today,
    required this.thisWeek,
    required this.total,
  });

  factory CareSummary.of(Iterable<CareJobState> jobs) {
    var overdue = 0, today = 0, week = 0, total = 0;
    for (final j in jobs) {
      total++;
      switch (j.status) {
        case CareStatus.overdue:
          overdue++;
        case CareStatus.today:
          today++;
        case CareStatus.thisWeek:
          week++;
        case CareStatus.later:
          break;
      }
    }
    return CareSummary(overdue: overdue, today: today, thisWeek: week, total: total);
  }

  final int overdue;
  final int today;
  final int thisWeek;
  final int total;

  int get dueNow => overdue + today;
}

/// What a new or edited job will be. [validate] returns a user-facing problem.
class CareJobDraft {
  const CareJobDraft({
    required this.name,
    required this.area,
    required this.schedule,
    required this.startDate,
    this.subject,
    this.notes,
  });

  final String name;
  final CareArea area;
  final String? subject;
  final CareSchedule schedule;
  final CalendarDate startDate;
  final String? notes;

  static const maxName = 80;
  static const maxSubject = 40;
  static const maxNotes = 500;

  String? validate() {
    final n = name.trim();
    if (n.isEmpty) return 'Give the job a name.';
    if (n.length > maxName) return 'Keep the name under $maxName characters.';
    if ((subject?.trim().length ?? 0) > maxSubject) return 'Keep "for" under $maxSubject characters.';
    if ((notes?.trim().length ?? 0) > maxNotes) return 'Keep notes under $maxNotes characters.';
    return null;
  }

  String? get cleanSubject => subject == null || subject!.trim().isEmpty ? null : subject!.trim();
  String? get cleanNotes => notes == null || notes!.trim().isEmpty ? null : notes!.trim();
}

/// A ready-made job to start from when adding one.
class CarePreset {
  const CarePreset(this.name, this.area, this.schedule);

  final String name;
  final CareArea area;
  final CareSchedule Function() schedule;
}

/// Common jobs, as starting points only: the person picks one, then edits it.
final carePresets = <CarePreset>[
  CarePreset('Change bedsheets', CareArea.home, () => EveryInterval(1, CareUnit.weeks)),
  CarePreset('Clean the fridge', CareArea.home, () => EveryInterval(1, CareUnit.months)),
  CarePreset('Clean AC filters', CareArea.home, () => EveryInterval(1, CareUnit.months)),
  CarePreset('Water purifier service', CareArea.home, () => EveryInterval(6, CareUnit.months)),
  CarePreset('Clean the bathroom', CareArea.home, () => EveryInterval(1, CareUnit.weeks)),
  CarePreset('Descale the kettle', CareArea.home, () => EveryInterval(2, CareUnit.months)),
  CarePreset('Water the plants', CareArea.garden, () => EveryInterval(2, CareUnit.days)),
  CarePreset('Fertilise', CareArea.garden, () => EveryInterval(1, CareUnit.months)),
  CarePreset('Prune and deadhead', CareArea.garden, () => EveryInterval(2, CareUnit.weeks)),
  CarePreset('Mow the lawn', CareArea.garden, () => EveryInterval(1, CareUnit.weeks)),
  CarePreset('Aquarium water change', CareArea.pets, () => EveryInterval(1, CareUnit.weeks)),
  CarePreset('Clean aquarium filter', CareArea.pets, () => EveryInterval(1, CareUnit.months)),
  CarePreset('Bath the dog', CareArea.pets, () => EveryInterval(2, CareUnit.weeks)),
  CarePreset('Flea and tick treatment', CareArea.pets, () => EveryInterval(1, CareUnit.months)),
  CarePreset('Deworming', CareArea.pets, () => EveryInterval(3, CareUnit.months)),
  CarePreset('Vet check-up', CareArea.pets, () => EveryInterval(12, CareUnit.months)),
  CarePreset('Clean the litter box', CareArea.pets, () => EveryInterval(1, CareUnit.days)),
];

/// When Home care reminds you on days something is due: a list of times of
/// day (minutes since midnight). Each reminder lists what is still not done,
/// so a job you finish drops out of the later ones. Empty means off.
class CareReminderTimes {
  const CareReminderTimes(this.minutes);

  /// 9:00 in the morning and 19:00 after work.
  static const defaults = CareReminderTimes([9 * 60, 19 * 60]);
  static const maxTimes = 4;

  final List<int> minutes;

  bool get isOff => minutes.isEmpty;

  List<ClockTime> get times => [for (final m in minutes) ClockTime.fromMinutes(m)];

  /// "540,1140", or "off".
  String encode() => isOff ? 'off' : minutes.join(',');

  static CareReminderTimes parse(String? stored) {
    if (stored == null) return defaults;
    if (stored.trim() == 'off') return const CareReminderTimes([]);
    final values = <int>{};
    for (final part in stored.split(',')) {
      final m = int.tryParse(part.trim());
      if (m != null && m >= 0 && m < 24 * 60) values.add(m);
    }
    if (values.isEmpty) return defaults;
    return CareReminderTimes((values.toList()..sort()).take(maxTimes).toList());
  }

  CareReminderTimes withTime(int minute) =>
      CareReminderTimes(({...minutes, minute}.toList()..sort()).take(maxTimes).toList());

  CareReminderTimes without(int minute) => CareReminderTimes([
    for (final m in minutes)
      if (m != minute) m,
  ]);

  @override
  bool operator ==(Object other) => other is CareReminderTimes && other.encode() == encode();

  @override
  int get hashCode => encode().hashCode;
}

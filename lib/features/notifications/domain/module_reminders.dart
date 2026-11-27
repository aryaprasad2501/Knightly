import '../../../core/time/calendar_date.dart';

/// Water nudges: every [everyMinutes] between [from] and [to].
class WaterNudge {
  const WaterNudge({required this.everyMinutes, required this.from, required this.to});

  final int everyMinutes;
  final ClockTime from;
  final ClockTime to;

  static const choices = [60, 90, 120, 180, 240];

  /// The times of day the nudges fall on.
  List<ClockTime> get times => [
    for (var m = from.inMinutes; m <= to.inMinutes; m += everyMinutes) ClockTime.fromMinutes(m),
  ];

  @override
  bool operator ==(Object other) =>
      other is WaterNudge && other.everyMinutes == everyMinutes && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(everyMinutes, from, to);
}

/// Reminders for whole modules (not single records): timed missions, water,
/// a wind-down before bed and an evening habits check. One setting,
/// `reminders.modules`, e.g. `m=10;w=120,540,1260;s=1350;h=off`.
class ModuleReminders {
  const ModuleReminders({this.missionLead = 0, this.water, this.windDown, this.habitsAt});

  /// Minutes before a timed mission's time; null is off. On (at the time) by default.
  final int? missionLead;
  final WaterNudge? water;
  final ClockTime? windDown;
  final ClockTime? habitsAt;

  static const storageKey = 'reminders.modules';
  static const missionLeads = [0, 10, 30, 60];

  ModuleReminders copyWith({
    int? Function()? missionLead,
    WaterNudge? Function()? water,
    ClockTime? Function()? windDown,
    ClockTime? Function()? habitsAt,
  }) => ModuleReminders(
    missionLead: missionLead == null ? this.missionLead : missionLead(),
    water: water == null ? this.water : water(),
    windDown: windDown == null ? this.windDown : windDown(),
    habitsAt: habitsAt == null ? this.habitsAt : habitsAt(),
  );

  String encode() => [
    'm=${missionLead ?? 'off'}',
    'w=${water == null ? 'off' : '${water!.everyMinutes},${water!.from.inMinutes},${water!.to.inMinutes}'}',
    's=${windDown?.inMinutes ?? 'off'}',
    'h=${habitsAt?.inMinutes ?? 'off'}',
  ].join(';');

  static ModuleReminders parse(String? stored) {
    if (stored == null || stored.trim().isEmpty) return const ModuleReminders();
    final parts = <String, String>{
      for (final p in stored.split(';'))
        if (p.contains('=')) p.substring(0, p.indexOf('=')).trim(): p.substring(p.indexOf('=') + 1).trim(),
    };
    ClockTime? time(String? v) {
      final m = int.tryParse(v ?? '');
      return m == null || m < 0 || m >= 24 * 60 ? null : ClockTime.fromMinutes(m);
    }

    WaterNudge? water(String? v) {
      final n = (v ?? '').split(',').map(int.tryParse).toList();
      if (n.length != 3 || n.any((x) => x == null)) return null;
      final from = time('${n[1]}'), to = time('${n[2]}');
      if (from == null || to == null || n[0]! < 30 || to.inMinutes < from.inMinutes) return null;
      return WaterNudge(everyMinutes: n[0]!, from: from, to: to);
    }

    final lead = parts['m'];
    return ModuleReminders(
      missionLead: lead == null ? 0 : (lead == 'off' ? null : int.tryParse(lead)?.clamp(0, 240)),
      water: water(parts['w']),
      windDown: time(parts['s']),
      habitsAt: time(parts['h']),
    );
  }

  @override
  bool operator ==(Object other) => other is ModuleReminders && other.encode() == encode();

  @override
  int get hashCode => encode().hashCode;
}

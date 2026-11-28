/// The Knightly backup file: one JSON document holding every record.
///
/// ```json
/// {
///   "format": "knightly-backup",
///   "formatVersion": 1,
///   "schemaVersion": 4,
///   "createdAt": "2026-11-26T18:30:00.000Z",
///   "counts": {"settings": 2, "projects": 1, "tasks": 3, "habits": 2, "habitCheckIns": 40},
///   "checksum": "1a2b3c4d",
///   "data": {"settings": [...], "projects": [...], "tasks": [...], "habits": [...], "habitCheckIns": [...],
///            "events": [...], "eventExceptions": [...], "routines": [...], "routineSteps": [...],
///            "routineRuns": [...], "waterLogs": [...], "sleepLogs": [...],
///            "workouts": [...], "workoutSets": [...], "foods": [...], "mealEntries": [...],
///            "careJobs": [...], "careLogs": [...], "taskChecks": [...],
///            "workoutTemplates": [...]}
/// }
/// ```
///
/// `checksum` is the CRC-32 of `data` re-encoded compactly, so a file that was
/// truncated or edited is detected; reformatting (pretty-printing) is fine.
/// Records in the Recycle Bin are included, with their `deletedAt`.
library;

const backupFormatName = 'knightly-backup';

/// Bumped when the file layout itself changes; readers reject newer files.
const backupFormatVersion = 1;

/// The tables, in the order they are written and restored.
const backupTables = [
  'settings',
  'projects',
  'tasks',
  'habits',
  'habitCheckIns',
  'events',
  'eventExceptions',
  'routines',
  'routineSteps',
  'routineRuns',
  'waterLogs',
  'sleepLogs',
  'workouts',
  'workoutSets',
  'foods',
  'mealEntries',
  'careJobs',
  'careLogs',
  'taskChecks',
  'workoutTemplates',
];

/// Tables added after the first backup format; files made before them (an
/// older schema) simply don't have them and restore with them empty.
const backupTablesSince = {
  'events': 5,
  'eventExceptions': 5,
  'routines': 6,
  'routineSteps': 6,
  'routineRuns': 6,
  'waterLogs': 7,
  'sleepLogs': 8,
  'workouts': 9,
  'workoutSets': 9,
  'foods': 10,
  'mealEntries': 10,
  'careJobs': 11,
  'careLogs': 11,
  'taskChecks': 13,
  'workoutTemplates': 14,
};

/// Settings that describe this device rather than the user's data; they are
/// never exported and never overwritten by a restore.
const deviceOnlySettingPrefix = 'backup.';

/// What a valid backup file contains, shown before restoring it.
class BackupSummary {
  const BackupSummary({required this.createdAt, required this.schemaVersion, required this.counts});

  final DateTime createdAt;
  final int schemaVersion;

  /// Records per table (see [backupTables]).
  final Map<String, int> counts;

  int get missions => counts['tasks'] ?? 0;
  int get projects => counts['projects'] ?? 0;
  int get habits => counts['habits'] ?? 0;
  int get checkIns => counts['habitCheckIns'] ?? 0;
  int get events => counts['events'] ?? 0;
  int get routines => counts['routines'] ?? 0;
  int get waterLogs => counts['waterLogs'] ?? 0;
  int get sleepLogs => counts['sleepLogs'] ?? 0;
  int get workouts => counts['workouts'] ?? 0;
  int get mealEntries => counts['mealEntries'] ?? 0;
  int get foods => counts['foods'] ?? 0;
  int get careJobs => counts['careJobs'] ?? 0;
  int get careLogs => counts['careLogs'] ?? 0;
}

/// A backup that cannot be read or restored. [message] is user-facing and
/// says what is wrong and what to do.
class BackupException implements Exception {
  const BackupException(this.message);

  final String message;

  @override
  String toString() => 'BackupException: $message';
}

/// CRC-32 (IEEE 802.3) of [bytes], as 8 lowercase hex digits.
String crc32Hex(List<int> bytes) {
  var crc = 0xffffffff;
  for (final b in bytes) {
    crc = _crcTable[(crc ^ b) & 0xff] ^ (crc >>> 8);
  }
  return ((crc ^ 0xffffffff) & 0xffffffff).toRadixString(16).padLeft(8, '0');
}

final List<int> _crcTable = List<int>.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = (c & 1) != 0 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
  }
  return c;
}, growable: false);

/// "knightly-backup-2026-11-26-1830.json" for a backup made at [at].
String backupFileName(DateTime at, {String prefix = 'knightly-backup'}) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '$prefix-${at.year}-${two(at.month)}-${two(at.day)}-${two(at.hour)}${two(at.minute)}.json';
}

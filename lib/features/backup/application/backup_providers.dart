import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/document_files.dart';
import '../../settings/application/live_backdrop_controller.dart';
import '../../settings/application/theme_controller.dart';
import '../data/backup_service.dart';
import '../domain/backup_format.dart';

/// When this device last saved a backup, or null.
final lastBackupProvider = FutureProvider<DateTime?>(
  (ref) => ref.watch(backupServiceProvider).lastBackupAt(),
);

/// Safety copies of earlier data, newest first.
final safetyCopiesProvider = FutureProvider<List<SafetyCopy>>(
  (ref) => ref.watch(backupServiceProvider).safetyCopies(),
);

/// A backup file the user picked and that passed validation.
class CheckedBackup {
  const CheckedBackup({required this.json, required this.summary, this.fileName});

  final String json;
  final BackupSummary summary;
  final String? fileName;
}

/// Backup and restore as the screens use them.
class BackupActions {
  BackupActions(this._ref);

  final Ref _ref;

  BackupService get _service => _ref.read(backupServiceProvider);
  DocumentFiles get _files => _ref.read(documentFilesProvider);

  /// Exports everything and lets the user choose where to save it. Returns the
  /// saved file's name, or null if the user cancelled.
  Future<String?> createBackup(DateTime now) async {
    final json = await _service.exportJson();
    final saved = await _files.save(backupFileName(now), utf8.encode(json));
    if (saved == null) return null;
    await _service.markBackedUp();
    _ref.invalidate(lastBackupProvider);
    return saved;
  }

  /// Lets the user pick a backup file and validates it completely. Returns
  /// null if they cancelled; throws [BackupException] or [DocumentException]
  /// with a user-facing message when the file can't be used.
  Future<CheckedBackup?> pickBackup() async {
    final picked = await _files.open();
    if (picked == null) return null;
    final String json;
    try {
      json = utf8.decode(picked.bytes);
    } on FormatException {
      throw const BackupException("This file can't be read. It isn't a Knightly backup, or it is damaged.");
    }
    return CheckedBackup(json: json, summary: _service.validate(json), fileName: picked.name);
  }

  /// Replaces all data with [json] (after a safety copy) and reloads settings.
  Future<BackupSummary> restore(String json) async {
    final summary = await _service.restore(json);
    // Theme and Live backdrop are cached by their controllers; reload them.
    _ref.invalidate(themeControllerProvider);
    _ref.invalidate(liveBackdropControllerProvider);
    _ref.invalidate(safetyCopiesProvider);
    return summary;
  }

  /// Saves a safety copy of everything now (before cloud sync first merges).
  Future<void> saveSafetyCopy() async {
    await _service.saveSafetyCopy();
    _ref.invalidate(safetyCopiesProvider);
  }
}

final backupActionsProvider = Provider<BackupActions>(BackupActions.new);

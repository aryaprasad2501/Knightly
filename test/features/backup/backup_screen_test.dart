import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/design/components/k_button.dart';
import 'package:knightly/core/design/components/k_loading_indicator.dart';
import 'package:knightly/core/design/components/k_navigation_bar.dart';
import 'package:knightly/core/platform/document_files.dart';
import 'package:knightly/features/backup/data/backup_service.dart';
import 'package:knightly/features/tasks/data/task_repository.dart';
import 'package:knightly/features/tasks/domain/task.dart';

import '../../helpers/pump_app.dart';

final now = DateTime(2026, 11, 26, 18, 30);

/// Stands in for the system file picker.
class FakeDocumentFiles extends DocumentFiles {
  FakeDocumentFiles();

  Uint8List? saved;
  String? savedName;
  PickedDocument? toOpen;

  @override
  Future<String?> save(String name, Uint8List bytes, {String mimeType = 'application/json'}) async {
    saved = bytes;
    savedName = name;
    return name;
  }

  @override
  Future<PickedDocument?> open() async => toOpen;
}

Future<void> openBackupScreen(WidgetTester tester) async {
  await tester.tap(find.descendant(of: find.byType(KNavigationBar), matching: find.text('Settings')));
  await tester.pumpAndSettle();
  final row = find.text('Backup & restore');
  await tester.scrollUntilVisible(row, 250, scrollable: find.byType(Scrollable).hitTestable().first);
  await tester.pumpAndSettle();
  await tester.tap(row);
  await tester.pumpAndSettle();
}

/// Lets real file and database I/O finish (it runs outside the fake test
/// clock), waiting until no button shows its busy spinner, then settles.
Future<void> settleIo(WidgetTester tester) async {
  for (var i = 0; i < 60; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();
    if (i > 3 && find.byType(KLoadingIndicator).evaluate().isEmpty) break;
  }
  await tester.pumpAndSettle();
}

void main() {
  late Directory temp;
  setUp(() => temp = Directory.systemTemp.createTempSync('knightly_backup_ui'));
  tearDown(() {
    try {
      temp.deleteSync(recursive: true);
    } on FileSystemException {
      // Windows may still hold the folder for a moment; the OS cleans temp.
    }
  });

  testWidgets('create a backup, then restore another one after confirming', (tester) async {
    usePhoneViewport(tester);
    final files = FakeDocumentFiles();

    // A second "phone" whose backup will be restored.
    final other = testDatabase();
    final otherBackup = await tester.runAsync(() async {
      await TaskRepository(other, clock: () => now).create(const TaskDraft(title: 'From the backup'));
      return BackupService(other, clock: () => now, safetyDir: () async => temp).exportJson();
    });

    final db = testDatabase();
    final service = BackupService(
      db,
      clock: () => now,
      safetyDir: () async => Directory('${temp.path}/safety'),
    );
    await tester.runAsync(
      () => TaskRepository(db, clock: () => now).create(const TaskDraft(title: 'On this phone')),
    );
    await pumpKnightlyApp(
      tester,
      db: db,
      now: now,
      overrides: [
        documentFilesProvider.overrideWithValue(files),
        backupServiceProvider.overrideWithValue(service),
      ],
    );
    await openBackupScreen(tester);
    expect(find.text('No backup made on this phone yet.'), findsOneWidget);

    // Back up.
    await tester.tap(find.text('Create backup'));
    await settleIo(tester);
    expect(files.savedName, 'knightly-backup-2026-11-26-1830.json');
    expect(utf8.decode(files.saved!), contains('On this phone'));
    expect(find.text('Backup saved · knightly-backup-2026-11-26-1830.json'), findsOneWidget);
    expect(find.textContaining('Last backup:'), findsOneWidget);

    // Restore the other phone's backup: confirmation first, cancel keeps data.
    files.toOpen = PickedDocument(bytes: utf8.encode(otherBackup!), name: 'other.json');
    await tester.tap(find.text('Choose backup file'));
    await settleIo(tester);
    expect(find.text('Replace all your data?'), findsOneWidget);
    expect(find.textContaining('1 mission, 0 projects, 0 habits and 0 check-ins'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await settleIo(tester);

    await tester.tap(find.text('Choose backup file'));
    await settleIo(tester);
    await tester.tap(find.widgetWithText(KButton, 'Restore'));
    await settleIo(tester);
    expect(find.textContaining('Restored 1 mission'), findsOneWidget);
    // The safety-copy list reloads from disk (real I/O), below the fold.
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
    }
    await tester.scrollUntilVisible(
      find.text('SAFETY COPIES'),
      200,
      scrollable: find.byType(Scrollable).hitTestable().first,
    );
    expect(find.text('SAFETY COPIES'), findsOneWidget);
    expect(find.textContaining('1 mission, 0 projects'), findsWidgets); // the copy holds "On this phone"

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(KNavigationBar), matching: find.text('Tasks')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Anytime 1'));
    await tester.pumpAndSettle();
    expect(find.text('From the backup').hitTestable(), findsOneWidget);
    expect(find.text('On this phone').hitTestable(), findsNothing);
  });

  testWidgets('a damaged file is refused with a clear reason and nothing changes', (tester) async {
    usePhoneViewport(tester);
    final files = FakeDocumentFiles()
      ..toOpen = PickedDocument(bytes: Uint8List.fromList(utf8.encode('{"format": "knightly-backup"')));
    final db = testDatabase();
    await tester.runAsync(
      () => TaskRepository(db, clock: () => now).create(const TaskDraft(title: 'Still here')),
    );
    await pumpKnightlyApp(
      tester,
      db: db,
      now: now,
      overrides: [
        documentFilesProvider.overrideWithValue(files),
        backupServiceProvider.overrideWithValue(
          BackupService(db, clock: () => now, safetyDir: () async => Directory('${temp.path}/safety')),
        ),
      ],
    );
    await openBackupScreen(tester);

    await tester.tap(find.text('Choose backup file'));
    await settleIo(tester);
    expect(find.text('Not restored'), findsOneWidget);
    expect(find.textContaining("can't be read"), findsOneWidget);
    expect(find.text('Replace all your data?'), findsNothing);
  });
}

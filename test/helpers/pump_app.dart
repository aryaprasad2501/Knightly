import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/app/home_widget_sync.dart';
import 'package:knightly/features/settings/application/display_controllers.dart';
import 'package:knightly/core/design/motion/k_device_tilt.dart';
import 'package:knightly/core/design/components/k_navigation_bar.dart';
import 'package:knightly/features/settings/presentation/welcome_sheet.dart';
import 'package:knightly/app/knightly_app.dart';
import 'package:knightly/core/database/app_database.dart';
import 'package:knightly/core/database/database_provider.dart';
import 'package:knightly/core/design/ambient/k_ambient_scene.dart';
import 'package:knightly/core/design/brand/k_boot_sequence.dart';
import 'package:knightly/core/design/theme/knightly_theme.dart';
import 'package:knightly/core/design/theme/knightly_themes.dart';
import 'package:knightly/core/time/clock.dart';

/// Sizes the test view like a typical 390×844 dp Android phone.
void usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// Pumps [child] inside a themed app with a scaffold, for component tests.
Future<void> pumpThemed(
  WidgetTester tester,
  Widget child, {
  KnightlyThemeId theme = KnightlyThemeId.darkKnight,
  bool settle = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildKnightlyTheme(theme),
      home: Scaffold(
        body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: child),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 500));
  }
}

/// A fresh in-memory database for widget tests. Streams close synchronously so
/// no drift timers are left pending when the widget tree is torn down.
AppDatabase testDatabase() {
  final db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
  addTearDown(db.close);
  return db;
}

/// Pumps the full app against [db] (default: a fresh in-memory database).
/// [now] freezes the clock.
Future<AppDatabase> pumpKnightlyApp(
  WidgetTester tester, {
  AppDatabase? db,
  DateTime? now,
  List<Override> overrides = const [],
  bool showWelcome = false,
}) async {
  final database = db ?? testDatabase();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        // The cold-start brand reveal would cover the UI; tests start past it.
        bootSequenceEnabledProvider.overrideWithValue(false),
        // Live header scenes repaint on a timer; tests need frames to settle.
        liveSceneEnabledProvider.overrideWithValue(false),
        // The first-run welcome is tested on its own.
        welcomeEnabledProvider.overrideWithValue(showWelcome),
        // No motion sensor in tests.
        deviceTiltEnabledProvider.overrideWithValue(false),
        // No audio in tests.
        soundsAllowedProvider.overrideWithValue(false),
        homeWidgetEnabledProvider.overrideWithValue(false),
        if (now != null) clockProvider.overrideWithValue(() => now),
        ...overrides,
      ],
      child: const KnightlyApp(),
    ),
  );
  await settleWithDatabase(tester);
  return database;
}

/// Seeds a fresh database *before* the app starts listening, then pumps the
/// app. Writing from a test while app streams are live deadlocks: drift's lock
/// is then held by queries running on the fake test clock.
Future<AppDatabase> pumpSeededKnightlyApp(
  WidgetTester tester, {
  required DateTime now,
  required Future<void> Function(AppDatabase db) seed,
  List<Override> overrides = const [],
}) async {
  final db = testDatabase();
  await tester.runAsync(() => seed(db));
  return pumpKnightlyApp(tester, db: db, now: now, overrides: overrides);
}

/// Lets real database I/O finish (it runs outside the fake test clock), then
/// settles animations. Use after any action that writes to or reads from Drift.
Future<void> settleWithDatabase(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
  await tester.pumpAndSettle();
}

/// Canvas colour of the theme applied to the widget found by [finder].
Color canvasOf(WidgetTester tester, Finder finder) =>
    Theme.of(tester.element(finder)).scaffoldBackgroundColor;

/// Scrolls the visible page until [finder] is built and on screen. Pages build
/// lower sections lazily, so anything below the fold needs this first.
Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 250, scrollable: find.byType(Scrollable).hitTestable().first);
  await tester.pumpAndSettle();
}

/// Scrolls the visible page back to its top.
Future<void> scrollToTop(WidgetTester tester) async {
  await tester.drag(find.byType(Scrollable).hitTestable().first, const Offset(0, 3000));
  await tester.pumpAndSettle();
}

/// Opens Settings from the gear at the top right of the current tab.
Future<void> openSettings(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Settings').hitTestable().first);
  await tester.pumpAndSettle();
}

/// Closes pushed pages (Settings and anything opened from it) until the tab
/// dock is back.
Future<void> backToTabs(WidgetTester tester) async {
  for (var i = 0; i < 5 && find.byType(KNavigationBar).evaluate().isEmpty; i++) {
    await tester.tap(find.byTooltip('Back').hitTestable().first);
    await tester.pumpAndSettle();
  }
}

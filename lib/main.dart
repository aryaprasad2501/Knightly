import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/knightly_app.dart';
import 'core/design/ambient/k_ambient_scene.dart';
import 'core/perf/frame_probe.dart';
import 'core/design/motion/k_effects.dart';
import 'features/settings/application/display_controllers.dart';
import 'features/notifications/data/notification_gateway.dart';
import 'features/settings/application/live_backdrop_controller.dart';
import 'features/settings/application/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerFontLicenses();
  FrameProbe.start();

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Reminders: the real device notifications (tests use a silent stand-in).
  final notifications = LocalNotifications();
  try {
    await notifications.init();
  } catch (e) {
    debugPrint('Knightly: notifications unavailable: $e');
  }

  final container = ProviderContainer(
    overrides: [
      notificationGatewayProvider.overrideWithValue(notifications),
      // Core's live header scene follows the user's "Live backdrop" setting.
      // Low mode switches the live scene off too.
      liveSceneEnabledProvider.overrideWith(
        (ref) => ref.watch(liveBackdropProvider) && !ref.watch(lowModeProvider),
      ),
      lowEffectsProvider.overrideWith((ref) => ref.watch(lowModeProvider)),
    ],
  );

  // Load the saved theme before the first frame so there is no theme flash.
  // On failure the app still starts with the fallback theme.
  try {
    await container.read(themeControllerProvider.future);
  } catch (_) {
    // Fallback theme is used; the error resurfaces if the user changes theme.
  }

  runApp(UncontrolledProviderScope(container: container, child: const KnightlyApp()));
}

/// Bundled fonts are SIL OFL 1.1; their licences appear on the licences page.
void _registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final (family, path) in const [('Inter', 'inter'), ('Sora', 'sora')]) {
      final text = await rootBundle.loadString('assets/fonts/$path/OFL.txt');
      yield LicenseEntryWithLineBreaks([family], text);
    }
    // The bundled exercise library; public domain, credited with thanks.
    yield const LicenseEntryWithLineBreaks(
      ['free-exercise-db (exercise library)'],
      'Exercise data from free-exercise-db by yuhonas (github.com/yuhonas/free-exercise-db), '
      'released under The Unlicense: dedicated to the public domain.',
    );
    // The bundled food list; U.S. government work, public domain.
    yield const LicenseEntryWithLineBreaks(
      ['USDA FoodData Central (food list)'],
      'Food data from U.S. Department of Agriculture, Agricultural Research Service. '
      'FoodData Central, SR Legacy (2018), fdc.nal.usda.gov. Public domain (CC0 1.0).',
    );
  });
}

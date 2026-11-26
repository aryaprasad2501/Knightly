import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/ambient/k_backdrop.dart';
import '../../core/modules/app_module.dart';
import '../../core/design/components/k_navigation_bar.dart';
import '../../core/design/icons/k_glyphs.dart';
import '../../core/design/theme/theme_context.dart';
import '../../core/design/tokens/k_motion.dart';
import '../../core/design/tokens/k_spacing.dart';
import '../../features/calendar/application/calendar_providers.dart';
import '../../features/calendar/presentation/event_editor_sheet.dart';
import '../../features/habits/presentation/habit_editor_sheet.dart';
import '../../core/time/clock.dart';
import '../../features/routines/presentation/routine_editor_sheet.dart';
import '../../features/tasks/presentation/task_editor_sheet.dart';
import '../../features/tasks/presentation/task_ui_actions.dart';

/// Top-level destinations, in bottom-bar order. Must match the branch order in
/// `app_router.dart`.
const shellDestinations = [
  KNavDestination(glyph: KGlyphs.home, label: 'Home'),
  KNavDestination(glyph: KGlyphs.calendar, label: 'Calendar'),
  KNavDestination(glyph: KGlyphs.tasks, label: 'Tasks'),
  KNavDestination(glyph: KGlyphs.track, label: 'Track'),
  KNavDestination(glyph: KGlyphs.settings, label: 'Settings'),
];

/// Hosts the five branch navigators under the Knightly command dock. Each
/// branch keeps its own navigation stack. The dock's contextual action follows
/// the selected screen.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell, required this.children});

  final StatefulNavigationShell navigationShell;
  final List<Widget> children;

  /// Whether branch [index] (in [shellDestinations] order) is shown, given
  /// the modules that are on. Home and Settings are always there; Track stays
  /// while anything it shows is on.
  static bool isBranchVisible(int index, Set<AppModule> on) => switch (index) {
    1 => on.contains(AppModule.calendar),
    2 => on.contains(AppModule.missions),
    3 =>
      on.contains(AppModule.habits) ||
          on.contains(AppModule.routines) ||
          on.contains(AppModule.analytics) ||
          on.any(AppModule.trackers.contains),
    _ => true,
  };

  void _onSelected(int index) {
    // Re-selecting the current tab returns it to its root.
    navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
  }

  /// The command each screen puts on the dock, in [shellDestinations] order.
  KDockAction? _actionFor(int index, BuildContext context, WidgetRef ref) => switch (index) {
    // From Home a new mission is for today; from Tasks it follows the board's view.
    0 when _on(ref, AppModule.missions) => KDockAction(
      glyph: KGlyphs.plus,
      label: 'New mission',
      onPressed: () => showTaskEditor(context, initialDue: ref.read(todayProvider)),
    ),
    1 => KDockAction(
      glyph: KGlyphs.plus,
      label: 'New event',
      onPressed: () => showEventEditor(context, initialDate: ref.read(focusedDateProvider)),
    ),
    2 => KDockAction(
      glyph: KGlyphs.plus,
      label: 'New mission',
      onPressed: () => composeMission(context, ref),
    ),
    3 when _on(ref, AppModule.habits) => KDockAction(
      glyph: KGlyphs.plus,
      label: 'New habit',
      onPressed: () => showHabitEditor(context),
    ),
    3 when _on(ref, AppModule.routines) => KDockAction(
      glyph: KGlyphs.plus,
      label: 'New routine',
      onPressed: () => showRoutineEditor(context),
    ),
    _ => null,
  };

  static bool _on(WidgetRef ref, AppModule module) => ref.read(enabledModulesProvider).contains(module);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canvas = context.palette.canvas;
    final modules = ref.watch(enabledModulesProvider);
    final visible = [
      for (var i = 0; i < shellDestinations.length; i++)
        if (isBranchVisible(i, modules)) i,
    ];
    final current = navigationShell.currentIndex;
    if (!visible.contains(current)) {
      // The open tab's module was just switched off: go Home.
      WidgetsBinding.instance.addPostFrameCallback((_) => navigationShell.goBranch(0));
    }
    // Decode the theme's page backdrops up front so every tab opens on its
    // picture, not on the drawn fallback. Cached, so repeat calls are free.
    final family = context.style.family;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      for (final art in KBackdropArt.all(family)) {
        precacheImage(AssetImage(art.asset), context);
      }
    });
    // The strip under the floating dock (system gesture area + gap) must be
    // fully opaque, or scrolled content shows through below the dock.
    final solid = MediaQuery.viewPaddingOf(context).bottom + KSpacing.lg;
    const fade = 110.0;

    // Back on another tab returns to Home first; only Home's Back leaves the app.
    return PopScope(
      canPop: navigationShell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) navigationShell.goBranch(0);
      },
      child: Scaffold(
        extendBody: true,
        body: Stack(
          children: [
            for (var i = 0; i < children.length; i++)
              _BranchLayer(active: i == navigationShell.currentIndex, child: children[i]),
            // Fades content into the canvas behind the floating dock.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: fade + solid,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0, fade / (fade + solid), 1],
                      colors: [canvas.withValues(alpha: 0), canvas, canvas],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: KNavigationBar(
          destinations: [for (final i in visible) shellDestinations[i]],
          selectedIndex: visible.contains(current) ? visible.indexOf(current) : 0,
          onSelected: (i) => _onSelected(visible[i]),
          action: _actionFor(current, context, ref),
        ),
      ),
    );
  }
}

/// One branch in the stack. Inactive branches stay alive (state preserved) but
/// are invisible, untouchable, hidden from accessibility and have tickers paused.
class _BranchLayer extends StatelessWidget {
  const _BranchLayer({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Only the incoming branch fades (briefly); the outgoing one disappears at
    // once. Cross-fading two full screens doubles the offscreen compositing
    // work and caused the tab-switch frame spikes in PERFORMANCE.md.
    final duration = active ? KMotion.quick : Duration.zero;
    return AnimatedOpacity(
      opacity: active ? 1 : 0,
      duration: duration,
      curve: KMotion.enter,
      child: AnimatedSlide(
        offset: active ? Offset.zero : const Offset(0, 0.012),
        duration: duration,
        curve: KMotion.emphasized,
        child: IgnorePointer(
          ignoring: !active,
          child: ExcludeSemantics(
            excluding: !active,
            child: TickerMode(enabled: active, child: child),
          ),
        ),
      ),
    );
  }
}

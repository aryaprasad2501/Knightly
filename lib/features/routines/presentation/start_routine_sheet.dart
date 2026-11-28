import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/design/components/k_bottom_sheet.dart';
import '../../../core/design/components/k_button.dart';
import '../../../core/design/components/k_divider.dart';
import '../../../core/design/components/k_empty_state.dart';
import '../../../core/design/components/k_loading_indicator.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../application/routines_providers.dart';
import '../domain/routine.dart';
import 'routine_editor_sheet.dart';
import 'routines_section.dart';

/// Lets the user pick a routine to run. Public entry point for Home.
Future<void> showStartRoutineSheet(BuildContext context) {
  return showKBottomSheet<void>(context: context, title: 'Start a routine', child: const _Picker());
}

class _Picker extends ConsumerWidget {
  const _Picker();

  static int _rank(RoutineDayStatus s) => switch (s) {
    RoutineDayStatus.inProgress => 0,
    RoutineDayStatus.due => 1,
    RoutineDayStatus.done => 2,
    RoutineDayStatus.rest => 3,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(routinesTodayProvider)
        .when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: KSpacing.xl),
            child: Center(child: KLoadingIndicator()),
          ),
          error: (_, _) => const KEmptyState(
            glyph: KGlyphs.alert,
            title: 'Routines could not be loaded',
            message: 'Restart Knightly to try again.',
            compact: true,
          ),
          data: (all) {
            if (all.isEmpty) {
              return KEmptyState(
                glyph: KGlyphs.routine,
                title: 'No routines yet',
                message: 'Make one first — a few steps you repeat together.',
                compact: true,
                action: KButton(
                  label: 'New routine',
                  glyph: KGlyphs.plus,
                  onPressed: () {
                    // The navigator outlives this sheet; open the editor from it.
                    final navigator = Navigator.of(context);
                    navigator.pop();
                    showRoutineEditor(navigator.context);
                  },
                ),
              );
            }
            final sorted = [...all]..sort((a, b) => _rank(a.status).compareTo(_rank(b.status)));
            // Captured now: the sheet's context is gone once it is popped.
            final router = GoRouter.of(context);
            void start(RoutineToday r) {
              Navigator.of(context).pop();
              router.push(AppRoutes.routineRunFor(r.routine.id));
            }

            return ListView(
              shrinkWrap: true,
              children: [
                for (final (i, r) in sorted.indexed) ...[
                  if (i > 0) const KDivider(indent: 64, spacing: 0),
                  RoutineTile(
                    key: ValueKey('pick-${r.routine.id}'),
                    today: r,
                    onTap: () => start(r),
                    onStart: () => start(r),
                  ),
                ],
              ],
            );
          },
        );
  }
}

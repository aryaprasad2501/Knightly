import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components/k_bottom_sheet.dart';
import '../../../core/design/components/k_button.dart';
import '../../../core/design/components/k_card.dart';
import '../../../core/design/components/k_confirmation_dialog.dart';
import '../../../core/design/components/k_icon_button.dart';
import '../../../core/design/components/k_section_header.dart';
import '../../../core/design/components/k_text_field.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../application/workouts_providers.dart';
import '../domain/workout.dart';
import '../domain/workout_template.dart';

/// What to start: an empty workout or one of the saved templates. Returns
/// the new workout's id, or null when dismissed.
Future<int?> pickWorkoutStart(BuildContext context, WidgetRef ref, List<WorkoutTemplate> templates) =>
    showKBottomSheet<int>(
      context: context,
      title: 'Start a workout',
      child: _StartSheet(initial: templates),
    );

class _StartSheet extends ConsumerWidget {
  const _StartSheet({required this.initial});

  final List<WorkoutTemplate> initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(workoutTemplatesProvider).value ?? initial;
    final actions = ref.read(workoutActionsProvider);
    final navigator = Navigator.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KButton(
          label: 'Empty workout',
          glyph: KGlyphs.plus,
          variant: KButtonVariant.secondary,
          expand: true,
          onPressed: () async => navigator.pop(await actions.start()),
        ),
        const SizedBox(height: KSpacing.lg),
        KSectionHeader('Templates · ${templates.length}'),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final t in templates) ...[
                  KCard(
                    glyph: KGlyphs.dumbbell,
                    title: t.name,
                    subtitle: t.summary,
                    trailing: KIconButton(
                      glyph: KGlyphs.trash,
                      tooltip: 'Delete template ${t.name}',
                      onPressed: () async {
                        final ok = await showKConfirmationDialog(
                          context,
                          title: 'Delete "${t.name}"?',
                          message: 'Only the template goes; workouts you logged with it stay.',
                          confirmLabel: 'Delete',
                          destructive: true,
                        );
                        if (ok) await actions.deleteTemplate(t.id);
                      },
                    ),
                    onTap: () async => navigator.pop(await actions.startFromTemplate(t.id)),
                  ),
                  const SizedBox(height: KSpacing.sm),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Saves a finished [workout] as a template, asking for its name.
Future<void> saveWorkoutAsTemplate(BuildContext context, WidgetRef ref, Workout workout) async {
  final messenger = ScaffoldMessenger.of(context);
  final name = await showKBottomSheet<String>(
    context: context,
    title: 'Save as template',
    child: _TemplateNameSheet(initial: workout.name),
  );
  if (name == null) return;
  final id = await ref.read(workoutActionsProvider).saveAsTemplate(workout.id, name);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(id == null ? 'Nothing logged to save' : 'Template saved')));
}

/// Asks for a template name; owns its text controller (the sheet animates
/// out after popping, so the controller must outlive the await).
class _TemplateNameSheet extends StatefulWidget {
  const _TemplateNameSheet({required this.initial});

  final String initial;

  @override
  State<_TemplateNameSheet> createState() => _TemplateNameSheetState();
}

class _TemplateNameSheetState extends State<_TemplateNameSheet> {
  late final _name = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Its exercises and sets are kept, so next time you start it with one tap.',
        style: context.textStyles.bodySmall?.copyWith(color: context.palette.textSecondary),
      ),
      const SizedBox(height: KSpacing.md),
      KTextField(
        label: 'Template name',
        controller: _name,
        hint: 'e.g. Push day',
        autofocus: true,
        maxLength: WorkoutTemplate.maxNameLength,
        onSubmitted: (v) => Navigator.of(context).pop(v),
      ),
      const SizedBox(height: KSpacing.md),
      KButton(label: 'Save template', expand: true, onPressed: () => Navigator.of(context).pop(_name.text)),
    ],
  );
}

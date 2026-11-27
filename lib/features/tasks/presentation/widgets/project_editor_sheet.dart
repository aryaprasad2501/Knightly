import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/components/k_bottom_sheet.dart';
import '../../../../core/design/components/k_button.dart';
import '../../../../core/design/components/k_text_field.dart';
import '../../../../core/design/icons/k_glyphs.dart';
import '../../../../core/design/tokens/k_spacing.dart';
import '../../application/tasks_providers.dart';
import '../../data/task_repository.dart';
import '../../domain/task.dart';

/// Creates a project, or renames/deletes [project]. Returns a new project's
/// id. [showOnBoard] also filters the Tasks board to the new project (off when
/// creating one from inside the mission editor).
Future<int?> showProjectEditor(BuildContext context, {Project? project, bool showOnBoard = true}) {
  return showKBottomSheet<int>(
    context: context,
    title: project == null ? 'New project' : 'Edit project',
    subtitle: project == null ? 'Group related missions, like "Work" or "Home".' : null,
    child: _ProjectEditor(project: project, showOnBoard: showOnBoard),
  );
}

class _ProjectEditor extends ConsumerStatefulWidget {
  const _ProjectEditor({this.project, this.showOnBoard = true});

  final Project? project;
  final bool showOnBoard;

  @override
  ConsumerState<_ProjectEditor> createState() => _ProjectEditorState();
}

class _ProjectEditorState extends ConsumerState<_ProjectEditor> {
  late final _name = TextEditingController(text: widget.project?.name ?? '');
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final actions = ref.read(taskActionsProvider);
    final navigator = Navigator.of(context);
    try {
      if (widget.project == null) {
        final id = await actions.createProject(_name.text);
        if (widget.showOnBoard) ref.read(projectFilterProvider.notifier).select(id);
        navigator.pop(id);
        return;
      } else {
        await actions.renameProject(widget.project!.id, _name.text);
      }
      navigator.pop();
    } on TaskValidationException catch (e) {
      setState(() => _error = e.message);
    }
  }

  /// Moves the project to the Recycle Bin. Its missions stay (shown without a
  /// project) and reconnect when it is restored.
  Future<void> _delete() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final actions = ref.read(taskActionsProvider);
    final id = widget.project!.id;
    await actions.trashProject(id);
    navigator.pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Project moved to Recycle Bin · its missions stay'),
          action: SnackBarAction(label: 'Undo', onPressed: () => actions.restoreProject(id)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          KTextField(
            label: 'Name',
            controller: _name,
            hint: 'e.g. Home renovation',
            autofocus: true,
            errorText: _error,
            maxLength: TaskRepository.maxProjectNameLength,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: KSpacing.xl),
          KButton(label: widget.project == null ? 'Create project' : 'Save', expand: true, onPressed: _save),
          if (widget.project != null) ...[
            const SizedBox(height: KSpacing.md),
            KButton(
              label: 'Delete project',
              glyph: KGlyphs.trash,
              variant: KButtonVariant.secondary,
              expand: true,
              onPressed: _delete,
            ),
          ],
        ],
      ),
    );
  }
}

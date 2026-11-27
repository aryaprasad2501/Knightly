import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components/k_button.dart';
import '../../../core/design/components/k_confirmation_dialog.dart';
import '../../../core/design/components/k_empty_state.dart';
import '../../../core/design/components/k_icon_button.dart';
import '../../../core/design/components/k_loading_indicator.dart';
import '../../../core/design/components/k_surface.dart';
import '../../../core/design/icons/k_glyph.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/layout/k_page.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../../../core/time/clock.dart';
import '../application/recycle_bin_providers.dart';
import '../domain/bin_item.dart';

/// Deleted missions, projects and habits. Each can be restored as it was or
/// deleted for good (after confirmation); "Empty" clears everything.
class RecycleBinScreen extends ConsumerWidget {
  const RecycleBinScreen({super.key});

  Future<void> _empty(BuildContext context, WidgetRef ref, int count) async {
    final ok = await showKConfirmationDialog(
      context,
      title: 'Empty the Recycle Bin?',
      message:
          '$count ${count == 1 ? 'item is' : 'items are'} deleted from this device for good, '
          'including the history of any habits. This cannot be undone.',
      confirmLabel: 'Empty',
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final removed = await ref.read(recycleBinActionsProvider).emptyAll();
    messenger.showSnackBar(
      SnackBar(content: Text('Deleted $removed ${removed == 1 ? 'item' : 'items'} for good')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(binItemsProvider);
    final count = items.valueOrNull?.length ?? 0;

    return KSubpage(
      title: 'Recycle Bin',
      actions: [
        if (count > 0)
          KIconButton(
            glyph: KGlyphs.trash,
            tooltip: 'Empty Recycle Bin',
            onPressed: () => _empty(context, ref, count),
          ),
      ],
      children: items.when(
        loading: () => const [
          Padding(
            padding: EdgeInsets.all(KSpacing.xxl),
            child: Center(child: KLoadingIndicator()),
          ),
        ],
        error: (_, _) => const [
          KEmptyState(
            glyph: KGlyphs.alert,
            title: 'Could not open the Recycle Bin',
            message: 'Close this page and try again. Nothing was changed.',
          ),
        ],
        data: (list) => list.isEmpty
            ? const [
                SizedBox(height: KSpacing.xxl),
                KEmptyState(
                  glyph: KGlyphs.trash,
                  title: 'Recycle Bin is empty',
                  message:
                      'Deleted missions, projects, habits and events wait here until you restore them or delete them '
                      'for good.',
                ),
              ]
            : [
                Text(
                  'Restore brings an item back exactly as it was. Habits keep their history while they are here.',
                  style: context.textStyles.bodyMedium?.copyWith(color: context.palette.textSecondary),
                ),
                const SizedBox(height: KSpacing.lg),
                for (final item in list) ...[_BinRow(item: item), const SizedBox(height: KSpacing.md)],
              ],
      ),
    );
  }
}

class _BinRow extends ConsumerWidget {
  const _BinRow({required this.item});

  final BinItem item;

  KGlyphData get _glyph => switch (item.kind) {
    BinKind.mission => KGlyphs.tasks,
    BinKind.project => KGlyphs.folder,
    BinKind.habit => KGlyphs.habit,
    BinKind.event => KGlyphs.calendar,
    BinKind.routine => KGlyphs.routine,
    BinKind.workout => KGlyphs.dumbbell,
    BinKind.food => KGlyphs.leaf,
    BinKind.careJob => KGlyphs.home,
  };

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(recycleBinActionsProvider).restore(item);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Restored "${item.title}"')));
  }

  Future<void> _deleteForGood(BuildContext context, WidgetRef ref) async {
    final ok = await showKConfirmationDialog(
      context,
      title: 'Delete "${item.title}" for good?',
      message: switch (item.kind) {
        BinKind.habit =>
          'The habit and its whole check-in history are removed from this device. This cannot be undone.',
        BinKind.project =>
          'The project is removed; its missions stay, without a project. This cannot be undone.',
        BinKind.mission => 'The mission is removed from this device. This cannot be undone.',
        BinKind.event =>
          'The event and all its occurrences are removed from this device. This cannot be undone.',
        BinKind.routine =>
          'The routine, its steps and its run history are removed from this device. This cannot be undone.',
        BinKind.workout =>
          'The workout and all its sets are removed from this device. This cannot be undone.',
        BinKind.food =>
          'The food is removed from this device; meals already logged keep their numbers. This cannot be undone.',
        BinKind.careJob =>
          'The job and its whole history are removed from this device. This cannot be undone.',
      },
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    await ref.read(recycleBinActionsProvider).deletePermanently(item);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = context.textStyles;
    final now = ref.watch(clockProvider)();
    final meta = [
      item.kind.label,
      describeDeleted(item.deletedAt, now),
      if (item.detail.isNotEmpty) item.detail,
    ];

    return Semantics(
      container: true,
      child: KSurface(
        padding: const EdgeInsets.fromLTRB(KSpacing.lg, KSpacing.md, KSpacing.xs, KSpacing.md),
        child: Row(
          children: [
            KIcon(_glyph, size: 22, color: p.textSecondary),
            const SizedBox(width: KSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: text.bodyLarge),
                  const SizedBox(height: 2),
                  Text(meta.join(' · '), style: text.bodySmall?.copyWith(color: p.textMuted)),
                ],
              ),
            ),
            KButton(
              label: 'Restore',
              size: KButtonSize.compact,
              variant: KButtonVariant.outlined,
              onPressed: () => _restore(context, ref),
            ),
            KIconButton(
              glyph: KGlyphs.close,
              tooltip: 'Delete "${item.title}" for good',
              onPressed: () => _deleteForGood(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}

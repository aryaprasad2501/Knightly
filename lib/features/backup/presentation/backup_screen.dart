import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components/k_button.dart';
import '../../../core/design/components/k_card.dart';
import '../../../core/design/components/k_confirmation_dialog.dart';
import '../../../core/design/components/k_section_header.dart';
import '../../../core/design/components/k_surface.dart';
import '../../../core/design/icons/k_glyph.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/layout/k_page.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../../../core/platform/document_files.dart';
import '../../../core/time/clock.dart';
import '../application/backup_providers.dart';
import '../data/backup_service.dart';
import '../domain/backup_format.dart';

/// Manual backup to a file the user chooses, and restore from one.
///
/// Everything stays offline: the file goes wherever the user saves it in the
/// system file picker. A restore shows what the file contains, asks for
/// confirmation and saves a safety copy of the current data first.
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

enum _Busy { none, backingUp, checking, restoring }

class _BackupScreenState extends ConsumerState<BackupScreen> {
  _Busy _busy = _Busy.none;

  /// The last restore attempt's problem, shown on the page until the next try.
  String? _problem;

  void _say(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  Future<void> _backUp() async {
    setState(() => _busy = _Busy.backingUp);
    try {
      final name = await ref.read(backupActionsProvider).createBackup(ref.read(clockProvider)());
      if (name != null) _say('Backup saved · $name');
    } on DocumentException catch (e) {
      _say(e.message);
    } catch (_) {
      _say('The backup could not be created. Nothing was changed.');
    } finally {
      if (mounted) setState(() => _busy = _Busy.none);
    }
  }

  Future<void> _restoreFromFile() async {
    setState(() {
      _busy = _Busy.checking;
      _problem = null;
    });
    final actions = ref.read(backupActionsProvider);
    CheckedBackup? backup;
    try {
      backup = await actions.pickBackup();
    } on BackupException catch (e) {
      _problem = e.message;
    } on DocumentException catch (e) {
      _problem = e.message;
    } catch (_) {
      _problem = "The file couldn't be checked. Nothing was changed.";
    }
    if (!mounted) return;
    setState(() => _busy = _Busy.none);
    if (backup != null) await _confirmAndRestore(backup.json, backup.summary, source: backup.fileName);
  }

  Future<void> _confirmAndRestore(String json, BackupSummary summary, {String? source}) async {
    final when = _formatWhen(context, summary.createdAt);
    final ok = await showKConfirmationDialog(
      context,
      title: 'Replace all your data?',
      message:
          '${source == null ? 'This copy' : '"$source"'} is from $when and holds ${_contents(summary)}.\n\n'
          'Restoring replaces everything currently in Knightly — missions, projects, habits, check-ins, '
          'the Recycle Bin and your theme. A safety copy of your current data is saved first.',
      confirmLabel: 'Restore',
      destructive: true,
      glyph: KGlyphs.backup,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = _Busy.restoring);
    try {
      final restored = await ref.read(backupActionsProvider).restore(json);
      _say('Restored ${_contents(restored)} · a safety copy of your previous data is kept');
    } on BackupException catch (e) {
      setState(() => _problem = e.message);
    } catch (_) {
      setState(() => _problem = 'The restore failed and nothing was changed. Your data is as it was.');
    } finally {
      if (mounted) setState(() => _busy = _Busy.none);
    }
  }

  static String _contents(BackupSummary s) {
    String n(int count, String one) => '$count ${count == 1 ? one : '${one}s'}';
    return '${n(s.missions, 'mission')}, ${n(s.projects, 'project')}, ${n(s.habits, 'habit')}, '
        '${n(s.checkIns, 'check-in')}, ${n(s.events, 'event')}, ${n(s.routines, 'routine')} and ${n(s.waterLogs, 'water log')}';
  }

  static String _formatWhen(BuildContext context, DateTime at) {
    final l = MaterialLocalizations.of(context);
    return '${l.formatMediumDate(at)}, ${l.formatTimeOfDay(TimeOfDay.fromDateTime(at))}';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.textStyles;
    final last = ref.watch(lastBackupProvider).valueOrNull;
    final copies = ref.watch(safetyCopiesProvider).valueOrNull ?? const [];
    final idle = _busy == _Busy.none;

    return KSubpage(
      title: 'Backup & restore',
      children: [
        KCard(
          glyph: KGlyphs.backup,
          title: 'Create a backup',
          subtitle:
              'Saves every mission, project, habit, check-in and setting into one file. You choose where it goes — '
              'this phone, an SD card or a USB drive. Nothing is uploaded.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                last == null
                    ? 'No backup made on this phone yet.'
                    : 'Last backup: ${_formatWhen(context, last)}',
                style: text.bodySmall?.copyWith(color: p.textMuted),
              ),
              const SizedBox(height: KSpacing.md),
              KButton(
                label: 'Create backup',
                glyph: KGlyphs.backup,
                expand: true,
                loading: _busy == _Busy.backingUp,
                onPressed: idle ? _backUp : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: KSpacing.lg),
        KCard(
          glyph: KGlyphs.archive,
          title: 'Restore from a backup',
          subtitle:
              'Pick a Knightly backup file. It is checked completely first, and you see what it holds before '
              'anything changes.',
          child: KButton(
            label: 'Choose backup file',
            glyph: KGlyphs.folder,
            variant: KButtonVariant.secondary,
            expand: true,
            loading: _busy == _Busy.checking || _busy == _Busy.restoring,
            onPressed: idle ? _restoreFromFile : null,
          ),
        ),
        if (_problem != null) ...[
          const SizedBox(height: KSpacing.lg),
          Semantics(
            liveRegion: true,
            container: true,
            child: KSurface(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  KIcon(KGlyphs.alert, size: 22, color: p.danger),
                  const SizedBox(width: KSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Not restored', style: text.titleSmall),
                        const SizedBox(height: KSpacing.xs),
                        Text(_problem!, style: text.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (copies.isNotEmpty) ...[
          const SizedBox(height: KSpacing.xl),
          const KSectionHeader('Safety copies'),
          Text(
            'Saved automatically before each restore, on this phone only. The newest '
            '${BackupService.keepSafetyCopies} are kept.',
            style: text.bodyMedium?.copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: KSpacing.md),
          for (final copy in copies) ...[
            KCard(
              glyph: KGlyphs.clock,
              title: 'Data as of ${_formatWhen(context, copy.summary.createdAt)}',
              subtitle: _contents(copy.summary),
              trailing: KButton(
                label: 'Restore',
                size: KButtonSize.compact,
                variant: KButtonVariant.outlined,
                onPressed: idle
                    ? () async => _confirmAndRestore(await copy.file.readAsString(), copy.summary)
                    : null,
              ),
            ),
            const SizedBox(height: KSpacing.md),
          ],
        ],
        const SizedBox(height: KSpacing.lg),
        Text(
          'Backups are plain JSON files. Keep one somewhere safe: uninstalling Knightly or losing this phone '
          'removes all data, and Android cloud backup is off for this app.',
          style: text.bodySmall?.copyWith(color: p.textMuted),
        ),
      ],
    );
  }
}

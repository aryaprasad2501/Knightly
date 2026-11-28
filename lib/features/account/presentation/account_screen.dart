import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components/k_bottom_sheet.dart';
import '../../../core/design/components/k_button.dart';
import '../../../core/design/components/k_confirmation_dialog.dart';
import '../../../core/design/components/k_section_header.dart';
import '../../../core/design/components/k_surface.dart';
import '../../../core/design/icons/k_glyph.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/layout/k_page.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../../../core/sync/sync_engine.dart';
import '../../../core/time/clock.dart';
import '../application/account_providers.dart';
import '../application/sync_controller.dart';
import '../data/account_service.dart';

/// Settings › Account & sync: optional Google account. Signed out, Knightly
/// works fully offline as before.
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  bool _busy = false;
  String? _problem;

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _problem = null;
    });
    final problem = await ref.read(accountProvider.notifier).signIn();
    if (mounted) {
      setState(() {
        _busy = false;
        _problem = problem;
      });
    }
  }

  void _show(String? problem) {
    if (problem == null || !mounted) return;
    setState(() => _problem = problem);
  }

  /// Sign out, keeping or removing this phone's copy.
  Future<void> _signOut() async {
    final choice = await showKBottomSheet<bool>(
      context: context,
      title: 'Sign out',
      subtitle: 'Syncing stops. Your account keeps everything; sign in again any time.',
      child: Builder(
        builder: (sheet) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KButton(
              label: 'Sign out, keep data on this phone',
              expand: true,
              onPressed: () => Navigator.of(sheet).pop(false),
            ),
            const SizedBox(height: KSpacing.sm),
            KButton(
              label: 'Sign out and remove it from this phone',
              variant: KButtonVariant.secondary,
              expand: true,
              onPressed: () => Navigator.of(sheet).pop(true),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    if (choice) {
      final ok = await showKConfirmationDialog(
        context,
        title: 'Remove data from this phone?',
        message: 'It stays in your account: sign in again to get it back. Waiting changes are sent first.',
        confirmLabel: 'Remove and sign out',
        destructive: true,
      );
      if (!ok) return;
    }
    _show(await ref.read(syncControllerProvider.notifier).signOut(removeFromPhone: choice));
  }

  /// Deletes the account and its cloud data, after a clear warning.
  Future<void> _deleteAccount() async {
    final removeFromPhone = await showKBottomSheet<bool>(
      context: context,
      title: 'Delete account',
      subtitle:
          'Removes everything Knightly keeps in your Google account, and the account link itself. '
          'This cannot be undone.',
      child: Builder(
        builder: (sheet) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KButton(
              label: 'Delete account, keep data on this phone',
              variant: KButtonVariant.secondary,
              expand: true,
              onPressed: () => Navigator.of(sheet).pop(false),
            ),
            const SizedBox(height: KSpacing.sm),
            KButton(
              label: 'Delete account and this phone\'s data',
              variant: KButtonVariant.secondary,
              expand: true,
              onPressed: () => Navigator.of(sheet).pop(true),
            ),
          ],
        ),
      ),
    );
    if (removeFromPhone == null || !mounted) return;
    final ok = await showKConfirmationDialog(
      context,
      title: 'Delete your Knightly account?',
      message: removeFromPhone
          ? 'Your cloud copy and everything on this phone are deleted. Make a backup first if unsure.'
          : 'Your cloud copy is deleted. This phone keeps its data and works offline.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    setState(() => _busy = true);
    final problem = await ref
        .read(syncControllerProvider.notifier)
        .deleteAccount(removeFromPhone: removeFromPhone);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _problem = problem;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.textStyles;
    final account = ref.watch(accountProvider);
    final available = ref.watch(accountAvailableProvider).value;
    final user = account.value;

    return KSubpage(
      title: 'Account & sync',
      children: [
        if (account.isLoading && !account.hasValue)
          const SizedBox.shrink()
        else if (user == null) ...[
          KSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Keep your data safe', style: text.titleMedium),
                const SizedBox(height: KSpacing.xs),
                Text(
                  'Sign in with Google to keep a copy of everything in your own account: reinstall Knightly or '
                  'use another phone and sign in to get it all back. Optional; without an account Knightly '
                  'works fully offline, as now.',
                  style: text.bodySmall?.copyWith(color: p.textSecondary),
                ),
                const SizedBox(height: KSpacing.lg),
                KButton(
                  label: 'Continue with Google',
                  glyph: KGlyphs.shield,
                  expand: true,
                  loading: _busy,
                  onPressed: available == false ? null : _signIn,
                ),
                if (available == false) ...[
                  const SizedBox(height: KSpacing.sm),
                  Text(
                    'Cloud sync isn\'t set up in this version of Knightly.',
                    style: text.bodySmall?.copyWith(color: p.textMuted),
                  ),
                ],
                if (_problem != null) ...[
                  const SizedBox(height: KSpacing.sm),
                  Text(_problem!, style: text.bodySmall?.copyWith(color: p.warning)),
                ],
              ],
            ),
          ),
        ] else ...[
          _SignedIn(user: user),
          const SizedBox(height: KSpacing.xl),
          const KSectionHeader('Sync'),
          const _SyncPanel(),
          const SizedBox(height: KSpacing.xl),
          if (_problem != null) ...[
            Text(_problem!, style: text.bodySmall?.copyWith(color: p.warning)),
            const SizedBox(height: KSpacing.sm),
          ],
          KButton(label: 'Sign out', variant: KButtonVariant.secondary, expand: true, onPressed: _signOut),
          const SizedBox(height: KSpacing.sm),
          KButton(
            label: 'Delete account',
            glyph: KGlyphs.trash,
            variant: KButtonVariant.secondary,
            expand: true,
            loading: _busy,
            onPressed: _deleteAccount,
          ),
        ],
      ],
    );
  }
}

class _SignedIn extends StatelessWidget {
  const _SignedIn({required this.user});

  final AccountUser user;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.textStyles;
    return KSurface(
      child: Row(
        children: [
          KIcon(KGlyphs.shield, size: 28, color: p.accentStrong),
          const SizedBox(width: KSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (user.name != null && user.name!.isNotEmpty) Text(user.name!, style: text.titleMedium),
                Text(user.email, style: text.bodyMedium?.copyWith(color: p.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Sync status, last synced time, pending changes, Sync now / Retry, and the
/// first-sign-in choice when both sides have data.
class _SyncPanel extends ConsumerWidget {
  const _SyncPanel();

  static String _ago(DateTime at, DateTime now) {
    final d = now.difference(at);
    if (d.inMinutes < 1) return 'just now';
    if (d.inHours < 1) return '${d.inMinutes} min ago';
    if (d.inDays < 1) return '${d.inHours} h ago';
    return '${d.inDays} d ago';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = context.textStyles;
    final status = ref.watch(syncControllerProvider);
    final sync = ref.read(syncControllerProvider.notifier);
    final now = ref.watch(clockProvider)();

    if (status.phase == SyncPhase.needsChoice) return _FirstChoice(onChoose: sync.choose);

    final (String line, Color color) = switch (status.phase) {
      SyncPhase.off => ('Off', p.textMuted),
      SyncPhase.idle => ('Ready to sync', p.textSecondary),
      SyncPhase.starting => ('Getting ready…', p.textSecondary),
      SyncPhase.syncing => ('Syncing…', p.accentStrong),
      SyncPhase.synced => ('Up to date', p.success),
      SyncPhase.offline => (
        'Waiting for internet. Changes are kept and go up when you are back online.',
        p.warning,
      ),
      SyncPhase.error => (status.message ?? 'Sync stopped with an error.', p.danger),
      SyncPhase.needsChoice => ('', p.textMuted),
    };
    final busy = status.phase == SyncPhase.syncing || status.phase == SyncPhase.starting;
    return KSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            liveRegion: true,
            child: Text(line, style: text.titleSmall?.copyWith(color: color)),
          ),
          const SizedBox(height: KSpacing.xs),
          Text(
            [
              if (status.lastSyncedAt case final at?) 'Last synced ${_ago(at, now)}' else 'Not synced yet',
              if (status.pending > 0) '${status.pending} change${status.pending == 1 ? '' : 's'} waiting',
            ].join(' · '),
            style: text.bodySmall?.copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: KSpacing.md),
          KButton(
            label: status.phase == SyncPhase.error || status.phase == SyncPhase.offline
                ? 'Retry'
                : 'Sync now',
            glyph: KGlyphs.repeat,
            variant: KButtonVariant.secondary,
            expand: true,
            loading: busy,
            onPressed: busy ? null : sync.syncNow,
          ),
        ],
      ),
    );
  }
}

/// Both this phone and the account have data: how to combine them. A safety
/// backup of this phone is always saved first.
class _FirstChoice extends StatelessWidget {
  const _FirstChoice({required this.onChoose});

  final Future<void> Function(FirstSyncMode) onChoose;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.textStyles;
    return KSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Your account already has Knightly data', style: text.titleSmall),
          const SizedBox(height: KSpacing.xs),
          Text(
            'This phone has data too. Choose how to combine them. A safety backup of this phone is saved '
            'first (Backup & restore › Safety copies).',
            style: text.bodySmall?.copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: KSpacing.md),
          KButton(
            label: 'Merge both (recommended)',
            expand: true,
            onPressed: () => onChoose(FirstSyncMode.merge),
          ),
          const SizedBox(height: KSpacing.sm),
          KButton(
            label: "Use the account's copy",
            variant: KButtonVariant.secondary,
            expand: true,
            onPressed: () async {
              final ok = await showKConfirmationDialog(
                context,
                title: "Replace this phone's data?",
                message:
                    "This phone's data is replaced by your account's. The safety backup keeps the old copy.",
                confirmLabel: 'Replace',
                destructive: true,
              );
              if (ok) await onChoose(FirstSyncMode.useCloud);
            },
          ),
          const SizedBox(height: KSpacing.sm),
          KButton(
            label: "Use this phone's copy",
            variant: KButtonVariant.secondary,
            expand: true,
            onPressed: () async {
              final ok = await showKConfirmationDialog(
                context,
                title: "Replace your account's data?",
                message: "Everything in your account is replaced by this phone's data, on every phone.",
                confirmLabel: 'Continue',
                destructive: true,
              );
              if (!ok || !context.mounted) return;
              final sure = await showKConfirmationDialog(
                context,
                title: 'Are you sure?',
                message: "Your account's current data can't be brought back after this.",
                confirmLabel: 'Replace account data',
                destructive: true,
              );
              if (sure) await onChoose(FirstSyncMode.usePhone);
            },
          ),
        ],
      ),
    );
  }
}

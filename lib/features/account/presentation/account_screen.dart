import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components/k_button.dart';
import '../../../core/design/components/k_confirmation_dialog.dart';
import '../../../core/design/components/k_section_header.dart';
import '../../../core/design/components/k_surface.dart';
import '../../../core/design/icons/k_glyph.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/layout/k_page.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../application/account_providers.dart';
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

  Future<void> _signOut() async {
    final ok = await showKConfirmationDialog(
      context,
      title: 'Sign out?',
      message: 'Everything stays on this phone and in your account. You can sign in again any time.',
      confirmLabel: 'Sign out',
    );
    if (ok) await ref.read(accountProvider.notifier).signOut();
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
          Text(
            'Not built yet: syncing your data to this account arrives in the next update. For now, '
            'Backup & restore keeps a copy.',
            style: text.bodySmall?.copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: KSpacing.xl),
          KButton(label: 'Sign out', variant: KButtonVariant.secondary, expand: true, onPressed: _signOut),
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

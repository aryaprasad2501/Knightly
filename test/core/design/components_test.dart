import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/design/components/k_art_header.dart';
import 'package:knightly/core/design/components/k_bottom_sheet.dart';
import 'package:knightly/core/design/components/k_activity_rings.dart';
import 'package:knightly/core/design/components/k_button.dart';
import 'package:knightly/core/design/components/k_toggle.dart';
import 'package:knightly/core/design/components/k_card.dart';
import 'package:knightly/core/design/components/k_check_circle.dart';
import 'package:knightly/core/design/components/k_chip.dart';
import 'package:knightly/core/design/components/k_confirmation_dialog.dart';
import 'package:knightly/core/design/components/k_divider.dart';
import 'package:knightly/core/design/components/k_dropdown.dart';
import 'package:knightly/core/design/components/k_empty_state.dart';
import 'package:knightly/core/design/components/k_icon_button.dart';
import 'package:knightly/core/design/components/k_loading_indicator.dart';
import 'package:knightly/core/design/components/k_metal_text.dart';
import 'package:knightly/core/design/components/k_number_field.dart';
import 'package:knightly/core/design/components/k_progress_bar.dart';
import 'package:knightly/core/design/components/k_progress_ring.dart';
import 'package:knightly/core/design/components/k_section_header.dart';
import 'package:knightly/core/design/components/k_surface.dart';
import 'package:knightly/core/design/components/k_text_field.dart';
import 'package:knightly/core/design/icons/k_glyph.dart';
import 'package:knightly/core/design/icons/k_glyphs.dart';
import 'package:knightly/core/design/theme/k_tone.dart';
import 'package:knightly/core/design/theme/knightly_themes.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('every component renders in', () {
    for (final theme in KnightlyThemeId.values) {
      testWidgets(theme.displayName, (tester) async {
        await pumpThemed(
          tester,
          theme: theme,
          settle: false, // the loading indicator animates forever
          Column(
            children: [
              for (final v in KButtonVariant.values) KButton(label: v.name, variant: v, onPressed: () {}),
              const KButton(label: 'off', onPressed: null),
              for (final v in KIconButtonVariant.values)
                KIconButton(glyph: KGlyphs.plus, tooltip: v.name, variant: v, onPressed: () {}),
              const KSurface(child: Text('surface')),
              const KSurface(
                padding: EdgeInsets.zero,
                child: KArtHeader(image: AssetImage('assets/panels/dk_water.webp'), child: Text('art')),
              ),
              const KCard(title: 'card', glyph: KGlyphs.moon, child: Text('body')),
              const KTextField(label: 'field', errorText: 'bad'),
              KNumberField(value: 62.5, decimal: true, semanticLabel: 'kg', onChanged: (_) {}),
              KDropdown<int>(
                label: 'drop',
                value: 1,
                onChanged: (_) {},
                options: const [KDropdownOption(value: 1, label: 'one')],
              ),
              const KSectionHeader('section'),
              const KProgressRing(value: 0.5),
              KToggle(value: true, semanticLabel: 'toggle', onChanged: (_) {}),
              const KActivityRings(
                rings: [
                  KRing(label: 'a', value: 0.5),
                  KRing(label: 'b', value: null),
                ],
              ),
              const KProgressBar(value: 0.5, label: 'bar'),
              for (final tone in KTone.values) KChip(label: tone.name, tone: tone),
              const KEmptyState(glyph: KGlyphs.flag, title: 'empty', message: 'msg'),
              const KLoadingIndicator(),
              const KDivider(label: 'or'),
              KCheckCircle(checked: true, semanticLabel: 'done', onChanged: (_) {}),
              Wrap(children: [for (final g in KGlyphs.all) KIcon(g, filled: true)]),
            ],
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.text('surface'), findsOneWidget);
      });
    }
  });

  group('KButton', () {
    testWidgets('fires onPressed', (tester) async {
      var taps = 0;
      await pumpThemed(tester, KButton(label: 'Save', onPressed: () => taps++));
      await tester.tap(find.text('Save'));
      expect(taps, 1);
    });

    testWidgets('disabled and loading buttons ignore taps', (tester) async {
      var taps = 0;
      await pumpThemed(
        tester,
        settle: false,
        Column(
          children: [
            const KButton(label: 'Off', onPressed: null),
            KButton(label: 'Busy', loading: true, onPressed: () => taps++),
          ],
        ),
      );
      await tester.tap(find.text('Off'));
      await tester.tap(find.byType(KButton).last);
      expect(taps, 0);
    });

    testWidgets('meets the 48 dp touch target in compact size', (tester) async {
      await pumpThemed(tester, KButton(label: 'Go', size: KButtonSize.compact, onPressed: () {}));
      expect(tester.getSize(find.byType(KButton)).height, greaterThanOrEqualTo(48));
    });
  });

  testWidgets('KIconButton is labelled by its tooltip and 48 dp', (tester) async {
    var taps = 0;
    await pumpThemed(tester, KIconButton(glyph: KGlyphs.search, tooltip: 'Search', onPressed: () => taps++));
    expect(find.byTooltip('Search'), findsOneWidget);
    expect(tester.getSize(find.byType(KIconButton)), const Size(48, 48));
    await tester.tap(find.byType(KIconButton));
    expect(taps, 1);
  });

  testWidgets('KTextField shows error instead of helper', (tester) async {
    await pumpThemed(tester, const KTextField(label: 'Target', helper: 'Helpful', errorText: 'Too high'));
    expect(find.text('Too high'), findsOneWidget);
    expect(find.text('Helpful'), findsNothing);
  });

  testWidgets('KDropdown picks a value from the sheet', (tester) async {
    String? picked;
    await pumpThemed(
      tester,
      KDropdown<String>(
        label: 'Area',
        value: 'a',
        onChanged: (v) => picked = v,
        options: const [
          KDropdownOption(value: 'a', label: 'Alpha'),
          KDropdownOption(value: 'b', label: 'Bravo'),
        ],
      ),
    );
    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();
    expect(find.text('Bravo'), findsOneWidget);
    await tester.tap(find.text('Bravo'));
    await tester.pumpAndSettle();
    expect(picked, 'b');
  });

  group('showKConfirmationDialog', () {
    Future<bool?> run(WidgetTester tester, Future<void> Function() act) async {
      bool? result;
      await pumpThemed(
        tester,
        Builder(
          builder: (context) => KButton(
            label: 'Ask',
            onPressed: () async => result = await showKConfirmationDialog(
              context,
              title: 'Delete?',
              message: 'Gone for good.',
              confirmLabel: 'Delete',
              destructive: true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Ask'));
      await tester.pumpAndSettle();
      expect(find.text('Gone for good.'), findsOneWidget);
      await act();
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('confirm resolves true', (tester) async {
      expect(await run(tester, () => tester.tap(find.text('Delete'))), isTrue);
    });

    testWidgets('cancel resolves false', (tester) async {
      expect(await run(tester, () => tester.tap(find.text('Cancel'))), isFalse);
    });

    testWidgets('tapping the barrier resolves false', (tester) async {
      expect(await run(tester, () => tester.tapAt(const Offset(5, 5))), isFalse);
    });
  });

  testWidgets('showKBottomSheet shows title and content', (tester) async {
    await pumpThemed(
      tester,
      Builder(
        builder: (context) => KButton(
          label: 'Open',
          onPressed: () =>
              showKBottomSheet<void>(context: context, title: 'Sheet', child: const Text('Inside')),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Sheet'), findsOneWidget);
    expect(find.text('Inside'), findsOneWidget);
  });

  testWidgets('KCheckCircle toggles, exposes checked state and is 48 dp', (tester) async {
    final handle = tester.ensureSemantics();
    bool? next;
    await pumpThemed(
      tester,
      KCheckCircle(checked: false, semanticLabel: 'Stretch', onChanged: (v) => next = v),
    );
    expect(tester.getSize(find.byType(KCheckCircle)), const Size(48, 48));
    expect(
      tester.getSemantics(find.bySemanticsLabel('Stretch')),
      matchesSemantics(
        label: 'Stretch',
        hasCheckedState: true,
        isChecked: false,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    await tester.tap(find.byType(KCheckCircle));
    expect(next, isTrue);
    handle.dispose();
  });

  for (final theme in KnightlyThemeId.values) {
    testWidgets('KMetalText fills its text with the ${theme.displayName} metal', (tester) async {
      await pumpThemed(tester, const KMetalText('CASE FILES', style: TextStyle(fontSize: 30)), theme: theme);
      final text = tester.widget<Text>(find.text('CASE FILES'));
      expect(text.style?.foreground?.shader, isNotNull);
      expect(text.style?.color, isNull);
    });
  }

  testWidgets('KToggle flips, exposes toggled state and is 48 dp', (tester) async {
    final handle = tester.ensureSemantics();
    var value = false;
    await pumpThemed(
      tester,
      StatefulBuilder(
        builder: (context, setState) =>
            KToggle(value: value, semanticLabel: 'Live', onChanged: (v) => setState(() => value = v)),
      ),
    );
    expect(tester.getSize(find.byType(KToggle)).height, greaterThanOrEqualTo(48));
    await tester.tap(find.byType(KToggle));
    await tester.pumpAndSettle();
    expect(value, isTrue);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Live')),
      matchesSemantics(
        label: 'Live',
        hasToggledState: true,
        isToggled: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('KChip toggles and keeps a 48 dp hit area', (tester) async {
    bool? next;
    await pumpThemed(tester, KChip(label: 'Today', onSelected: (v) => next = v));
    expect(tester.getSize(find.byType(KChip)).height, greaterThanOrEqualTo(48));
    await tester.tap(find.byType(KChip));
    expect(next, isTrue);
  });

  group('progress semantics', () {
    testWidgets('null means no data, values are clamped', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpThemed(
        tester,
        const Column(
          children: [
            KProgressRing(value: null, semanticLabel: 'Empty ring'),
            KProgressRing(value: 1.4, semanticLabel: 'Over ring'),
            KProgressBar(value: 0.4, label: 'Bar'),
          ],
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Empty ring')),
        matchesSemantics(label: 'Empty ring', value: 'No data'),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Over ring')),
        matchesSemantics(label: 'Over ring', value: '100%'),
      );
      expect(tester.getSemantics(find.bySemanticsLabel('Bar')), matchesSemantics(label: 'Bar', value: '40%'));
      handle.dispose();
    });

    testWidgets('activity rings describe every ring, null as no data', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpThemed(
        tester,
        const KActivityRings(
          rings: [
            KRing(label: 'Habits', value: 0.5),
            KRing(label: 'Week', value: null),
            KRing(label: 'Over', value: 2),
          ],
        ),
      );
      expect(find.bySemanticsLabel('Habits: 50%, Week: no data, Over: 100%'), findsOneWidget);
      handle.dispose();
    });
  });

  testWidgets('KLoadingIndicator holds still under reduced motion', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: KLoadingIndicator(color: Colors.white),
        ),
      ),
    );
    // Would time out if the indicator kept spinning.
    await tester.pumpAndSettle();
    expect(find.byType(KLoadingIndicator), findsOneWidget);
  });

  testWidgets('KSectionHeader action and KCard tap', (tester) async {
    var actions = 0;
    var cardTaps = 0;
    await pumpThemed(
      tester,
      Column(
        children: [
          KSectionHeader('Missions', actionLabel: 'See all', onAction: () => actions++),
          KCard(title: 'Card', onTap: () => cardTaps++),
        ],
      ),
    );
    expect(find.text('MISSIONS'), findsOneWidget);
    await tester.tap(find.text('See all'));
    await tester.tap(find.text('Card'));
    expect((actions, cardTaps), (1, 1));
  });
}
